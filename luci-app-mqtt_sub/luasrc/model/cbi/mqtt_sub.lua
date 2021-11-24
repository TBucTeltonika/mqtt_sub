m = Map("mqtt_sub", translate("MQTT client"), translate("An MQTT client is a client that sends messages to the Broker, who then forwards these messages to the Subscriber. "))
    local certs = require "luci.model.certificate"
    local s = m:section(NamedSection, "mqtt_sub", "mqtt_sub",  translate(""), translate(""))
 
    enabled_sub = s:option(Flag, "enabled", translate("Enable"), translate("Select to enable MQTT client"))

    remote_addr = s:option(Value, "remote_addr", translate("Hostname"), translate("Specify address of the broker"))
    remote_addr:depends("enabled", "1")
    remote_addr.placeholder  = "www.example.com"
    remote_addr.datatype = "host"

    function remote_addr.parse(self, section, novld, ...)
        local val = self:formvalue(section)
        if val and #val == 0 then
            self:add_error(section, "invalid", translate("Empty address field"))
            return false
        elseif val then
            Value.parse(self, section, novld, ...)
        end
    end

    remote_port = s:option(Value, "remote_port", translate("Port"), translate("Specify port of the broker"))
    remote_port:depends("enabled", "1")
    remote_port.default = "1883"
    remote_port.placeholder = "1883"
    remote_port.datatype = "port"
    remote_port.parse = function(self, section, novld, ...)
        local enabled = luci.http.formvalue("cbid.mqtt_sub.mqtt_sub.enabled")
        local value = self:formvalue(section)
        if enabled and (value == nil or value == "") then
            self:add_error(section, "invalid", "Error: port is empty")
        end
        Value.parse(self, section, novld, ...)
    end
 
    remote_username = s:option(Value, "username", translate("Username"), translate("Specify username of remote host"))
    remote_username.datatype = "credentials_validate"
    remote_username.placeholder = translate("Username")
    remote_username:depends("enabled", "1")
    remote_username.parse = function(self, section, novld, ...)
        local enabled = luci.http.formvalue("cbid.mqtt_sub.mqtt_sub.enabled")
        local pass = luci.http.formvalue("cbid.mqtt_sub.mqtt_sub.password")
        local value = self:formvalue(section)
        if enabled and pass ~= nil and pass ~= "" and (value == nil or value == "") then
            self:add_error(section, "invalid", "Error: username is empty but password is not")
        end
        Value.parse(self, section, novld, ...)
    end
 
    remote_password = s:option(Value, "password", translate("Password"), translate("Specify password of remote host. Allowed characters (a-zA-Z0-9!@#$%&*+-/=?^_`{|}~. )"))
    remote_password:depends("enabled", "1")
    remote_password.password = true
    remote_password.datatype = "credentials_validate"
    remote_password.placeholder = translate("Password")
    remote_password.parse = function(self, section, novld, ...)
        local enabled = luci.http.formvalue("cbid.mqtt_sub.mqtt_sub.enabled")
        local user = luci.http.formvalue("cbid.mqtt_sub.mqtt_sub.username")
        local value = self:formvalue(section)
        if enabled and user ~= nil and user ~= "" and (value == nil or value == "") then
            self:add_error(section, "invalid", "Error: password is empty but username is not")
        end
        Value.parse(self, section, novld, ...)
    end
 
    FileUpload.size = "262144"
    FileUpload.sizetext = translate("Selected file is too large, max 256 KiB")
    FileUpload.sizetextempty = translate("Selected file is empty")
    FileUpload.unsafeupload = true
 
    tls_enabled = s:option(Flag, "tls", translate("TLS"), translate("Select to enable TLS encryption"))
    tls_enabled:depends("enabled", "1")
 
    tls_type = s:option(ListValue, "tls_type", translate("TLS Type"), translate("Select the type of TLS encryption"))
    tls_type:depends({enabled = "1", tls = "1"})
    tls_type:value("cert", translate("Certificate based"))
 
    tls_insecure = s:option(Flag, "tls_insecure", translate("Allow insecure connection"), translate("Allow not verifying server authenticity"))
    tls_insecure:depends({enabled = "1", tls = "1", tls_type = "cert"})
 
    local certificates_link = luci.dispatcher.build_url("admin", "system", "admin", "certificates")
    o = s:option(Flag, "_device_files", translate("Certificate files from device"), translatef("Choose this option if you want to select certificate files from device.\
                                                                                        Certificate files can be generated <a class=link href=%s>%s</a>", certificates_link, translate("here")))
    o:depends({tls = "1", tls_type = "cert"})
    local cas = certs.get_ca_files().certs
    local certificates = certs.get_certificates()
    local keys = certs.get_keys()
 
    tls_cafile = s:option(FileUpload, "cafile", translate("CA file"), "")
    tls_cafile:depends({tls = "1", _device_files="", tls_type = "cert"})
 
    tls_certfile = s:option(FileUpload, "certfile", translate("Certificate file"), "")
    tls_certfile:depends({tls = "1", _device_files="", tls_type = "cert"})
 
    tls_keyfile = s:option(FileUpload, "keyfile", translate("Key file"), "")
    tls_keyfile:depends({tls = "1", _device_files="", tls_type = "cert"})
 
    tls_cafile = s:option(ListValue, "_device_cafile", translate("CA file"), "")
    tls_cafile:depends({tls = "1", _device_files="1", tls_type = "cert"})
 
    if #cas > 0 then
        for _,ca in pairs(cas) do
            tls_cafile:value("/etc/certificates/" .. ca.name, ca.name)
        end
    else         tls_cafile:value("", translate("-- No files available --"))
    end
 
    function tls_cafile.write(self, section, value)
        m.uci:set(self.config, section, "cafile", value)
    end
 
    tls_cafile.cfgvalue = function(self, section)
        return m.uci:get(m.config, section, "cafile") or ""
    end
 
    tls_certfile = s:option(ListValue, "_device_certfile", translate("Certificate file"), "")
    tls_certfile:depends({tls = "1", _device_files="1", tls_type = "cert"})
 
    if #certificates > 0 then
        for _,certificate in pairs(certificates) do
            tls_certfile:value("/etc/certificates/" .. certificate.name, certificate.name)
        end
    else         tls_certfile:value("", translate("-- No files available --"))
    end
 
    function tls_cafile.write(self, section, value)
        m.uci:set(self.config, section, "certfile", value)
    end
 
    tls_cafile.cfgvalue = function(self, section)
        return m.uci:get(m.config, section, "certfile") or ""
    end
 
    tls_keyfile = s:option(ListValue, "_device_keyfile", translate("Key file"), "")
    tls_keyfile:depends({tls = "1", _device_files="1", tls_type = "cert"})
 
    if #keys > 0 then
        for _,key in pairs(keys) do
            tls_keyfile:value("/etc/certificates/" .. key.name, key.name)
        end
    else         tls_keyfile:value("", translate("-- No files available --"))
    end
 
    function tls_keyfile.write(self, section, value)
        m.uci:set(self.config, section, "keyfile", value)
    end
 
    tls_keyfile.cfgvalue = function(self, section)
        return m.uci:get(m.config, section, "keyfile") or ""
    end
 

    sc1 = m:section(TypedSection, "topic", translate("Subscribed topics"), translate("Configuration for individual subscribed topics"))
    sc1.addremove = true
    sc1.anonymous = true
    sc1.template = "cbi/tblsection"
    sc1.delete_alert = true
    sc1.alert_message = translate("Are you sure you want to delete this topic?")

    sc1.novaluetext = translate("There are no topic subscribption rules created yet")
    sc1.template_addremove = "cbi/add_rule"

    tpc_col = sc1:option(Value, "topic", translate("Topic"), translate("This section contains names of hosts that will be added to the Blacklist or Whitelist. Click the 'Add' button to add more hosts."))
    tpc_col.datatype = "lengthvalidation(1, 128)"
    tpc_col.placeholder = "status"
    tpc_col.parse = function(self, section, novld, ...)
        local value = self:formvalue(section)
        if (value == nil or value == "") then
            self:add_error(section, "invalid", "Error: Topic is empty")
        end
        Value.parse(self, section, novld, ...)
    end

    qos_col = sc1:option(ListValue, "qos", translate("QoS"), translate("Please select QoS level."))
    qos_col:value("0", translate("QoS 0 - at most once"))
    qos_col:value("1", translate("QoS 1 - at least once"))
    qos_col:value("2", translate("QoS 2 - exactly once"))
    

    enb_col = sc1:option(Flag, "enabled", translate(""))
    enb_col.rmempty = false
    enb_col.default = "1"
    enb_col.last = true

 
    return m
 

