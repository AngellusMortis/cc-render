local v = require("cc.expect")

local core = require("am.core")
local b = require("am.ui.base")
local c = require("am.ui.const")
local e = require("am.ui.event")
local h = require("am.ui.helpers")

---@class am.ui.UILoop:am.ui.b.UIObject
local UILoop = b.UIObject:extend("am.ui.UILoop")
function UILoop:init(id)
    v.expect(1, id, "string", "nil")
    UILoop.super.init(self, id)

    self.running = false
    return self
end

--- Cancel currently running UILoop
function UILoop:cancel()
    if self.running then
        self.running = false
        local event = e.LoopCancelEvent(self.id)
        os.queueEvent(event.name, event)
    end
end

---Run UILoop handling events for given UI objs
---@param uiObj am.ui.b.UIObject
---@vararg am.ui.b.UIObject
function UILoop:run(uiObj, ...)
    local objs = {uiObj, ...}
    self.running = true
    while self.running do
        -- timeout timer
        local timer = os.startTimer(5)

        local event, args = core.cleanEventArgs(os.pullEvent())
        local output = nil
        if c.l.Events.Terminal[event] then
            output = term
        elseif c.l.Events.Monitor[event] then
            output = peripheral.wrap(args[1])
        elseif c.l.Events.UI[event] then
            local eventObj = args[1]
            if eventObj.outputType == "term" then
                output = term
            elseif eventObj.outputType == "monitor" then
                output = peripheral.wrap(eventObj.outputId)
            else
                for _, obj in ipairs(objs) do
                    if h.isUIScreen(obj) then
                        local frame, subOutput = obj:get(eventObj.outputId, obj.output)
                        if frame ~= nil and subOutput ~= nil then
                            output = frame:makeScreen(subOutput)
                            break
                        end
                    end
                end
            end
        end

        if event == c.e.Events.loop_cancel and args[1].id == self.id then
            self.running = false
        else
            for _, obj in ipairs(objs) do
                if output == nil then
                    if h.isUIScreen(obj) then
                        output = obj.output
                    end
                end

                if output ~= nil and obj:handle(output, {event, unpack(args)})then
                    break
                end
            end
        end
        os.cancelTimer(timer)
    end
end

return UILoop