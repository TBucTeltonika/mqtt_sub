#include "confighelper.h"

/* Macro with error checking */
#define READVALUE(contxt, sect, dest, name)                                         \
	if (uci_lookup_option_string(contxt, sect, name) == NULL) {                     \
		printf("ERROR: READVALUE failed to lookup value : %s\n", name);             \
		TRACE_LOG(LOG_CRIT, "ERROR: READVALUE failed to lookup value :%s\n", name); \
		exit(1);                                                                    \
	} else                                                                          \
		dest = strdup(uci_lookup_option_string(contxt, sect, name));

/* Macro with error checking for optional values, if value is not found its set to NULL */
#define READVALUEOPT(contxt, sect, dest, name)                                         \
	if (uci_lookup_option_string(contxt, sect, name) == NULL) {                        \
		printf("ERROR: READVALUEOPT failed to lookup value : %s\n", name);             \
		TRACE_LOG(LOG_CRIT, "ERROR: READVALUEOPT failed to lookup value :%s\n", name); \
		dest = NULL;                                                                   \
	} else                                                                             \
		dest = strdup(uci_lookup_option_string(contxt, sect, name));

static enum comp_type get_comp_type(char *str)
{
	if (strcmp(str, "equal") == 0)
		return equal;
	else if (strcmp(str, "notequal") == 0)
		return not_equal;
	else if (strcmp(str, "lessthan") == 0)
		return less_than;
	else if (strcmp(str, "morethan") == 0)
		return more_than;
	else if (strcmp(str, "lessorequalthan") == 0)
		return less_or_equal;
	else if (strcmp(str, "moreorequalthan") == 0)
		return more_or_equal;
	else
		return unknown;
}

static struct uci_context *get_uci_ctx()
{
	static struct uci_context *ctx = NULL;
	if (ctx == NULL)
		ctx = uci_alloc_context(); // apply for a UCI context.
	return ctx;
}

static int free_uci_ctx(struct uci_context *ctx)
{
	uci_free_context(ctx);
	ctx = NULL;
	return 0;
}

static uint32_t getUID()
{
	static uint32_t counter = 1;
	return counter++;
}

bool isenabled(char *enabled)
{
	if (enabled != NULL && strcmp(enabled, "0") == 0) {
		free(enabled);
		return false;
	} else if (enabled == NULL) {
		return false;
	}
	free(enabled);
	return true;
}

int subscribe(struct mosquitto *mosq, char *topic, int qos, uint32_t sub_id)
{
	int rc = 0;
#ifdef USE_V5
	mosquitto_property *proplist = NULL;
	rc							 = mosquitto_property_add_varint(&proplist, SUBSCRIBER_ID, sub_id);
	if (rc != 0)
		return rc;

	if (proplist == NULL)
		TRACE_LOG(LOG_ERR, "error: proplist is NULL: \n");
	rc = mosquitto_subscribe_v5(mosq, NULL, topic, qos, 0, proplist);

	free(proplist);
	if (rc != 0)
		return rc;
#else
	rc = mosquitto_subscribe(mosq, NULL, topic, qos);
#endif
	return rc;
}

static int parse_uci_sections(struct uci_context *ctx,
							  struct uci_package *pkg,
							  char *			  name,
							  parse_handler		  hand,
							  void *			  opt1,
							  void *			  opt2)
{
	int					rc = 0;
	struct uci_element *e;
	uci_foreach_element(&pkg->sections, e)
	{
		struct uci_section *s = uci_to_section(e);
		if (strcmp(s->type, name) == 0)
			rc = (*hand)(ctx, s, opt1, opt2);
	}
	return rc;
}

