#include "mqtt_sub.h"
static int run		  = 1;
llist *	   event_list = NULL;

void handle_signal(int s)
{
	run = 0;
}

void connect_callback(struct mosquitto *mosq, void *obj, int result)
{
	logwrite("MQTT Client connected \n");
}

void connect_callback_v5(struct mosquitto *		   mosq,
						 void *					   pObject,
						 int					   iResult,
						 int					   iFlags,
						 const mosquitto_property *pProperties)
{
	logwrite("MQTT Client V5 connected \n");
}

void message_callback_topics(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message)
{
	int rc = insert_into_db(message->topic, (char *)message->payload);
	if (rc != SQLITE_DONE)
		TRACE_LOG(1, "Insert into db error: %d", rc);
}

void topic_callback_v5(struct mosquitto *			   mosq,
					   void *						   obj,
					   const struct mosquitto_message *message,
					   const mosquitto_property *	   pProperties)
{
	int rc = insert_into_db(message->topic, (char *)message->payload);

	if (rc != SQLITE_DONE)
		TRACE_LOG(1, "Insert into db error: %d", rc);
}

struct mqtt_event *event_matches(struct mqtt_event *event, struct mosquitto_message *message, uint32_t sub_id)
{
	bool match = false;
	int	 rc;

	if (sub_id != event->sub_id)
		return NULL;

	rc = mosquitto_topic_matches_sub(event->topic, message->topic, &match);

	if (match) {
		cJSON *json = cJSON_Parse(message->payload);
		if (json == NULL) {
			return NULL;
		}
		bool result = false;
		rc			= parseJsonValue(json, event, &result);
		if (result)
			return event;
	}
	return NULL;
}

void event_callback_v5(struct mosquitto *			   mosq,
					   void *						   obj,
					   const struct mosquitto_message *message,
					   const mosquitto_property *	   pProperties,
					   uint32_t						   sub_id)
{
	int				   rc;
	struct mqtt_event *event = (struct mqtt_event *)llist_getone(event_list, event_matches, message, sub_id);
	if (event != NULL) {
		TRACE_LOG(LOG_INFO, "send email to %s\n", event->recipient);

		sendEmail(event->recipient, event->email->user, NULL, NULL, event->subject, event->message,
				  event->email->smtp_ip, event->email->smtp_port, event->email->password,
				  (int)event->email->secure_conn);
		return;
	}
}

void message_callback_v5(struct mosquitto *				 mosq,
						 void *							 obj,
						 const struct mosquitto_message *message,
						 const mosquitto_property *		 pProperties)
{
	uint32_t				   sub_id = 0;
	struct mosquitto_property *prop	  = mosquitto_property_read_varint(pProperties, SUBSCRIBER_ID, &sub_id, false);
	if (sub_id == TOPIC_ID)
		topic_callback_v5(mosq, obj, message, pProperties);
	else
		event_callback_v5(mosq, obj, message, pProperties, sub_id);

	return;
}

int parseJsonValue(cJSON *json, struct mqtt_event *event, bool *result)
{
	int rc	   = 0;
	*result	   = false;
	cJSON *val = NULL;

	val = cJSON_GetObjectItemCaseSensitive(json, event->key);

	if (val == NULL) {
		return 1;
	}

	if (event->is_string) {
		if (strcmp(event->value, val->valuestring) == 0) {
			if (event->comptype == equal)
				*result = true;
			else if (event->comptype == not_equal)
				*result = false;
			return 0;
		} else {
			if (event->comptype == not_equal)
				*result = true;
			else if (event->comptype == equal)
				*result = false;
			return 0;
		}
	} else {
		if (cJSON_IsNumber(val) == false)
			*result = false;
		else if (event->comptype == equal)
			*result = event->valueint == val->valueint;
		else if (event->comptype == not_equal)
			*result = event->valueint != val->valueint;
		else if (event->comptype == less_than)
			*result = event->valueint < val->valueint;
		else if (event->comptype == more_than)
			*result = event->valueint > val->valueint;
		else if (event->comptype == more_or_equal)
			*result = event->valueint >= val->valueint;
		else if (event->comptype == less_or_equal)
			*result = event->valueint <= val->valueint;
	}
	return 0;
}

