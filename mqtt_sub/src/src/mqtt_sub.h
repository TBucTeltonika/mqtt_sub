#include <stdio.h>
#include <stdlib.h>
#include <uci.h>
#include <mosquitto.h>
#include <signal.h>

#include "logger.h"
#include "database.h"
#include "confighelper.h"

enum comp_type {equal, not_equal, less_than, more_than, less_or_equal, more_or_equal};

struct mqtt_event
{
    char *topic;
    char *key;
    int is_string;
    enum comp_type type;
    char* value;
    void *next;
};

void handle_signal(int s);
void connect_callback(struct mosquitto *mosq, void *obj, int result);
void message_callback_topics(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message);
void message_callback_events(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message);
int run_mqtt_client(struct mosquitto* mosq, struct mqtt_config* cfg);
int configure_mqtt_client(struct mosquitto* mosq, struct mqtt_config* cfg);