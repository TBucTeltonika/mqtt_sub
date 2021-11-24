#include <stdio.h>
#include <stdlib.h>
#include <uci.h>
#include <mosquitto.h>
#include <signal.h>
#include "llist.h"
#include "logger.h"
#include "database.h"
#include "confighelper.h"
#include "cJSON/cJSON.h"
#include "email.h"

void handle_signal(int s);
void connect_callback(struct mosquitto *mosq, void *obj, int result);
void message_callback_topics(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message);
void message_callback_events(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message);
int run_mqtt_client(struct mosquitto** mosq, struct mqtt_config* cfg);
int configure_mqtt_client(struct mosquitto** mosq, struct mqtt_config* cfg);
void free_event(struct mqtt_event *event);
