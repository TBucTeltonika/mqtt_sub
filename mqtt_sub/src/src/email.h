#include <stdio.h>
#include <string.h>
#define CURLPROTO_SMTP
#include <curl/curl.h>
#include <stdlib.h>
#include <time.h>
#include "logger.h"
int sendEmail(char *to,
			  char *from,
			  char *cc,
			  char *nameFrom,
			  char *subject,
			  char *body,
			  char *url,
			  int	port,
			  char *password,
			  int	secure);
