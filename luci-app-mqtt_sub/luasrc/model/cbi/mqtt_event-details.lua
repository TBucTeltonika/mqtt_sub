local fs = require "nixio.fs"
local dsp = require "luci.dispatcher"
local parser = require "tlt_parser_lua"
local util  = require("luci.util")
local cont = require "luci.model.container"
local modem_list = cont.get_all_modems()
local json 	= require "luci.jsonc"
local board = json.parse(fs.readfile("/etc/board.json"))


local m, s, o

arg[1] = arg[1] or ""

m = Map("mqtt_events", translate("MQTT Client Events Reporting Configuration"), translate("This section is used to customize how an Events Reporting rule will function. Scroll your mouse pointer over field names in order to see helpful hints."))

m.redirect = dsp.build_url("admin/services/mqtt/client/events")
if m.uci:get("mqtt_events", arg[1]) ~= "rule" then
	luci.http.redirect(dsp.build_url("admin/services/mqtt/client/events"))
	return
end

s = m:section(NamedSection, arg[1], "rule", translate(""))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enable", translate("Enable"), translate("Turns the rule on or off."))
o.rmempty = false

------Topic
topic = s:option(Value, "topic", translate("Topic which will be listened to."), translate("Topic where you expect phone messages. Server is the same as in the client field."))
topic.placeholder = "#"
topic.rmempty = false
topic.datatype = "fieldvalidation('^[a-zA-Z0-9!@#%$%%&%*%+%-/=%?%^_`{|}~%. ]+$',0)"



function topic.parse(self, section, novld, ...)
	local val = self:formvalue(section)
	if val and #val == 0 then
		self:add_error(section, "invalid", translate("Empty topic field"))
		return false
	elseif val then
		Value.parse(self, section, novld, ...)
	end
end

--------Key
key = s:option(Value, "key", translate("Key"), translate("Key in the json message.."))
key.placeholder = "#"
key.rmempty = false
key.datatype = "fieldvalidation('^[a-zA-Z0-9!@#%$%%&%*%+%-/=%?%^_`{|}~%. ]+$',0)"

function key.parse(self, section, novld, ...)
	local val = self:formvalue(section)
	if val and #val == 0 then
		self:add_error(section, "invalid", translate("Empty key field"))
		return false
	elseif val then
		Value.parse(self, section, novld, ...)
	end
end

--------Type
o = s:option(ListValue, "type", translate("Type"), translate("Value type."))
o:value("Integer", translate("Integer"))
o:value("String", translate("String"))


function o.cfgvalue(...)
	local v = Value.cfgvalue(...)
	return v
end

--CompType

o = s:option(ListValue, "compType", translate("Comparison type for values"), translate("More specific event type that will trigger the rule."))

o:value("equal", translate("=="), {type = "String"}, {type = "Integer"})
o:value("notequal", translate("=/="), {type = "String"}, {type = "Integer"})

o:value("lessthan", translate("<"), {type = "Integer"})
o:value("morethan", translate(">"), {type = "Integer"})
o:value("lessorequalthan", translate("<="), {type = "Integer"})
o:value("moreorequalthan", translate(">="), {type = "Integer"})



--Value
var = s:option(Value, "value", translate("Value"), translate("Value to compare to."))
var:depends("type", "String")
var.maxlength = "128"
var.datatype = "fieldvalidation('^[a-zA-Z0-9!@#%$%%&%*%+%-/=%?%^_`{|}~%. ]+$',0)"

--Value
varint = s:option(Value, "valueint", translate("Value"), translate("Value to compare to."))
varint:depends("type", "Integer")
varint.maxlength = "9"
varint.datatype = "integer"

--
--if x == "String" then
--	value.datatype = "fieldvalidation('^[a-zA-Z0-9!@#%$%%&%*%+%-/=%?%^_`{|}~%. ]+$',0)"
--else
--	value.datatype = "integer"
--en





emailsub = s:option(Value, "subject", translate("Subject"), translate("Subject of an email. Allowed characters (a-zA-Z0-9!@#$%&*+-/=?^_`{|}~. )"))
--emailsub:depends("action", "sendEmail")
emailsub.datatype = "fieldvalidation('^[a-zA-Z0-9!@#%$%%&%*%+%-/=%?%^_`{|}~%. ]+$',0)"
emailsub.maxlength = "128"
--
message = s:option(TextValue, "message", translate("Message text on Event"), translate("Message to send"))
--message.template = "events_reporting/events_textbox"
message.default = "Event has been triggered."
message.rows = "8"
message.placeholder = "Event has been triggered."
message.indicator = arg[1]

function message.parse(self, section, novld, ...)
	local val = self:formvalue(section)
	if not val or val == "" then
		m:error_msg(translate("Message field is empty!"))
		m.save  = false
	end
	Value.parse(self, section, novld, ...)
end


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

is_group = false
mailGroup = s:option(ListValue, "emailgroup", translate("Email account"), translate("Recipient's email configuration <br/>(<a href=\"/cgi-bin/luci/admin/system/admin/group/email\" class=\"link\">configure it here</a>)"))
--mailGroup:depends("action", "sendEmail")
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

 recEmail = s:option(Value, "recipEmail", translate("Recipient's email address"), translate("For whom you want to send an email to. Allowed characters (a-zA-Z0-9._%+@-)"))
--recEmail:depends("action", "sendEmail")
recEmail.datatype = "email"
recEmail.placeholder = "mail@domain.com"



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
