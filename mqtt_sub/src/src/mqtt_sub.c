#include "mqtt_sub.h"
static int run = 1;
//SUkurti atskira langa. Kuris bus eventams.
//Gauntat kazkokia zinute patikrinti ar jinai neturi kazkokio evento.
//Issiusti emaila.

void handle_signal(int s)
{
	run = 0;
}

void connect_callback(struct mosquitto *mosq, void *obj, int result)
{
	logwrite("MQTT Client connected \n");
}

void message_callback_topics(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message)
{
	int rc = insert_into_db(message->topic, (char *)message->payload);
	if (rc != SQLITE_DONE)
		TRACE_LOG(1, "Insert into db error: %d", rc);
}

void message_callback_events(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message)
{
	int rc = insert_into_db(message->topic, (char *)message->payload);
	if (rc != SQLITE_DONE)
		TRACE_LOG(1, "Insert into db error: %d", rc);
}

int configure_mqtt_client(struct mosquitto* mosq, struct mqtt_config* cfg)
{
	uint8_t reconnect = true;
	char clientid[24];
	struct mosquitto *mosq;
	int rc = 0;
	signal(SIGINT, handle_signal);
	signal(SIGTERM, handle_signal);

	mosquitto_lib_init();
	memset(clientid, 0, 24);
	snprintf(clientid, 23, "mqttsub%d", getpid());
	mosq = mosquitto_new(clientid, true, 0);

	//Read uci config
	
	rc = config_read_options(&cfg);
	if (cfg->tls != NULL && strcmp(cfg->tls, "1") == 0){
		//TLS insecure configuration. Dont set it to true in a real system!
		if (cfg->tls_insecure != NULL && strcmp(cfg->tls_insecure, "1") == 0)
			rc = mosquitto_tls_insecure_set(mosq, true);
		else
			rc = mosquitto_tls_insecure_set(mosq, false);
		//TLS SET
		rc = mosquitto_tls_set(mosq, cfg->cafile, NULL, cfg->certfile, cfg->keyfile, NULL);
	}
	return rc;
}

int run_mqtt_client(struct mosquitto* mosq, struct mqtt_config* cfg)
{
		int rc = 0;
		mosquitto_connect_callback_set(mosq, connect_callback);
		mosquitto_message_callback_set(mosq, message_callback_topics);

		int port = atoi(cfg->port);
		if (cfg->username != NULL)
			rc = mosquitto_username_pw_set(mosq, cfg->username, cfg->password);

		rc = mosquitto_connect(mosq, cfg->hostname, port, 60);

		//Read and sub to topics.
		config_read_and_subto_topics(mosq);
		while (run){
			rc = mosquitto_loop(mosq, -1, 1);
			if (run && rc){			
				printf("connection error!\n");
				sleep(10);
				mosquitto_reconnect(mosq);
			}
		}
		mosquitto_destroy(mosq);

	mosquitto_lib_cleanup();

	return rc;
}

int main(int argc, char *argv[])
{
	struct mosquitto *mosq;
	struct mqtt_config cfg = {0};
	configure_mqtt_client(mosq, &cfg);
	if (mosq)
		run_mqtt_client(mosq, &cfg);
}