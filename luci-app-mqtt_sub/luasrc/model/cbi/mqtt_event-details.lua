local fs = require "nixio.fs"
local dsp = require "luci.dispatcher"
local parser = require "tlt_parser_lua"
local util  = require("luci.util")
local cont = require "luci.model.container"
local modem_list = cont.get_all_modems()
local json 	= require "luci.jsonc"
local board = json.parse(fs.readfile("/etc/board.json"))

__RUT300_PLATFORM_START__
local rut3xx = true
__RUT300_PLATFORM_END__
__RUT360_PLATFORM_START__
local rut3xx = true
__RUT360_PLATFORM_END__

local m, s, o

arg[1] = arg[1] or ""

m = Map("events_reporting", translate("Events Reporting Configuration"), translate("This section is used to customize how an Events Reporting rule will function. Scroll your mouse pointer over field names in order to see helpful hints."))

m.redirect = dsp.build_url("admin/services/events_reporting")
if m.uci:get("events_reporting", arg[1]) ~= "rule" then
	luci.http.redirect(dsp.build_url("admin/services/events_reporting"))
	return
end

s = m:section(NamedSection, arg[1], "rule", translate(""))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enable", translate("Enable"), translate("Turns the rule on or off."))
o.rmempty = false

o = s:option(ListValue, "event", translate("Event"), translate("Event that will trigger the rule."))
o:value("Config", translate("Config change"))
o:value("DHCP", translate("New DHCP client"))
if #modem_list > 0 then
	o:value("Mobile Data", translate("Mobile data"))
	o:value("SMS", translate("SMS"))
	--o:value("SIM switch", translate("SIM switch"))
	o:value("Signal strength", translate("Signal strength"))
end
o:value("Reboot", translate("Reboot"))
o:value("SSH", translate("SSH"))
o:value("Web UI", translate("Web UI"))

__RUTX_PLATFORM_START__
o:value("Switch Topology", translate("Topology state"))
o:value("Switch Events", translate("Ports state"))
__RUTX_PLATFORM_END__


if fs.access("/etc/config/mwan3") then
	o:value("Failover", translate("WAN Failover"))
end

if board.hwinfo and board.hwinfo.gps then
	o:value("GPS", translate("GPS"))
end

function o.cfgvalue(...)
	local v = Value.cfgvalue(...)
	return v
end

o = s:option(ListValue, "eventMark", translate("Event type"), translate("More specific event type that will trigger the rule."))
o:value("all", translate("All"), {event = "Config"}, {event = "DHCP"}, {event = "WiFi"},
		{event = "Reboot"}, {event = "SSH"}, {event = "Web UI"}, {event = "GPS"}, {event = "SIM switch"}, {event = "Switch Events"},
		{event = "Failover"}, {event = "Restore Point"}, {event = "Signal strength"}, {event = "Mobile Data"})

o:value("openvpn", translate("OpenVPN"), {event = "Config"})
if #modem_list > 0 then
	o:value("sms", translate("SMS"), {event = "Config"})

	if fs.access("/etc/config/mwan3") then
		o:value("mwan", translate("Multiwan"), {event = "Config"})
	end

	o:value("simcard", translate("Mobile"), {event = "Config"})
	if fs.access("/etc/config/quota_limit") then
		o:value("quota_limit", translate("Data limit"), {event = "Config"})
	end
	if board.hwinfo and board.hwinfo.gps then
		o:value("gps", translate("GPS"), {event = "Config"})
	end
end
if board.hwinfo and board.hwinfo.bluetooth then
	o:value("blesem", translate("Bluetooth"), {event = "Config"})
	o:value("ble_devices", translate("Bluetooth devices"), {event = "Config"})
end
if fs.access("/etc/config/sqm") then
	o:value("sqm", translate("QoS"), {event = "Config"})
end
o:value("events_reporting", translate("Events reporting"), {event = "Config"})
if fs.access("/etc/config/ulogd") then
	o:value("ulogd", translate("Traffic logging"), {event = "Config"})
