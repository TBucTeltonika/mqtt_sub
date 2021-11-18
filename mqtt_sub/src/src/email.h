#include <stdio.h>
#include <string.h>
#include <curl/curl.h>
 
/*
 * For an SMTP example using the multi interface please see smtp-multi.c.
 */
 
/* The libcurl options want plain addresses, the viewable headers in the mail
 * can very well get a full name as well.
 */
#define FROM_ADDR    "<sender@example.org>"
#define TO_ADDR      "<addressee@example.net>"
#define CC_ADDR      "<info@example.org>"
 
#define FROM_MAIL "Sender Person " FROM_ADDR
#define TO_MAIL   "A Receiver " TO_ADDR
#define CC_MAIL   "John CC Smith " CC_ADDR
 
static const char *payload_text =
  "Date: Mon, 29 Nov 2010 21:54:29 +1100\r\n"
  "To: " TO_MAIL "\r\n"
  "From: " FROM_MAIL "\r\n"
  "Cc: " CC_MAIL "\r\n"
  "Message-ID: <dcd7cb36-11db-487a-9f3a-e652a9458efd@"
  "rfcpedant.example.org>\r\n"
  "Subject: SMTP example message\r\n"
  "\r\n" /* empty line to divide headers from body, see RFC5322 */
  "The body of the message starts here.\r\n"
  "\r\n"
  "It could be a lot of lines, could be MIME encoded, whatever.\r\n"
  "Check RFC5322.\r\n";
 
struct upload_status {
  size_t bytes_read;
};
 
static size_t payload_source(char *ptr, size_t size, size_t nmemb, void *userp);
int send(void);

 
