#ifndef LOGGER_H
#define LOGGER_H
#include <sys/syslog.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>


#define	LOG_EMERG	0	/* system is unusable */
#define	LOG_ALERT	1	/* action must be taken immediately */
#define	LOG_CRIT	2	/* critical conditions */
#define	LOG_ERR		3	/* error conditions */
#define	LOG_WARNING	4	/* warning conditions */
#define	LOG_NOTICE	5	/* normal but significant condition */
#define	LOG_INFO	6	/* informational */
#define	LOG_DEBUG	7	/* debug-level messages */

#define LOGNAME "MQTT_CLIENT"

#define LOGTO_LOGREAD

#ifdef LOGTO_LOGREAD
/* USING VERSION THAT WRITES TO SYSTEM LOG. 
ARGUMENTS - pri - priority(int). fmt - format(const char*). args - valist*/
#define TRACE_LOG(pri, fmt, args...) logwritef(pri, fmt, ##args)
#endif
#ifndef LOGTO_LOGREAD
/* USING VERSION THAT WRITES TO THE STDOUT STREAM. */
#define TRACE_LOG(pri, format, args...) printf(format, ##args);

#endif

int logwritef(int pri, const char *fmt, ...);
int logwrite(const char *text);
int logwritepri(int pri, const char *text);

#endif
