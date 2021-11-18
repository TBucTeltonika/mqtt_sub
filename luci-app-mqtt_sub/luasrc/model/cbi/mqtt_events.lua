--[[

LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: forwards.lua 8117 2011-12-20 03:14:54Z jow $
]]--

local ds = require "luci.dispatcher"

m = Map("mqtt_events", translate(""))
--translate("Create rules for events reporting.")

--
-- Port Forwards
--

s = m:section(TypedSection, "rule", translate("Events Reporting Rules"), translate("This section displays Events Reporting rules that are currently configured on the router. Events Reporting rules inform you via SMS when certain specified events occur on the router. Click the 'Add' button to create a new rule and begin configuring it."))
s.template  = "cbi/tblsection"
s.addremove = true
s.anonymous = true
s.sortable  = true
s.extedit   = ds.build_url("admin/services/events_reporting/%s")
s.template_addremove = "cbi/add_rule"
s.novaluetext = translate("There are no events reporting rules created yet")
s.delete_alert = true
s.alert_message = translate("Are you sure you want to delete this rule?")

s.cfgsections = function (self)
	local sections = {}

	self.map.uci:foreach(self.config, self.sectiontype, function(s)
		if s.action ~= "sendRMS" then
			table.insert(sections, s[".name"])
		end
	end)

	return sections
end

function s.create(self, section)
	created = TypedSection.create(self, section)
end

function s.parse(self, ...)
	TypedSection.parse(self, ...)
	if created then
		m.uci:save(self.config)
		luci.http.redirect(ds.build_url("admin/services/events_reporting", created))
	else
		m.uci:save(self.config)
		m.uci.commit(self.config)
	end
end

src = s:option(DummyValue, "event", translate("Event type"), translate("Event type for which the rule is applied"))
src.rawhtml = true
src.width = "16%"
function src.cfgvalue(self, s)
	local z = self.map:get(s, "event")
	if z == "Config" then
		return translatef("Config change")
	elseif z == "DHCP" then
		return translatef("New DHCP client")
	elseif z == "Mobile Data" then
		return translatef("Mobile data")
	elseif z == "Reboot" then
		return translatef("Reboot")
	elseif z == "SMS" then
		return translatef("SMS")
	elseif z == "SSH" then
		return translatef("SSH")
	elseif z == "Web UI" then
		return translatef("Web UI")
	--elseif z == "WiFi" then
	--	return translatef("New WiFi client")
	--elseif z == "SIM switch" then
	--	return translatef("SIM switch")
	elseif z == "Signal strength" then
		return translatef("Signal strength")
	elseif z == "GPS" then
		return translatef("GPS")
	elseif z == "Switch Events" then
		return translatef("Port State")
	elseif z == "Switch Topology" then
		return translatef("Topology Changes")
	elseif z == "Failover" then
		return translatef("WAN Failover")
	--elseif z == "Restore Point" then
	--	return translatef("Restore Point")
	else
	    return translatef("NA")
	end
end

src = s:option(DummyValue, "eventMark", translate("Event subtype"), translate("Event subtype for which the rule is applied"))
src.rawhtml = true
src.width = "20%"
function src.cfgvalue(self, s)
	local t = self.map:get(s, "eventMark")
	local z = self.map:get(s, "event")
	if t == "all" then
		return translatef("All")
-- Config
	elseif t == "openvpn" and z == "Config" then
		return translatef("OpenVPN")
	elseif t == "sms" and z == "Config" then
		return translatef("SMS")
	elseif t == "events_reporting" and z == "Config" then
		return translatef("Events reporting")
	elseif t == "gps" and z == "Config" then
		return translatef("GPS")
	elseif t == "blesem" and z == "Config" then
		return translate("Bluetooth")
	elseif t == "ble_devices" and z == "Config" then
		return translate("Bluetooth devices")
	elseif t == "sqm" and z == "Config" then
		return translate("QoS")
	elseif t == "ulogd" and z == "Config" then
		return translate("Traffic logging")
	elseif t == "modbus_data_sender" and z == "Config" then
		return translate("Data to server")
	elseif t == "mosquitto" and z == "Config" then
		return translate("MQTT broker")
	elseif t == "mqtt_pub" and z == "Config" then
		return translate("MQTT publisher")
	elseif t == "periodic_reboot" and z == "Config" then
		return translatef("Reboot Scheduler")
	elseif t == "snmpd" and z == "Config" then
		return translatef("SNMP")
	elseif t == "ping_reboot" and z == "Config" then
		return translatef("Ping reboot")
	--elseif t == "auto update" and z == "Config" then
	--	return translatef("Auto update")
	elseif t == "hostblock" and z == "Config" then
		return translatef("Site blocking")
	elseif t == "chilli" and z == "Config" then
		return translatef("Hotspot")
	elseif t == "ioman" and z == "Config" then
		return translatef("Input/output")
	elseif t == "privoxy" and z == "Config" then
		return translatef("Proxy blocking")
	--elseif t == "login page" and z == "Config" then
	--	return translatef("Login page")
	elseif t == "quota_limit" and z == "Config" then
		return translatef("Data limit")
	--elseif t == "language" and z == "Config" then
    --  return translatef("Language")
	elseif t == "profile" and z == "Config" then
		return translatef("Profile")
	elseif t == "ddns" and z == "Config" then
		return translatef("DDNS")
	--elseif t == "mobile traffic" and z == "Config" then
	--	return translatef("Mobile traffic")
	elseif t == "strongswan" and z == "Config" then
		return translatef("IPsec")
	--elseif t == "access control" and z == "Config" then
	--	return translatef("Access control")
	elseif t == "dhcp" and z == "Config" then
		return translatef("DHCP")
	elseif t == "mwan" and z == "Config" then
		return translatef("Multiwan")
	--elseif t == "rs232/rs485" and z == "Config" then
	--	return translatef("RS232/RS485")
	elseif t == "vrrpd" and z == "Config" then
		return translatef("VRRP")
	elseif t == "dropbear" and z == "Config" then
		return translatef("SSH")
	elseif t == "network" and z == "Config" then
		return translatef("Network")
	--elseif t == "sim switch" and z == "Config" then
	--	return translatef("SIM switch")
	elseif t == "wireless" and z == "Config" then
		return translatef("Wireless")
	elseif t == "firewall" and z == "Config" then
		return translatef("Firewall")
	elseif t == "ntp" and z == "Config" then
		return translatef("NTP")
	elseif t == "samba" and z == "Config" then
		return translate("Network shares")
	elseif t == "etherwake" and z == "Config" then
		return translate("Wake on LAN")
    elseif t == "call_utils" and z == "Config" then
        return translatef("Call Utilities")
    elseif t == "sms_utils" and z == "Config" then
        return translatef("SMS Utilities")
	elseif t == "simcard" and z == "Config" then
		return translatef("Mobile")
	elseif t == "upnp" and z == "Config" then
		return translatef("UPNP")
