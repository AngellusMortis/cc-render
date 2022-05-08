require(settings.get("ghu.base") .. "core/apis/ghu")

local output
if arg[1] ~= nil then
    if arg[1] == "term" then
        output = term
    else
        output = peripheral.wrap(arg[1])
    end
else
    output = term
end

local ui = require("am.ui")
local width, _ = output.getSize()
local count = 0
local loop = ui.UILoop()
local s = ui.Screen(output, {textColor=colors.white, backgroundColor=colors.black})
s:add(ui.ProgressBar(ui.a.TopLeft(), {
    width=math.floor(width / 2),
    progressVertical=true,
    fillColor=colors.lightGray,
    fillHorizontal=false,
    labelAnchor=ui.a.Bottom(),
    id="progress"
}))
local rightFrame = ui.Frame(ui.a.TopRight(), {
        width=math.floor(width / 2),
        fillVertical=true,
        padLeft=2,
        id="frame"
    }
)
rightFrame.borderColor = nil
rightFrame:add(ui.Text(ui.a.Top(), "Event"))
rightFrame:add(ui.Text(ui.a.Center(2), "", {id="eventText"}))
rightFrame:add(ui.Text(ui.a.Center(3), "", {id="eventArgsText"}))
local counter = ui.Button(
    ui.a.Center(8), string.format("Disabled (%d)", count), {
        fillColor=colors.blue, disabled=true, id="count", bubble=false
    }
)
rightFrame:add(counter)
local button1 = ui.Button(
    ui.a.Center(5, ui.c.Offset.Right), "+", {fillColor=colors.green, id="addButton"}
)
button1:addActivateHandler(function(button, objOutput)
    count = math.min(100, count + 1)
    counter:updateLabel(objOutput, string.format("Disabled (%d)", count))
    local progressBar = s:get("progress")
    progressBar:update(count)
end)
rightFrame:add(button1)
local button2 = ui.Button(
    ui.a.Center(5, ui.c.Offset.Left), "-", {
        fillColor=colors.yellow, textColor=colors.black, id="removeButton"
    }
)
button2:addActivateHandler(function(button, objOutput)
    count = math.max(0, count - 1)
    counter:updateLabel(objOutput, string.format("Disabled (%d)", count))
    local progressBar = s:get("progress")
    progressBar:update(count)
end)
rightFrame:add(button2)
local exitButton = ui.Button(ui.a.Bottom(), "Exit", {id="exitButton", fillColor=colors.red})
exitButton:addActivateHandler(function()
    loop:cancel()
end)
rightFrame:add(exitButton)
s:add(rightFrame)

local function run()
    s:render()
    loop:run(s)
end
local excluded_events = {
    [ui.c.e.Events.text_update] = true,
    [ui.c.e.Events.progress_update] = true
}
local function eventLoop()
    while loop.running do
        -- timeout timer
        local timer = os.startTimer(5)

        local event = {os.pullEvent()}
        if ui.c.l.Events.UI[event[1]] then
            local eventText = s:get("eventText")
            if not excluded_events[event[1]] then
                eventText:update(event[1])

                local eventArgsText = s:get("eventArgsText")
                if event[1] == ui.c.e.Events.loop_cancel then
                    eventArgsText:update("")
                elseif event[1] == ui.c.e.Events.button_activate then
                    eventArgsText:update(string.format("%s: %s", event[2].objId, event[2].touch))
                elseif event[1] == ui.c.e.Events.button_deactivate then
                    eventArgsText:update(event[2].objId)
                elseif event[1] == ui.c.e.Events.frame_scroll then
                    eventArgsText:update(
                        string.format("%s: %d", event[2].objId, event[2].newScroll)
                    )
                elseif event[1] ~= ui.c.e.Events.text_update and event[1] ~= ui.c.e.Events.progress_update then
                    local frameEvent = event[2]
                    eventArgsText:update(
                        string.format("%s: %d, %d: %d", frameEvent.objId, frameEvent.x, frameEvent.y, frameEvent.clickArea)
                    )
                end
            end
        end
        os.cancelTimer(timer)
    end
end

parallel.waitForAll(run, eventLoop)
output.clear()
output.setCursorPos(1, 1)