end
if fs.access("/etc/config/modbus_data_sender") then
	o:value("modbus_data_sender", translate("Data to server"), {event = "Config"})
end
if fs.access("/etc/config/mosquitto") then
	o:value("mosquitto", translate("MQTT broker"), {event = "Config"})
end
if fs.access("/etc/config/mqtt_pub") then
	o:value("mqtt_pub", translate("MQTT publisher"), {event = "Config"})
end
o:value("periodic_reboot", translate("Reboot Scheduler"), {event = "Config"})
o:value("snmpd", translate("SNMP"), {event = "Config"})
o:value("ping_reboot", translate("Ping reboot"), {event = "Config"})
--o:value("auto_update", translate("Auto update"), {event = "Config"})
__RUTX_PLATFORM_START__
o:value("hostblock", translate("Site blocking"), {event = "Config"})
__RUTX_PLATFORM_END__
--o:value("administration", translate("Administration"), {event = "Config"})
if fs.access("/etc/config/chilli") then
	o:value("chilli", translate("Hotspot"), {event = "Config"})
end
if fs.access("/etc/config/ioman") then
	o:value("ioman", translate("Input/output"), {event = "Config"})
end
__RUTX_PLATFORM_START__
o:value("privoxy", translate("Content blocker"), {event = "Config"})
__RUTX_PLATFORM_END__
o:value("profile", translate("Profiles"), {event = "Config"})
o:value("ddns", translate("DDNS"), {event = "Config"})
o:value("strongswan", translate("IPsec"), {event = "Config"})
o:value("dhcp", translate("DHCP"), {event = "Config"})

__RUTX_PLATFORM_START__
o:value("vrrpd", translate("VRRP"), {event = "Config"})
__RUTX_PLATFORM_END__
o:value("dropbear", translate("SSH"), {event = "Config"})
o:value("network", translate("Network"), {event = "Config"})
if fs.access("/etc/config/wireless") then
	o:value("wireless", translate("Wireless"), {event = "Config"})
end
o:value("firewall", translate("Firewall"), {event = "Config"})
o:value("ntp", translate("NTP"), {event = "Config"})
if fs.access("/etc/config/samba") then
	o:value("samba", translate("Network Shares"), {event = "Config"})
end
if fs.access("/etc/config/etherwake") then
	o:value("etherwake", translate("Wake on LAN"), {event = "Config"})
end
__RUTX_PLATFORM_START__
o:value("upnp", translate("UPNP"), {event = "Config"})
__RUTX_PLATFORM_END__
if fs.access("/etc/config/wireless") then
	o:value("wifi", translate("Connected from WiFi"), {event = "DHCP"})
end
o:value("lan", translate("Connected from LAN"), {event = "DHCP"})

o:value("connected", translate("Connected"), {event = "WiFi"})

o:value(" connected", translate("Connected"), {event = "Mobile Data"})
o:value("disconnected", translate("Disconnected"), {event = "Mobile Data"})

o:value("web ui", translate("From Web UI"), {event = "Reboot"})
if #modem_list > 0 then
    o:value("sms", translate("From SMS"), {event = "Reboot"})
end
o:value("input/output", translate("From Input/output"), {event = "Reboot"})
o:value("ping reboot", translate("From ping reboot"), {event = "Reboot"})
o:value("reboot scheduler", translate("From reboot scheduler"), {event = "Reboot"})
o:value("from button", translate("From button"), {event = "Reboot"})

o:value("received from", translate("SMS received"), {event = "SMS"})

o:value("succeeded", translate("Successful authentication"), {event = "SSH"})
o:value("bad", translate("Unsuccessful authentication"), {event = "SSH"})

o:value("was succesful", translate("Successful authentication"), {event = "Web UI"})
o:value("not succesful", translate("Unsuccessful authentication"), {event = "Web UI"})

o:value("left geofence", translate("Left geofence"), {event = "GPS"})
o:value("entered geofence", translate("Entered geofence"), {event = "GPS"})

