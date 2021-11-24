include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=mqtt_sub
PKG_VERSION:=1


include $(INCLUDE_DIR)/package.mk

define Package/mqtt_sub
	SECTION:=net
	CATEGORY:=Network
	TITLE:=mqtt subscribe client
	DEPENDS:=+libuci +libtlt_uci +libmosquitto +libubus +libjson-c +libubox +libblobmsg-json +lsqlite3 +libcurl
endef

define Package/mqtt_sub/description
	MQTT client daemon by TomasB
endef

define Package/mqtt_sub/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/mqtt_sub.conf $(1)/etc/config/mqtt_sub
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/mqtt_sub.init $(1)/etc/init.d/mqtt_sub
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mqtt_sub $(1)/usr/sbin/mqtt_sub
endef

$(eval $(call BuildPackage,mqtt_sub))
