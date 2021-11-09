local function tableSort(a, b)
    return a.date > b.date
end


local m, s, o
m = SimpleForm("system")
m.submit = false
m.reset = false

--messages = get_events()

local s = m:section(Table, messages, translate("EVENTS LOG"), translate("The Events Log section contains a chronological list of various events related to the device."))
s.anonymous = true
s.template = "status/tblsection_clientlog"
--This breaks it for some reason but it has all the fancy stuff. I think i will make my own version of it or something.
s.addremove = false
s.refresh = true
s.table_config = {
    truncatePager = true,
    labels = {
        placeholder = "Search...",
        perPage = "Events per page {select}",
        noRows = "No entries found",
        info = ""
    },
    layout = {
        top = "<table><tr style='padding: 0 !important; border:none !important'><td style='display: flex !important; flex-direction: row'>{select}<span style='margin-left: auto; width:100px'>{search}</span></td></tr></table>",
        bottom = "{info}{pager}"
    }
}

o = s:option(DummyValue, "date", translate("Date"))
o = s:option(DummyValue, "sender", translate("Topic"))
o = s:option(DummyValue, "event", translate("Payload"))


s:option(DummyValue, "", translate(""))



return m