--o:value("SIM 1 to SIM 2", translate("From SIM 1 to SIM 2"), {event = "SIM switch"})
--o:value("SIM 2 to SIM 1", translate("From SIM 2 to SIM 1"), {event = "SIM switch"})

o:value("Port link state", translate("Link state"), {event = "Switch Events"})
if rut3xx then
	o:value("Port speed for", translate("Link speed (LAN)"), {event = "Switch Events"})
else
	o:value("Port speed for", translate("Link speed"), {event = "Switch Events"})
end

o:value("Changes in topology", translate("Topology changes"), {event = "Switch Topology"})

o:value("main", translate("Switched to main"), {event = "Failover"})
o:value("to backup", translate("Switched to failover"), {event = "Failover"})

--o:value("download", translate("Save"), {event = "Restore Point"})
--o:value("restore", translate("Load"), {event = "Restore Point"})

o:value("Signal strength dropped below -113 dBm", translate("-121dBm -113dBm"), {event = "Signal strength"})
o:value("Signal strength dropped below -98 dBm", translate("-113dBm -98dBm"), {event = "Signal strength"})
o:value("Signal strength dropped below -93 dBm", translate("-98dBm -93dBm"), {event = "Signal strength"})
o:value("Signal strength dropped below -75 dBm", translate("-93dBm -75dBm"), {event = "Signal strength"})
o:value("Signal strength dropped below -60 dBm", translate("-75dBm -60dBm"), {event = "Signal strength"})
o:value("Signal strength dropped below -50 dBm", translate("-60dBm -50dBm"), {event = "Signal strength"})

o = s:option(ListValue, "action", translate("Action"), translate("Action that will be executed when the rule is triggered."))
if #modem_list > 0 then
	o:value("sendSMS", translate("Send SMS"))
end
o:value("sendEmail", translate("Send email"))
function o.cfgvalue(...)
	local v = Value.cfgvalue(...)
	return v
end

if #modem_list > 1 then
	o = s:option(ListValue, "info_modem_id", translate("Modem"), translate("Modem, which is used to get information from"))
	for i,v in ipairs(modem_list) do
		if v.id and v.name then
			o:value(v.id, translate(v.name))
		end
	end
end

if #modem_list > 1 then
	o = s:option(ListValue, "send_modem_id", translate("Gateway modem"), translate("Modem, which is used to send information from"))
	for i,v in ipairs(modem_list) do
		if v.id and v.name then
			o:value(v.id, translate(v.name))
		end
	end
	o:depends("action", "sendSMS")
end

emailsub = s:option(Value, "subject", translate("Subject"), translate("Subject of an email. Allowed characters (a-zA-Z0-9!@#$%&*+-/=?^_`{|}~. )"))
emailsub:depends("action", "sendEmail")
emailsub.datatype = "fieldvalidation('^[a-zA-Z0-9!@#%$%%&%*%+%-/=%?%^_`{|}~%. ]+$',0)"
emailsub.maxlength = "128"
--
message = s:option(TextValue, "message", translate("Message text on Event"), translate("Message to send"))
message.template = "events_reporting/events_textbox"
message.default = "Device name - %rn; Event type - %et; Event text - %ex; Time stamp - %ts;"
message.rows = "8"
message.placeholder = "Device name - %rn; Event type - %et; Event text - %ex; Time stamp - %ts;"
message.indicator = arg[1]

function message.parse(self, section, novld, ...)
	local val = self:formvalue(section)
	if not val or val == "" then
		m:error_msg(translate("Message field is empty!"))
		m.save  = false
	end
	Value.parse(self, section, novld, ...)
end

o = s:option(ListValue, "recipient_format", translate("Recipients"), translate("You can choose to add single numbers in a list or use a phone group list"))
o:depends("action", "sendSMS")
o:value("single", translate("Single number"))
o:value("group", translate("Group"))

telnum = s:option(Value, "telnum", translate("Recipient's phone number"), translate("To whom the message will be sent. The number must be specified in full format, country code included. e.g., +37000000000."))
telnum:depends("recipient_format", "single")
telnum.placeholder = "+37000000000"
telnum.datatype	= "phonedigit"
telnum.rmempty = false

