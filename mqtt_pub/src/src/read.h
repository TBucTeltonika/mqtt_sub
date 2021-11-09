#ifndef READ_H
#define READ_H

#include <stddef.h>
#if defined(RUT2) || defined(RUT9)
	#include <libtlt_uci/libtlt_uci.h>
#else
	#include <libtlt_uci.h>
#endif

int read_init(void);
int read_serial(size_t n, char *s);
int read_uptime(size_t n, char *s);
int read_temperature(size_t n, char *s);
int read_operator(size_t n, char *s);
int read_signal(size_t n, char *s);
int read_network(size_t n, char *s);
int read_connection(size_t n, char *s);
int read_wan(size_t n, char *s);
int read_device_code(size_t n, char *s);
int read_lan_mac(size_t n, char *s);
int read_digital1(size_t n, char *s);
int read_digital2(size_t n, char *s);
int read_analog(size_t n, char *s);
int read_dout1(size_t n, char *s);
int read_dout2(size_t n, char *s);
int read_pin2(size_t n, char *s);
int read_pin3(size_t n, char *s);
int read_pin4(size_t n, char *s);

#endif