-- DHCP
	elseif t == "wifi" and z == "DHCP" then
		return translatef("Connected from WiFi")
	elseif t == "lan" and z == "DHCP" then
		return translatef("Connected from LAN")
-- Mobile Data
	elseif t == " connected" and z == "Mobile Data" then
		return translatef("Connected")
	elseif t == "disconnected" and z == "Mobile Data" then
		return translatef("Disconnected")
-- Reboot
	elseif t == "web ui" and z == "Reboot" then
		return translatef("From Web UI")
	elseif t == "sms" and z == "Reboot" then
		return translatef("From SMS")
	elseif t == "input/output" and z == "Reboot" then
        return translatef("From input/output")
	elseif t == "ping reboot" and z == "Reboot" then
		return translatef("From ping reboot")
	elseif t == "reboot scheduler" and z == "Reboot" then
		return translatef("From reboot scheduler")
	elseif t == "from button" and z == "Reboot" then
		return translatef("From button")
-- SMS
	elseif t == "received from" and z == "SMS" then
		return translatef("SMS received")
-- SSH
	elseif t == "succeeded" and z == "SSH" then
		return translatef("Successful authentication")
	elseif t == "bad" and z == "SSH" then
		return translatef("Unsuccessful authentication")
-- Web UI
	elseif t == "was succesful" and z == "Web UI" then
		return translatef("Successful authentication")
	elseif t == "not succesful" and z == "Web UI" then
		return translatef("Unsuccessful authentication")
-- WiFi
	--elseif t == "connected" and z == "WiFi" then
	--	return translatef("Connected")
	--elseif t == "disconnected" and z == "WiFi" then
	--	return translatef("Disconnected")
-- SIM switch
	--elseif t == "SIM 1 to SIM 2" and z == "SIM switch" then
	--	return translatef("From SIM1 to SIM2")
	--elseif t == "SIM 2 to SIM 1" and z == "SIM switch" then
	--	return translatef("From SIM2 to SIM1")
-- GPS
	elseif t == "left geofence" and z == "GPS" then
		return translatef("Left geofence")
	elseif t == "entered geofence" and z == "GPS" then
		return translatef("Entered geofence")
-- Signal strength
	elseif t == "Signal strength dropped below -113 dBm" and z == "Signal strength" then
		return translatef("Signal strength dropped below -113 dBm")
	elseif t == "Signal strength dropped below -98 dBm" and z == "Signal strength" then
		return translatef("Signal strength dropped below -98 dBm")
	elseif t == "Signal strength dropped below -93 dBm" and z == "Signal strength" then
		return translatef("Signal strength dropped below -93 dBm")
	elseif t == "Signal strength dropped below -75 dBm" and z == "Signal strength" then
		return translatef("Signal strength dropped below -75 dBm")
	elseif t == "Signal strength dropped below -60 dBm" and z == "Signal strength" then
		return translatef("Signal strength dropped below -60 dBm")
	elseif t == "Signal strength dropped below -50 dBm" and z == "Signal strength" then
		return translatef("Signal strength dropped below -50 dBm")
-- LAN Port cheker
	elseif t == "Port link state" and z == "Switch Events" then
		return translatef("Link State")
	elseif t == "Port speed for" and z == "Switch Events" then
		return translatef("Link Speed")
	elseif t == "Changes in topology" and z == "Switch Topology" then
		return translatef("Topology Changes")
--Backup
	elseif t == "main" and z == "Failover" then
		return translatef("Switched to main")
	elseif t == "to backup" and z == "Failover" then
		return translatef("Switched to failover")
--Restore point
	--elseif t == "download" and z == "Restore Point" then
	--	return translatef("Save")
	--elseif t == "restore" and z == "Restore Point" then
	--	return translatef("Restore")
	--else
	--	return translatef("N/A")
	end
end

src = s:option(DummyValue, "action", translate("Action"), translate("Action to perform when an event occurs"))
src.rawhtml = true
src.width = "18%"
function src.cfgvalue(self, s)
	local z = self.map:get(s, "action")
	if z == "sendSMS" then
		return translatef("Send SMS")
	elseif z == "sendEmail" then
		return translatef("Send email")
	else
	    return translatef("NA")
	end
end

en = s:option(Flag, "enable", translate(""))
en.width = "18%"
en.default = en.enabled
en.rmempty = false
en.last = true

return m