function telnum.parse(self, section, novld, ...)
	local val = self:formvalue(section)
	if val and #val == 0 then
		self:add_error(section, "invalid", translate("Empty phone number field"))
		return false
	elseif val then
		Value.parse(self, section, novld, ...)
	end
end

function telnum.validate(_, value)
	if value and not value:match("^[0-9\*+#]+$") then
		return nil, translatef("Invalid phone number %s", value)
	end
	return value
end

o = s:option(ListValue, "group", translate("Phone group"), translate("A recipient's phone number users group (<a href=\"/cgi-bin/luci/admin/system/admin/group/phone\" class=\"link\">configure it here</a>)"))
o:depends("recipient_format", "group")
local no_groups = true
m.uci:foreach("user_groups", "phone", function(s)
	o:value(s.name, s.name)
	no_groups = false
end)

if no_groups then 
	o:value("0", translate("No phone groups created"))
	function o.write() end
end

function o.parse(self, section, novld, ...)
	local val = self:formvalue(section)
	if val and val == "0" then
		self:add_error(section, "invalid", translate("No phone group selected"))
	end
	Value.parse(self, section, novld, ...)
end

local is_group = false
mailGroup = s:option(ListValue, "emailgroup", translate("Email account"), translate("Recipient's email configuration <br/>(<a href=\"/cgi-bin/luci/admin/system/admin/group/email\" class=\"link\">configure it here</a>)"))
mailGroup:depends("action", "sendEmail")
m.uci:foreach("user_groups", "email", function(s)
	if s.senderemail then
		mailGroup:value(s.name, s.name)
		is_group = true
	end
end)
if not is_group then
	mailGroup:value(0, translate("No email accounts created"))
end

function mailGroup.parse(self, section, novld, ...)
	local val = self:formvalue(section)
	if val and val == "0" then
		self:add_error(section, "invalid", translate("No email accounts selected"))
	end
	Value.parse(self, section, novld, ...)
end

recEmail = s:option(DynamicList, "recipEmail", translate("Recipient's email address"), translate("For whom you want to send an email to. Allowed characters (a-zA-Z0-9._%+@-)"))
recEmail:depends("action", "sendEmail")
recEmail.datatype = "email"
recEmail.placeholder = "mail@domain.com"

testMail = s:option(Button, "_testMail")
testMail.template = "events_reporting/events_button"
testMail.title = translate("Send test email")
testMail.inputtitle = translate("Send")
testMail.onclick = true
testMail:depends("action", "sendEmail")

function testMail.write(self) end


