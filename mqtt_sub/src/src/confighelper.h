#include <stdio.h>
#include <stdlib.h>
#include <uci.h>
#include <mosquitto.h>
#include "logger.h"

struct mqtt_config
{
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

int config_read_options(struct mqtt_config *cfg);

int config_read_and_subto_topics(struct mosquitto *mosq);

