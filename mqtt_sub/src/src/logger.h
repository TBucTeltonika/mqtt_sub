#ifndef LOGGER_H
#define LOGGER_H
#include <sys/syslog.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>

#define LOGNAME "ProjectIot"

#define LOGTO_LOGREAD

#ifdef LOGTO_LOGREAD
/* USING VERSION THAT WRITES TO SYSTEM LOG. 
ARGUMENTS - pri - priority(int). fmt - format(const char*). args - valist*/
#define TRACE_LOG(pri, fmt, args...) logwritef(pri, fmt, ##args)
#endif
#ifndef LOGTO_LOGREAD
/* USING VERSION THAT WRITES TO THE STDOUT STREAM. */
#define TRACE_LOG(pri, format, args...) \
    fprintf(stderr, format, ##args);    \
    fprintf(stderr, "\n");
#endif

int logwritef(int pri, const char *fmt, ...);
int logwrite(const char *text);
int logwritepri(int pri, const char *text);

#endif
