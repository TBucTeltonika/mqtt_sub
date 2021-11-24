/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) 1998 - 2021, Daniel Stenberg, <daniel@haxx.se>, et al.
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution. The terms
 * are also available at https://curl.se/docs/copyright.html.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the COPYING file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 ***************************************************************************/

/* <DESC>
 * Modified into a function that takes variables.
 * </DESC>
 */

#include <curl/curl.h>
#include <stdio.h>
#include <string.h>

#include "email.h"

struct upload_status {
	char *payloadText[11];
	int	  lines_read;
};

static size_t payload_source(void *ptr, size_t size, size_t nmemb, void *userp)
{
	struct upload_status *upload_ctx = (struct upload_status *)userp;
	const char *		  data;

	if ((size == 0) || (nmemb == 0) || ((size * nmemb) < 1)) {
		return 0;
	}
	static size_t mail_size = sizeof(upload_ctx->payloadText) / sizeof(upload_ctx->payloadText[0]);

	for (int i = upload_ctx->lines_read; i < mail_size; i++) {
		data = upload_ctx->payloadText[i];
		if (data) {
			size_t len = strlen(data);
			memcpy(ptr, data, len);
			upload_ctx->lines_read++;

			return len;
		} else
			upload_ctx->lines_read++;
	}

	return 0;
}

void setPayloadText(char **payloadText, char *to, char *from, char *cc, char *nameFrom, char *subject, char *body)
{
	payloadText[0] = NULL;
	asprintf(&payloadText[1], "To: %s\r\n", to);
	if (nameFrom)
		asprintf(&payloadText[2], "From: %s\r\n", nameFrom);
	else
		asprintf(&payloadText[2], "From: %s\r\n", from);
	if (cc != NULL)
		asprintf(&payloadText[3], "Cc: %s \"%s\"\r\n", cc, nameFrom);
	else
		payloadText[3] = NULL;
	payloadText[4] = NULL;
	asprintf(&payloadText[5], "Subject: %s\r\n", subject);
	asprintf(&payloadText[6], "\r\n");
	asprintf(&payloadText[7], "%s\r\n", body);
	asprintf(&payloadText[8], "\r\n");
	asprintf(&payloadText[9], "\r\n");
	asprintf(&payloadText[10], "\r\n");
}

int sendEmail(char *to,
			  char *from,
			  char *cc,
			  char *nameFrom,
			  char *subject,
			  char *body,
			  char *url,
			  int	port,
			  char *password,
			  int	secure)
{
	CURL *				 curl;
	CURLcode			 res		= CURLE_OK;
	struct curl_slist *	 recipients = NULL;
	struct upload_status upload_ctx = {0};

	curl = curl_easy_init();
	if (curl) {
		/* This is the URL for your mailserver */
		curl_easy_setopt(curl, CURLOPT_DEFAULT_PROTOCOL, "smtps");
		curl_easy_setopt(curl, CURLOPT_PORT, port);
		curl_easy_setopt(curl, CURLOPT_URL, url);

		if (secure)
			curl_easy_setopt(curl, CURLOPT_USE_SSL, CURLUSESSL_ALL);

		curl_easy_setopt(curl, CURLOPT_MAIL_FROM, from);

		/* Add two recipients, in this particular case they correspond to the
		 * To: and Cc: addressees in the header, but they could be any kind of
		 * recipient. */
		recipients = curl_slist_append(recipients, to);
		if (cc != NULL)
			recipients = curl_slist_append(recipients, cc);
		curl_easy_setopt(curl, CURLOPT_MAIL_RCPT, recipients);

		curl_easy_setopt(curl, CURLOPT_USERNAME, from);
		curl_easy_setopt(curl, CURLOPT_PASSWORD, password);

		setPayloadText(&upload_ctx.payloadText, to, from, cc, nameFrom, subject, body);

		curl_easy_setopt(curl, CURLOPT_READFUNCTION, payload_source);
		curl_easy_setopt(curl, CURLOPT_READDATA, &upload_ctx);
		curl_easy_setopt(curl, CURLOPT_UPLOAD, 1L);
		/* Send the message */
		res = curl_easy_perform(curl);

		/* Check for errors */
		if (res != CURLE_OK) {
			TRACE_LOG(LOG_ERR, "curl_easy_perform() failed: %s %d\n", curl_easy_strerror(res), res);
		} else {
			TRACE_LOG(LOG_INFO, "curl_easy_perform() success\n");
		}
		/* Free the list of recipients */
		curl_slist_free_all(recipients);

		curl_easy_cleanup(curl);
	}
	return (int)res;
}