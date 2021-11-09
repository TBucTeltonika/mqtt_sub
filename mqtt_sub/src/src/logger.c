#include "logger.h"

int logwritepri(int pri, const char *text)
{
    openlog(LOGNAME, 0, LOG_DAEMON);

    syslog(pri, "%s", text);

    closelog();
    return 0;
}
int logwrite(const char *text)
{
    return logwritepri(LOG_INFO, text);
}
int logwritef(int pri, const char *fmt, ...)
{
    openlog(LOGNAME, 0, LOG_DAEMON);

    va_list args;
    va_start(args, fmt);
    syslog(pri, fmt, args);
    va_end(args);

    closelog();
    return 0;
}