int configure_mqtt_client(struct mosquitto **mosq, struct mqtt_config *cfg)
{
	uint8_t reconnect = true;
	char	clientid[24];
	// struct mosquitto *mosq;
	int rc = 0;
	signal(SIGINT, handle_signal);
	signal(SIGTERM, handle_signal);

	mosquitto_lib_init();
	memset(clientid, 0, 24);
	snprintf(clientid, 23, "mqttsub%d", getpid());
	*mosq = mosquitto_new(clientid, true, 0);
#ifdef USE_V5
	mosquitto_int_option(*mosq, MOSQ_OPT_PROTOCOL_VERSION, MQTT_PROTOCOL_V5);
#endif
	// Read uci config
	rc = config_read_options(cfg);
	if (cfg->tls != NULL && strcmp(cfg->tls, "1") == 0) {
		// TLS insecure configuration.
		if (cfg->tls_insecure != NULL && strcmp(cfg->tls_insecure, "1") == 0)
			rc = mosquitto_tls_insecure_set(mosq, true);
		else
			rc = mosquitto_tls_insecure_set(mosq, false);
		// TLS SET
		rc = mosquitto_tls_set(mosq, cfg->cafile, NULL, cfg->certfile, cfg->keyfile, NULL);
	}
	return rc;
}

#define ASSERT_FREE(ptr) \
	if (ptr)             \
		free(ptr);

void free_event(struct mqtt_event *event)
{
	if (event != NULL) {
		ASSERT_FREE(event->topic);
		ASSERT_FREE(event->key);
		ASSERT_FREE(event->value);
		ASSERT_FREE(event->recipient);
		ASSERT_FREE(event->subject);
		ASSERT_FREE(event->message);
		if (event->email != NULL) {
			ASSERT_FREE(event->email->smtp_ip);
			ASSERT_FREE(event->email->email_address);
			ASSERT_FREE(event->email->user);
			ASSERT_FREE(event->email->password);
			free(event->email);
		}
		free(event);
	}
	return;
}

int run_mqtt_client(struct mosquitto **mosq, struct mqtt_config *cfg)
{
	int rc = 0;
#ifdef USE_V5
	mosquitto_connect_v5_callback_set(*mosq, connect_callback_v5);
	mosquitto_message_v5_callback_set(*mosq, message_callback_v5);
#else
	mosquitto_connect_callback_set(*mosq, connect_callback);
	mosquitto_message_callback_set(*mosq, message_callback_topics);
#endif
	if (cfg->username != NULL)
		rc = mosquitto_username_pw_set(*mosq, cfg->username, cfg->password);

	int port = atoi(cfg->port);
#ifdef USE_V5
	rc = mosquitto_connect_bind_v5(*mosq, cfg->hostname, port, 60, NULL, NULL);
#else
	rc = mosquitto_connect(*mosq, cfg->hostname, port, 60);
#endif

	// Read and sub to topics.
	config_read_topics(*mosq);
	config_read_events(*mosq, event_list);

	while (run) {
		rc = mosquitto_loop(*mosq, -1, 1);
		if (run && rc) {
			TRACE_LOG(LOG_CRIT, "connection error!\n");
			sleep(10);
			mosquitto_reconnect(*mosq);
		}
	}
	return rc;
}

int clean_up(struct mosquitto *mosq)
{
	int rc;

	mosquitto_destroy(mosq);
	mosquitto_lib_cleanup();
	llist_free_custom(event_list, free_event);
	rc = free_db_resources();

	return rc;
}

int main(int argc, char *argv[])
{
	struct mosquitto * mosq = NULL;
	struct mqtt_config cfg	= {0};
	event_list				= llist_create(NULL);

	configure_mqtt_client(&mosq, &cfg);

	if (mosq != NULL)
		run_mqtt_client(&mosq, &cfg);
}