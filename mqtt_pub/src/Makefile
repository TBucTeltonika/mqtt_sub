DEPS = $(wildcard *.h)
SRC = $(wildcard src/*.c)
OBJ = $(patsubst %.c, %.o, $(SRC))
TARGET = mqtt_pub
LDFLAGS+=-luci -ltlt_uci -lmosquitto -lubus -lubox -ljson-c -lblobmsg_json
RM = rm -f

all: $(TARGET)

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET): $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS)

.PHONY: clean

clean:
	$(RM) $(OBJ) $(TARGET)
