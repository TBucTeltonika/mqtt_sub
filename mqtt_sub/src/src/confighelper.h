#include "logger.h"
#include <mosquitto.h>
#include <stdio.h>
#include <stdlib.h>
#include <uci.h>
#include "llist.h"
enum comp_type { equal, not_equal, less_than, more_than, less_or_equal, more_or_equal, unknown };
//use MQTT V5. earlier versions are not fully supported.
#define USE_V5

#define TOPIC_ID 4444
#define SUBSCRIBER_ID 11

#define UCI_CONFIG_FILE "mqtt_sub"
#define UCI_EVENT_FILE "mqtt_events"
#define UCI_USERGROUPS_FILE "user_groups"

struct mqtt_config {
	char *hostname;
	char *port;
	char *username;
	char *password;
	char *tls;
	char *tls_type;
	char *tls_insecure;
	char *cafile;
	char *certfile;
	char *keyfile;
};

struct email_info {
	bool  secure_conn;
	char *smtp_ip;
	int	  smtp_port;
	char *email_address;
	char *user;
	char *password;
};

struct mqtt_event {
	char *topic;
	char *key;
	uint32_t sub_id;
	
	enum comp_type comptype;
	bool is_string;
	char *value;
	int	valueint;
	char *recipient;
	char *subject;
	char *message;

	struct email_info* email;
};

typedef int (*parse_handler)(struct uci_context *, struct uci_section *, void *, void *);

static enum comp_type get_comp_type(char *str);

static struct uci_context *get_uci_ctx();

static int free_uci_ctx(struct uci_context *ctx);

static uint32_t getUID();

bool isenabled(char *enabled);

int subscribe(struct mosquitto *mosq, char *topic, int qos, uint32_t sub_id);

static int parse_uci_sections(struct uci_context *ctx,
							  struct uci_package *pkg,
							  char *			  name,
							  parse_handler		  hand,
							  void *			  opt1,
							  void *			  opt2);

static int event_section_handler(struct uci_context *ctx, struct uci_section *s, void *opt1, void *opt2);

static int cfg_section_handler(struct uci_context *ctx, struct uci_section *s, void *opt1, void *opt2);

static int topic_section_handler(struct uci_context *ctx, struct uci_section *s, void *opt1, void *opt2);

static int email_section_handler(struct uci_context *ctx, struct uci_section *s, void *opt1, void *opt2);

static int parse_uci(char *file, char *section_name, parse_handler handler, void *opt1, void *opt2);

int config_read_options(struct mqtt_config *cfg);

int config_read_events(struct mosquitto *mosq, llist *list);

int config_read_emailgroup(struct email_info *event, char *groupname);

int config_read_topics(struct mosquitto *mosq);