function m.on_parse(self)
	local group_name = m:formvalue("cbid.events_reporting."..arg[1]..".emailgroup")
	if group_name ~= "0" then
		if m:formvalue("cbid.events_reporting."..arg[1].."._testMail") then
			local group
			m.uci:foreach("user_groups", "email", function(s)
				if s.name == group_name then
					group = s[".name"]
				end
			end)
			local t = {}
			local call, result = {}, {}
			local ev_type = m:formvalue("cbid.events_reporting."..arg[1]..".event")
			local recMail = {}
			local status = ""
			local message = m:formvalue("cbid.events_reporting."..arg[1]..".message")
			local secure = m.uci:get("user_groups", group, "secure_conn") or "0"
			local smtpIP = m.uci:get("user_groups", group, "smtp_ip")
			local smtpPort = m.uci:get("user_groups", group, "smtp_port") 
			local username = m.uci:get("user_groups", group, "username")
			local passwd = m.uci:get("user_groups", group, "password")  
			local credentials = m.uci:get("user_groups", group, "credentials")  
			local senderEmail = m.uci:get("user_groups", group, "senderemail") 
			local subject = m:formvalue("cbid.events_reporting."..arg[1]..".subject")
			local recMail = m:formvalue("cbid.events_reporting."..arg[1]..".recipEmail")
			if type(recMail) == "table" then
				for i = 1, #recMail, 1 do

					table.insert(t, tostring(" "..recMail[i].." "))
					luci.sys.exec("echo \"|".. recMail[i] .. "|\" > /tmp/ff")
				end
				allRecMail = table.concat(t)
			else
				luci.sys.exec("echo \"|".. recMail .. "|\" > /tmp/ff")
				allRecMail = m:formvalue("cbid.events_reporting."..arg[1]..".recipEmail")
			end

			if string.find(message, "\%et") then
				message = string.gsub(message, "%%et", ev_type)
			end
			if string.find(message, "\%ex") then
				message = string.gsub(message, "%%ex", "Test email")
			end
			call = {text = message}

			result = parser:parse_msg(call)
			message = util.trim(result)

			--isvalomas tempinis failiukas
			luci.sys.call("echo -n >/tmp/sendmail")

			if secure == "1" then
				if credentials == "1" then
					username = " -au\"" .. username .. "\""
					passwd = " -ap\"" .. passwd .. "\""
				else
					username = " "
					passwd = " "
				end
				luci.sys.call("(echo -e \"subject:".. subject .."\nfrom:".. senderEmail .."\n".. message .."\" | sendmail -v -H \"exec openssl s_client -quiet -connect ".. smtpIP ..":".. smtpPort .." -tls1_2 -starttls smtp\" -f ".. senderEmail .." ".. username .." ".. passwd .." ".. allRecMail .."; echo $? >/tmp/sendmail ) &")
				for time = 0, 30, 1 do
					status = util.trim(luci.sys.exec("cat /tmp/sendmail"))
					if status ~= "" then
						break
					end
					luci.sys.exec("sleep 1")
					if time == 30 then
						luci.sys.exec("killall sendmail")
					end
				end
			elseif secure == "0" then
				if credentials == "1" then
					username = " -au\"" .. username .. "\""
					passwd = " -ap\"" .. passwd .. "\""
				else
					username = " "
					passwd = " "
				end
				luci.sys.exec("(echo -e \"subject:".. subject .."\nfrom:".. senderEmail .."\n".. message .."\" | sendmail -S \"".. smtpIP ..":".. smtpPort .."\" -f ".. senderEmail .." ".. username .." ".. passwd .." ".. allRecMail .."; echo $? >/tmp/sendmail )&")
				for time = 0, 30, 1 do
					status = util.trim(luci.sys.exec("cat /tmp/sendmail"))
					if status ~= "" then
						break
					end
					luci.sys.exec("sleep 1")
					if time == 30 then
						luci.sys.exec("killall sendmail")
					end
				end
			end
			--trinamas tempinisfailiukas
			luci.sys.call("rm /tmp/sendmail")

			if status == "0" then
				m.message = translate("Mail sent successful")
			else
				m.message = translate("Mail sent failed")
			end
		end
	else
		m.save  = false
		return false
	end
	return 0
end

function m.on_save(self)
	local group_name = m:formvalue("cbid.events_reporting."..arg[1]..".emailgroup")
	local group
	m.uci:foreach("user_groups", "email", function(s)
		if s.name == group_name then
			group = s[".name"]
		end
	end)
	local smtpIP = m.uci:get("user_groups", group, "smtp_ip") 
	local smtpPort = m.uci:get("user_groups", group, "smtp_port") 
	local username = m.uci:get("user_groups", group, "username") 
	local passwd = m.uci:get("user_groups", group, "password") 
	local senderEmail = m.uci:get("user_groups", group, "senderemail") 
	local secure = m.uci:get("user_groups", group, "secure_conn") 
	m.uci:delete("events_reporting", arg[1], "userName")
	m.uci:delete("events_reporting", arg[1], "password")
	m.uci:set("events_reporting",arg[1],"senderEmail", senderEmail)
	m.uci:set("events_reporting",arg[1],"password", passwd)
	m.uci:set("events_reporting",arg[1],"userName", username)
	m.uci:set("events_reporting",arg[1],"smtpPort", smtpPort)
	m.uci:set("events_reporting",arg[1],"smtpIP", smtpIP)
	m.uci:set("events_reporting",arg[1],"secureConnection", secure)
end

return m
