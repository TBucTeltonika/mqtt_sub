DEPS = $(wildcard *.h)
SRC = $(wildcard src/*.c)
OBJ = $(patsubst %.c, %.o, $(SRC))
TARGET = mqtt_sub
LDFLAGS+=-luci -ltlt_uci -lmosquitto -lubus -lubox -ljson-c -lblobmsg_json -lsqlite3
RM = rm -f
#INC=-L/home/tomas/Desktop/rutos/staging_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/usr/lib
#DEPS2 = MQTTAsync.h MQTTClientPersistence.h MQTTProperties.h MQTTClient.h MQTTReasonCodes.h MQTTSub$


all: $(TARGET)

%.o: %.c $(DEPS) 
	$(CC) -c -o $@ $< $(CFLAGS) 

$(TARGET): $(OBJ)
	$(CC) -o  $@ $^  $(LDFLAGS) 

.PHONY: clean

clean:
	$(RM) $(OBJ) $(TARGET)
