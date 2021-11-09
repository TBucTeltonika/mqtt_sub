#include "confighelper.h"

#define UCI_CONFIG_FILE "mqtt_sub"

/* Macro with error checking */
#define READVALUE(contxt, sect, dest, name)                                                   \
    if (uci_lookup_option_string(contxt, sect, name) == NULL)                                 \
    {                                                                                         \
        printf("ERROR: config_read_options failed to lookup value : %s\n", name);             \
        TRACE_LOG(LOG_CRIT, "ERROR: config_read_options failed to lookup value :%s\n", name); \
        exit(1);                                                                              \
    }                                                                                         \
    else                                                                                      \
        dest = strdup(uci_lookup_option_string(contxt, sect, name));

/* Macro with error checking for optional values, if value is not found its set to NULL */
#define READVALUEOPT(contxt, sect, dest, name)                                                \
    if (uci_lookup_option_string(contxt, sect, name) == NULL)                                 \
    {                                                                                         \
        printf("ERROR: config_read_options failed to lookup value Optional : %s\n", name);    \
        TRACE_LOG(LOG_CRIT, "ERROR: config_read_options failed to lookup value :%s\n", name); \
        dest = NULL;                                                                          \
    }                                                                                         \
    else                                                                                      \
        dest = strdup(uci_lookup_option_string(contxt, sect, name));

int config_read_options(struct mqtt_config *cfg)
{
    int rc = 0;
    struct uci_context *ctx = NULL;
    struct uci_package *pkg = NULL;
    struct uci_element *e;
    ctx = uci_alloc_context(); //apply for a UCI context.
    if (UCI_OK != uci_load(ctx, UCI_CONFIG_FILE, &pkg))
        goto cleanup; //If the UCI file fails to open, skip to the end to clean up the UCI context.
    /* Traverse every section of UCI */
    uci_foreach_element(&pkg->sections, e)
    {
        struct uci_section *s = uci_to_section(e);
        if (strcmp(s->type, "mqtt_sub") == 0)
        {

            const char *str = uci_lookup_option_string(ctx, s, "remote_addr");
            printf("remote_addr: %s\n", str);

            READVALUE(ctx, s, cfg->hostname, "remote_addr");
            READVALUE(ctx, s, cfg->port, "remote_port");
            READVALUEOPT(ctx, s, cfg->username, "username");
            READVALUEOPT(ctx, s, cfg->password, "password");
            READVALUEOPT(ctx, s, cfg->tls, "tls");
            if (cfg->tls != NULL && strcmp(cfg->tls, "1") == 0)
            {
                READVALUEOPT(ctx, s, cfg->tls_insecure, "tls_insecure");
                READVALUE(ctx, s, cfg->cafile, "cafile");
                READVALUE(ctx, s, cfg->certfile, "certfile");
                READVALUE(ctx, s, cfg->keyfile, "keyfile");
            }
        }
    }
    uci_unload(ctx, pkg); //release pkg
    return rc;
cleanup:
    printf("open file failed\n");
    uci_free_context(ctx);
    ctx = NULL;
    return rc;
}

int config_read_and_subto_topics(struct mosquitto *mosq)
{
    int rc = 0;
    struct uci_context *ctx = NULL;
    struct uci_package *pkg = NULL;
    struct uci_element *e;
    ctx = uci_alloc_context(); //apply for a UCI context.
    if (UCI_OK != uci_load(ctx, UCI_CONFIG_FILE, &pkg))
        goto cleanup; //If the UCI file fails to open, skip to the end to clean up the UCI context.
    /* Traverse every section of UCI */
    uci_foreach_element(&pkg->sections, e)
    {
        struct uci_section *s = uci_to_section(e);
        if (strcmp(s->type, "topic") == 0)
        {
            char *enabled;
            char *topic;
            char *qos;
            READVALUE(ctx, s, enabled, "enabled");
            if (strcmp(enabled, "0") == 0)
            {
                free(enabled);
            }
            else
            {
                READVALUE(ctx, s, topic, "topic");
                READVALUE(ctx, s, qos, "qos");
                int qos_i = atoi(qos);
                mosquitto_subscribe(mosq, NULL, topic, qos_i);
            }
        }
    }
    uci_unload(ctx, pkg); //release pkg
    return rc;
cleanup:
    uci_free_context(ctx);
    ctx = NULL;
    return rc;
}