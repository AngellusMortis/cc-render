local c = {}
---@type table<string, number>
c.Click = {
    Left=1,
    Right=2,
    Middle=3
}
---@type table<string, number>
c.Offset = {
    Left=1,
    Right=2
}

c.e = {}
---@type table<string, string>
c.e.Events = {
    loop_cancel = "ui.loop_cancel",
    frame_touch = "ui.frame_touch",
    frame_click = "ui.frame_click",
    frame_up = "ui.frame_up",
    text_update = "ui.text_update",
    button_activate = "ui.button_activate",
    button_deactivate = "ui.button_deactivate"
}

c.l = {}
c.l.Events = {}
---@type table<string, boolean>
c.l.Events.Terminal = {
    char=true,
    key=true,
    key_up=true,
    mouse_click=true,
    mouse_drag=true,
    mouse_scroll=true,
    mouse_up=true,
    paste=true
}
---@type table<string, boolean>
c.l.Events.Monitor = {
    monitor_resize=true,
    monitor_touch=true
}
---@type table<string, boolean>
c.l.Events.UI = {
    ["ui.frame_touch"]=true,
    ["ui.frame_click"]=true,
    ["ui.frame_up"]=true,
    ["ui.text_update"]=true,
    ["ui.button_activate"]=true,
    ["ui.button_deactivate"]=true,
}

return c
