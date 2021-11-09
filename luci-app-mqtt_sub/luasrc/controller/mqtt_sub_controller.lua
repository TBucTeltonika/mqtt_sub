module("luci.controller.mqtt_sub_controller", package.seeall)

function index()
  --entry( { "admin", "services", "mqtt"}, firstchild(), _("MQTT"), 150)
  --entry( { "admin", "services", "mqtt", "client" }, cbi("mqtt_sub"), _("Client"), 3).leaf = true

  entry({"admin", "services", "mqtt", "client"}, firstchild(), _("Client"), 3)
  entry({"admin", "services", "mqtt", "client", "config"}, cbi("mqtt_sub"), _("Client config"), 1).leaf = true
  entry({"admin", "services", "mqtt", "client", "log"}, cbi("mqtt_log"), _("Client log"), 2).leaf = true
end