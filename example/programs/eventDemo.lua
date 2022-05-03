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
s:add(
    ui.Frame(ui.a.TopLeft(), {
            width=math.floor(width / 2),
            fillVertical=true,
            fillColor=colors.lightGray,
            id="leftFrame"
        }
    )
)
local rightFrame = ui.Frame(ui.a.TopRight(), {
        width=math.floor(width / 2),
        fillVertical=true,
        id="rightFrame"
    }
)
rightFrame.borderColor = nil
rightFrame:add(ui.Text(ui.a.Top(), "Event"))
rightFrame:add(ui.Text(ui.a.Center(2), "", {id="eventText"}))
rightFrame:add(ui.Text(ui.a.Center(3), "", {id="eventArgsText"}))
local counter = ui.Button(
    ui.a.Center(8), string.format("Disabled (%d)", count), {
        fillColor=colors.blue, disabled=true, id="disabledButton"
    }
)
rightFrame:add(counter)
local button1 = ui.Button(
    ui.a.Center(5, ui.c.Offset.Left), "Add", {fillColor=colors.green, id="addButton"}
)
button1:addActivateHandler(function(button, objOutput)
    count = count + 1
    counter:updateLabel(objOutput, string.format("Disabled (%d)", count))
end)
rightFrame:add(button1)
local button2 = ui.Button(
    ui.a.Center(5, ui.c.Offset.Right), "Remove", {
        fillColor=colors.yellow, textColor=colors.black, id="removeButton"
    }
)
button2:addActivateHandler(function(button, objOutput)
    count = math.max(0, count - 1)
    counter:updateLabel(objOutput, string.format("Disabled (%d)", count))
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
local function eventLoop()
    while loop.running do
        -- timeout timer
        local timer = os.startTimer(5)

        local event = {os.pullEvent()}
        if ui.c.l.Events.UI[event[1]] then
            local eventText, eventTextOutput = s:get("eventText")
            local eventArgsText, eventArgsTextOutput = s:get("eventArgsText")
            if event[1] == ui.c.e.Events.loop_cancel then
                eventText:update(eventTextOutput, event[1])
                eventArgsText:update(eventArgsTextOutput, "")
            elseif event[1] == ui.c.e.Events.button_activate then
                eventText:update(eventTextOutput, event[1])
                eventArgsText:update(
                    eventArgsTextOutput,
                    string.format("%s: %s", event[2].objId, event[2].touch)
                )
            elseif event[1] == ui.c.e.Events.button_deactivate then
                eventText:update(eventTextOutput, event[1])
                eventArgsText:update(eventArgsTextOutput, event[2].objId)
            elseif event[1] ~= ui.c.e.Events.text_update then
                local frameEvent = event[2]
                eventText:update(eventTextOutput, event[1])
                eventArgsText:update(
                    eventArgsTextOutput,
                    string.format("%s: %d, %d", frameEvent.objId, frameEvent.x, frameEvent.y)
                )
            end
        end
        os.cancelTimer(timer)
    end
end

parallel.waitForAll(run, eventLoop)
output.clear()
output.setCursorPos(1, 1)
