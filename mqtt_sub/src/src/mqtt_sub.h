#include <stdio.h>
#include <stdlib.h>
#include <uci.h>
#include <mosquitto.h>
#include <signal.h>

#include "logger.h"
#include "database.h"
#include "confighelper.h"


void handle_signal(int s);
void connect_callback(struct mosquitto *mosq, void *obj, int result);
void message_callback(struct mosquitto *mosq, void *obj, const struct mosquitto_message *message);

