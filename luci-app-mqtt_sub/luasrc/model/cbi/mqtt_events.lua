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

s = m:section(TypedSection, "rule", translate("Events Reporting Rules for MQTT client."), translate("This section displays Events Reporting rules that are currently configured on the router. Events Reporting rules inform you via SMS when certain specified events occur on the router. Click the 'Add' button to create a new rule and begin configuring it."))
s.template  = "cbi/tblsection"
s.addremove = true
s.anonymous = true
s.sortable  = true
s.extedit   = ds.build_url("admin/services/mqtt/client/events/%s")
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
		luci.http.redirect(ds.build_url("admin/services/mqtt/client/events", created))
	else
		m.uci:save(self.config)
		m.uci.commit(self.config)
	end
end

src = s:option(DummyValue, "topic", translate("Topic"), translate("Event type for which the rule is applied"))
src.rawhtml = true
src.width = "16%"
function src.cfgvalue(self, s)
	local z = self.map:get(s, "topic")
	if z then
		return z
	else
	    return translatef("NA")
	end
end

src  = s:option(DummyValue, "key", translate("Key"), translate("Relevant key"))
src.rawhtml = true
src.width = "16%"
function src.cfgvalue(self, s)
	local z = self.map:get(s, "key")
	if z then
		return z
	else
	    return translatef("NA")
	end
end

src = s:option(DummyValue, "compType", translate("Comp. Type"), translate("Comparison type."))
src.rawhtml = true
src.width = "16%"
function src.cfgvalue(self, s)
	local z = self.map:get(s, "compType")
	if z == "equal" then
		return translatef("==")
	elseif z == "notequal" then
		return translatef("=/=")
	elseif z == "lessthan" then
		return translatef("<")
	elseif z == "morethan" then
		return translatef(">")
	elseif z == "lessorequalthan" then
		return translatef("<=")
	elseif z == "moreorequalthan" then
		return translatef(">=")
	else
	    return translatef("NA")
	end
end

src = s:option(DummyValue, "value", translate("Value"), translate("Comp. Value"))
src.rawhtml = true
src.width = "16%"
function src.cfgvalue(self, s)
	local z = self.map:get(s, "value")
	local t = self.map:get(s, "type")
	local x = self.map:get(s, "valueint")
	if t == "String" and z then
		return z
	elseif t == "Integer" and x then
		return x
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