static int event_section_handler(struct uci_context *ctx, struct uci_section *s, void *opt1, void *opt2)
{
	struct mosquitto *mosq = (struct mosquitto *)opt1;
	llist *			  list = (llist *)opt2;
	char *			  enabled;
	int				  rc = 0;

	READVALUE(ctx, s, enabled, "enable");
	if (isenabled(enabled)) {
		struct mqtt_event *event = (struct mqtt_event *)malloc(sizeof(struct mqtt_event));

		READVALUE(ctx, s, event->topic, "topic");

		READVALUE(ctx, s, event->key, "key");

		char *comptype;
		READVALUE(ctx, s, comptype, "compType");
		event->comptype = get_comp_type(comptype);
		free(comptype);

		char *datatype;
		READVALUE(ctx, s, datatype, "type");
		if (strcmp(datatype, "String") == 0) {
			event->is_string = true;
			READVALUE(ctx, s, event->value, "value");
		} else {
			event->is_string = false;
			char *valueint;
			READVALUE(ctx, s, valueint, "valueint");
			event->valueint = atoi(valueint);
			free(valueint);
		}
		free(datatype);

		READVALUE(ctx, s, event->subject, "subject");
		READVALUE(ctx, s, event->message, "message");
		READVALUE(ctx, s, event->recipient, "recipEmail");

		char *emailgroup;
		READVALUE(ctx, s, emailgroup, "emailgroup");

		event->email = (struct email_info *)malloc(sizeof(struct email_info));

		rc = config_read_emailgroup(event->email, emailgroup);
		free(emailgroup);

		llist_push(list, event);

		event->sub_id = getUID();

		rc = subscribe(mosq, event->topic, 0, event->sub_id);
	}
	return rc;
}
static int cfg_section_handler(struct uci_context *ctx, struct uci_section *s, void *opt1, void *opt2)
{
	struct mqtt_config *cfg = (struct mqtt_config *)opt1;

	READVALUE(ctx, s, cfg->hostname, "remote_addr");
	READVALUE(ctx, s, cfg->port, "remote_port");
	READVALUEOPT(ctx, s, cfg->username, "username");
	READVALUEOPT(ctx, s, cfg->password, "password");
	READVALUEOPT(ctx, s, cfg->tls, "tls");
	if (cfg->tls != NULL && strcmp(cfg->tls, "1") == 0) {
		READVALUEOPT(ctx, s, cfg->tls_insecure, "tls_insecure");
		READVALUE(ctx, s, cfg->cafile, "cafile");
		READVALUE(ctx, s, cfg->certfile, "certfile");
		READVALUE(ctx, s, cfg->keyfile, "keyfile");
	}
	return 0;
}

static int topic_section_handler(struct uci_context *ctx, struct uci_section *s, void *opt1, void *opt2)
{
	int				  rc   = 0;
	struct mosquitto *mosq = (struct mosquitto *)opt1;
	char *			  enabled;
	char *			  topic;
	char *			  qos;

	READVALUEOPT(ctx, s, enabled, "enabled");
	if (isenabled(enabled)) {
		READVALUE(ctx, s, topic, "topic");
		READVALUE(ctx, s, qos, "qos");
		int qos_i = atoi(qos);

		subscribe(mosq, topic, qos_i, TOPIC_ID);
	}
	return rc;
}

static int email_section_handler(struct uci_context *ctx, struct uci_section *s, void *opt1, void *opt2)
{
	struct email_info *email	 = (struct email_info *)opt1;
	char *			   groupname = (char *)opt2;

	char *name;

	READVALUE(ctx, s, name, "name");
	if (strcmp(name, groupname) != 0) {
		free(name);
	} else {
		READVALUE(ctx, s, email->smtp_ip, "smtp_ip");

		char *port;
		READVALUE(ctx, s, port, "smtp_port");
		email->smtp_port = atoi(port);

		char *cred;
		READVALUE(ctx, s, cred, "credentials");
		if (strcmp(cred, "0") == 0) {
			email->user		= NULL;
			email->password = NULL;
		} else {
			READVALUE(ctx, s, email->user, "username");
			READVALUE(ctx, s, email->password, "password");
		}
		free(cred);

		READVALUE(ctx, s, email->email_address, "senderemail");

		char *secure;
		READVALUE(ctx, s, secure, "secure_conn");
		email->secure_conn = (strcmp(secure, "1") == 0);
		free(secure);
	}
	return 0;
}

static int parse_uci(char *file, char *section_name, parse_handler handler, void *opt1, void *opt2)
{
	int					rc	= 0;
	struct uci_context *ctx = get_uci_ctx();
	struct uci_package *pkg = NULL;

	if (UCI_OK != uci_load(ctx, file, &pkg))
		uci_free_context(ctx);

	rc = parse_uci_sections(ctx, pkg, section_name, handler, opt1, opt2);

	uci_unload(ctx, pkg);

	return rc;
}

int config_read_options(struct mqtt_config *cfg)
{
	int rc = 0;
	rc	   = parse_uci(UCI_CONFIG_FILE, "mqtt_sub", &cfg_section_handler, cfg, NULL);
	return rc;
}

int config_read_events(struct mosquitto *mosq, llist *list)
{
	int rc = 0;
	rc	   = parse_uci(UCI_EVENT_FILE, "rule", &event_section_handler, mosq, list);
	return rc;
}

int config_read_emailgroup(struct email_info *event, char *groupname)
{
	int rc = 0;
	rc	   = parse_uci(UCI_USERGROUPS_FILE, "email", &email_section_handler, event, groupname);
	return rc;
}

int config_read_topics(struct mosquitto *mosq)
{
	int rc = 0;
	rc	   = parse_uci(UCI_CONFIG_FILE, "topic", &topic_section_handler, mosq, NULL);
	return rc;
}