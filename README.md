# luci-app_mqtt_sub
Frontend application written in Luci that is responsible for:

Configuration - settings for backend application
Log viewing - viewing data from user configured topics.
Applicaiton Control - Start and stop mqtt_sub.

# mqtt_sub
Backend application which acts as a MQTT Client.

Subscribe to topics.

Write events to a database.

Subscribe to events.

Process events.

Send emails based on events.


# Features
Can subscribe to any topic and save topic/message/time to Database.

QoS levels supported.

Can add events which support json values with conditions.

Email will be sent if event condition is satisfied.

Supports TLS/SSL

# Other
Tested on RUTX_R_00.02.06.1 

# Credits

Sending emails over SMTP using Libcurl:
[libcurl API example](https://curl.se/libcurl/c/smtp-mail.html)

Linked implementation based on:
[A generic linked list library for C  by  @meylingtaing](https://gist.github.com/meylingtaing/11018042)

cJson library used:
[cJSON by @DaveGamble](https://github.com/DaveGamble/cJSON)
