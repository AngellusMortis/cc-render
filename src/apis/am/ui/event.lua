local v = require("cc.expect")

local b = require("am.ui.base")
local h = require("am.ui.helpers")
local c = require("am.ui.const")

local e = {}

---@class am.ui.e.BaseEvent:am.ui.b.BaseObject
local BaseEvent = b.BaseObject:extend("am.ui.e.BaseEvent")
e.BaseEvent = BaseEvent
function BaseEvent:init(name)
    v.expect(1, name, "string")
    BaseEvent.super.init(self)

    self.name = name
    return self
end

---@class am.ui.e.LoopCancelEvent:am.ui.e.BaseEvent
local LoopCancelEvent = BaseEvent:extend("am.ui.e.LoopCancelEvent")
e.LoopCancelEvent = LoopCancelEvent
function LoopCancelEvent:init(loopId)
    v.expect(1, loopId, "string")
    LoopCancelEvent.super.init(self, c.e.Events.loop_cancel)

    self.loopId = loopId
    return self
end

---@class am.ui.e.UIEvent:am.ui.e.BaseEvent
local UIEvent = BaseEvent:extend("am.ui.e.UIEvent")
e.UIEvent = UIEvent
function UIEvent:init(name, output, objId)
    v.expect(1, name, "string")
    v.expect(2, output, "table")
    v.expect(3, objId, "string")
    h.requireOutput(output)
    UIEvent.super.init(self, name)

    self.objId = objId
    if h.isTerm(output) then
        self.outputType = "term"
        self.outputId = nil
    elseif h.isMonitor(output) then
        self.outputType = "monitor"
        self.outputId = peripheral.getName(output)
    else
        output = h.getFrameScreen(output)
        self.outputType = "frame"
        self.outputId = output.frameId
    end

    return self
end

---@class am.ui.e.TextUpdateEvent:am.ui.e.UIEvent
local TextUpdateEvent = UIEvent:extend("am.ui.e.TextUpdateEvent")
e.TextUpdateEvent = TextUpdateEvent
function TextUpdateEvent:init(output, objId, oldLabel, newLabel)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, oldLabel, "string")
    v.expect(4, newLabel, "string")
    h.requireOutput(output)
    TextUpdateEvent.super.init(self, c.e.Events.text_update, output, objId)

    self.oldLabel = oldLabel
    self.newLabel = newLabel
    return self
end

---@class am.ui.e.ButtonActivateEvent:am.ui.e.UIEvent
local ButtonActivateEvent = UIEvent:extend("am.ui.e.ButtonActivateEvent")
e.ButtonActivateEvent = ButtonActivateEvent
function ButtonActivateEvent:init(output, objId, touch)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, touch, "boolean", "nil")
    h.requireOutput(output)
    if touch == nil then
        touch = false
    end
    ButtonActivateEvent.super.init(self, c.e.Events.button_activate, output, objId)

    self.touch = touch
    return self
end

---@class am.ui.e.ButtonDeactivateEvent:am.ui.e.UIEvent
local ButtonDeactivateEvent = UIEvent:extend("am.ui.ButtonDeactivateEvent")
e.ButtonDeactivateEvent = ButtonDeactivateEvent
function ButtonDeactivateEvent:init(output, objId)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    h.requireOutput(output)
    ButtonDeactivateEvent.super.init(self, c.e.Events.button_deactivate, output, objId)

    return self
end

---@class am.ui.e.FrameActivateEvent:am.ui.e.UIEvent
local FrameActivateEvent = UIEvent:extend("am.ui.e.FrameActivateEvent")
e.FrameActivateEvent = FrameActivateEvent
function FrameActivateEvent:init(name, output, objId, x, y)
    v.expect(1, name, "string")
    v.expect(2, output, "table")
    v.expect(3, objId, "string")
    v.expect(4, x, "number")
    v.expect(5, y, "number")
    h.requireOutput(output)
    FrameActivateEvent.super.init(self, name, output, objId)

    self.x = x
    self.y = y
    return self
end

---@class am.ui.e.FrameTouchEvent:am.ui.e.FrameActivateEvent
local FrameTouchEvent = FrameActivateEvent:extend("am.ui.e.FrameTouchEvent")
e.FrameTouchEvent = FrameTouchEvent
function FrameTouchEvent:init(output, objId, x, y)
    v.expect(1, objId, "string")
    v.expect(2, output, "table")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    h.requireOutput(output)
    FrameTouchEvent.super.init(self, c.e.Events.frame_touch, output, objId, x, y)

    return self
end

---@class am.ui.e.FrameClickEvent:am.ui.e.FrameActivateEvent
local FrameClickEvent = FrameActivateEvent:extend("am.ui.e.FrameClickEvent")
e.FrameClickEvent = FrameClickEvent
function FrameClickEvent:init(output, objId, x, y, clickType)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    v.expect(5, clickType, "number")
    v.range(clickType, 1, 3)
    h.requireOutput(output)
    FrameClickEvent.super.init(self, c.e.Events.frame_click, output, objId, x, y)

    self.clickType = clickType
    return self
end

---@class am.ui.e.FrameDeactivateEvent:am.ui.e.FrameActivateEvent
local FrameDeactivateEvent = FrameActivateEvent:extend("am.ui.e.FrameDeactivateEvent")
e.FrameDeactivateEvent = FrameDeactivateEvent
function FrameDeactivateEvent:init(output, objId, x, y, clickType)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    v.expect(5, clickType, "number")
    v.range(clickType, 1, 3)
    h.requireOutput(output)
    FrameDeactivateEvent.super.init(self, c.e.Events.frame_up, output, objId, x, y)

    self.clickType = clickType
    return self
end

return e
