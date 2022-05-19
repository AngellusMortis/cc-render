local v = require("cc.expect")

local b = require("am.ui.base")
local h = require("am.ui.helpers")
local c = require("am.ui.const")

local e = {}

---@class am.ui.e.BaseEvent:am.ui.b.BaseObject
---@field name string
local BaseEvent = b.BaseObject:extend("am.ui.e.BaseEvent")
e.BaseEvent = BaseEvent
---@param name string
---@return am.ui.e.BaseEvent
function BaseEvent:init(name)
    v.expect(1, name, "string")
    BaseEvent.super.init(self)

    self.name = name
    return self
end

---@class am.ui.e.LoopCancelEvent:am.ui.e.BaseEvent
---@field loopId string
local LoopCancelEvent = BaseEvent:extend("am.ui.e.LoopCancelEvent")
e.LoopCancelEvent = LoopCancelEvent
---@param loopId string
---@return am.ui.e.LoopCancelEvent
function LoopCancelEvent:init(loopId)
    v.expect(1, loopId, "string")
    LoopCancelEvent.super.init(self, c.e.Events.loop_cancel)

    self.loopId = loopId
    return self
end

---@class am.ui.e.UIEvent:am.ui.e.BaseEvent
---@field objId string
---@field name string
---@field outputType "term"|"monitor"|"frame"
---@field outputId string|nil
local UIEvent = BaseEvent:extend("am.ui.e.UIEvent")
e.UIEvent = UIEvent
---@param name string
---@param output cc.output
---@param objId string
---@return am.ui.e.UIEvent
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
        ---@cast output am.ui.FrameScreen
        self.outputType = "frame"
        self.outputId = output.frameId
    end

    return self
end

---@class am.ui.e.TextUpdateEvent:am.ui.e.UIEvent
---@field oldLabel string|string[]
---@field newLabel string|string[]
local TextUpdateEvent = UIEvent:extend("am.ui.e.TextUpdateEvent")
e.TextUpdateEvent = TextUpdateEvent
---@param output cc.output
---@param objId string
---@param oldLabel string
---@param newLabel string
---@return am.ui.e.TextUpdateEvent
function TextUpdateEvent:init(output, objId, oldLabel, newLabel)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, oldLabel, "string", "table")
    v.expect(4, newLabel, "string", "table")
    h.requireOutput(output)
    TextUpdateEvent.super.init(self, c.e.Events.text_update, output, objId)

    self.oldLabel = oldLabel
    self.newLabel = newLabel
    return self
end

---@class am.ui.e.ProgressBarLabelUpdateEvent:am.ui.e.UIEvent
---@field oldLabel string|nil
---@field newLabel string|nil
---@field oldShowProgress boolean|nil
---@field newShowProgress boolean|nil
---@field oldShowPercent boolean|nil
---@field newShowPercent boolean|nil
local ProgressBarLabelUpdateEvent = UIEvent:extend("am.ui.e.ProgressBarLabelUpdateEvent")
e.ProgressBarLabelUpdateEvent = ProgressBarLabelUpdateEvent
---@param output cc.output
---@param objId string
---@return am.ui.e.ProgressBarLabelUpdateEvent
function ProgressBarLabelUpdateEvent:init(output, objId)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    h.requireOutput(output)
    ProgressBarLabelUpdateEvent.super.init(
        self, c.e.Events.progress_label_update, output, objId
    )

    self.oldLabel = nil
    self.newLabel = nil
    self.oldShowProgress = nil
    self.newShowProgress = nil
    self.oldShowPercent = nil
    self.newShowPercent = nil
    return self
end

---@class am.ui.e.ProgressBarUpdateEvent:am.ui.e.UIEvent
---@field oldCurrent number
---@field newCurrent number
local ProgressBarUpdateEvent = UIEvent:extend("am.ui.e.ProgressBarUpdateEvent")
e.ProgressBarUpdateEvent = ProgressBarUpdateEvent
---@param output cc.output
---@param objId string
---@param oldCurrent number
---@param newCurrent number
---@return am.ui.e.ProgressBarUpdateEvent
function ProgressBarUpdateEvent:init(output, objId, oldCurrent, newCurrent)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    h.requireOutput(output)
    ProgressBarLabelUpdateEvent.super.init(
        self, c.e.Events.progress_update, output, objId
    )

    self.oldCurrent = oldCurrent
    self.newCurrent = newCurrent
    return self
end

---@class am.ui.e.ButtonActivateEvent:am.ui.e.UIEvent
---@field touch boolean
local ButtonActivateEvent = UIEvent:extend("am.ui.e.ButtonActivateEvent")
e.ButtonActivateEvent = ButtonActivateEvent
---@param output cc.output
---@param objId string
---@param touch boolean
---@return am.ui.e.ButtonActivateEvent
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
---@param output cc.output
---@param objId string
---@return am.ui.e.ButtonDeactivateEvent
function ButtonDeactivateEvent:init(output, objId)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    h.requireOutput(output)
    ButtonDeactivateEvent.super.init(self, c.e.Events.button_deactivate, output, objId)

    return self
end

---@class am.ui.e.FrameActivateEvent:am.ui.e.UIEvent
---@field x number
---@field y number
---@field clickArea number
local FrameActivateEvent = UIEvent:extend("am.ui.e.FrameActivateEvent")
e.FrameActivateEvent = FrameActivateEvent
---@param name string
---@param output cc.output
---@param objId string
---@param x number
---@param y number
---@param clickArea number ui.c.ClickArea.Screen, ui.c.ClickArea.Padding, or ui.c.ClickArea.Border
---@return am.ui.e.ButtonDeactivateEvent
function FrameActivateEvent:init(name, output, objId, x, y, clickArea)
    v.expect(1, name, "string")
    v.expect(2, output, "table")
    v.expect(3, objId, "string")
    v.expect(4, x, "number")
    v.expect(5, y, "number")
    v.expect(6, clickArea, "number")
    v.range(clickArea, 0, 2)
    h.requireOutput(output)
    FrameActivateEvent.super.init(self, name, output, objId)

    self.x = x
    self.y = y
    self.clickArea = clickArea
    return self
end

---@class am.ui.e.FrameTouchEvent:am.ui.e.FrameActivateEvent
local FrameTouchEvent = FrameActivateEvent:extend("am.ui.e.FrameTouchEvent")
e.FrameTouchEvent = FrameTouchEvent
---@param output cc.output
---@param objId string
---@param x number
---@param y number
---@param clickArea number ui.c.ClickArea.Screen, ui.c.ClickArea.Padding, or ui.c.ClickArea.Border
---@return am.ui.e.FrameTouchEvent
function FrameTouchEvent:init(output, objId, x, y, clickArea)
    v.expect(1, objId, "string")
    v.expect(2, output, "table")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    v.expect(5, clickArea, "number")
    v.range(clickArea, 0, 2)
    h.requireOutput(output)
    FrameTouchEvent.super.init(self, c.e.Events.frame_touch, output, objId, x, y, clickArea)

    return self
end

---@class am.ui.e.FrameClickEvent:am.ui.e.FrameActivateEvent
---@field clickType number
local FrameClickEvent = FrameActivateEvent:extend("am.ui.e.FrameClickEvent")
e.FrameClickEvent = FrameClickEvent
---@param output cc.output
---@param objId string
---@param x number
---@param y number
---@param clickArea number ui.c.ClickArea.Screen, ui.c.ClickArea.Padding, or ui.c.ClickArea.Border
---@return am.ui.e.FrameClickEvent
function FrameClickEvent:init(output, objId, x, y, clickArea, clickType)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    v.expect(5, clickArea, "number")
    v.expect(6, clickType, "number")
    v.range(clickArea, 0, 2)
    v.range(clickType, 1, 3)
    h.requireOutput(output)
    FrameClickEvent.super.init(self, c.e.Events.frame_click, output, objId, x, y, clickArea)

    self.clickType = clickType
    return self
end

---@class am.ui.e.FrameDeactivateEvent:am.ui.e.FrameActivateEvent
---@field clickType number
local FrameDeactivateEvent = FrameActivateEvent:extend("am.ui.e.FrameDeactivateEvent")
e.FrameDeactivateEvent = FrameDeactivateEvent
---@param output cc.output
---@param objId string
---@param x number
---@param y number
---@param clickArea number ui.c.ClickArea.Screen, ui.c.ClickArea.Padding, or ui.c.ClickArea.Border
---@param clickType number clickType from mouse_click OS event
---@return am.ui.e.FrameDeactivateEvent
function FrameDeactivateEvent:init(output, objId, x, y, clickArea, clickType)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    v.expect(5, clickArea, "number")
    v.expect(6, clickType, "number")
    v.range(clickArea, 0, 2)
    v.range(clickType, 1, 3)
    h.requireOutput(output)
    FrameDeactivateEvent.super.init(self, c.e.Events.frame_up, output, objId, x, y, clickArea)

    self.clickType = clickType
    return self
end

---@class am.ui.e.FrameScrollEvent:am.ui.e.UIEvent
---@field oldScroll number
---@field newScroll number
local FrameScrollEvent = UIEvent:extend("am.ui.e.FrameScrollEvent")
e.FrameScrollEvent = FrameScrollEvent
---@param output cc.output
---@param objId string
---@param oldScroll number
---@param newScroll number
---@return am.ui.e.FrameScrollEvent
function FrameScrollEvent:init(output, objId, oldScroll, newScroll)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, oldScroll, "number")
    v.expect(4, newScroll, "number")
    h.requireOutput(output)
    FrameScrollEvent.super.init(self, c.e.Events.frame_scroll, output, objId)

    self.oldScroll = oldScroll
    self.newScroll = newScroll
    return self
end

---@class am.ui.e.TabChangedEvent:am.ui.e.UIEvent
---@field oldIndex number
---@field newIndex number
local TabChangedEvent = UIEvent:extend("am.ui.e.TabChangedEvent")
e.TabChangedEvent = TabChangedEvent
---@param output cc.output
---@param objId string
---@param oldTabId string
---@param newTabId string
---@return am.ui.e.TabChangedEvent
function TabChangedEvent:init(output, objId, oldTabId, newTabId)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, oldTabId, "string")
    v.expect(4, newTabId, "string")
    h.requireOutput(output)
    TabChangedEvent.super.init(self, c.e.Events.tab_change, output, objId)

    self.oldTabId = oldTabId
    self.newTabId = newTabId
    return self
end

---@class am.ui.e.TabCreatedEvent:am.ui.e.UIEvent
---@field tabId string
local TabCreatedEvent = UIEvent:extend("am.ui.e.TabCreatedEvent")
e.TabCreatedEvent = TabCreatedEvent
---@param output cc.output
---@param objId string
---@param tabId string
---@return am.ui.e.TabCreatedEvent
function TabCreatedEvent:init(output, objId, tabId)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, tabId, "string")
    h.requireOutput(output)
    TabCreatedEvent.super.init(self, c.e.Events.tab_created, output, objId)

    self.tabId = tabId
    return self
end

---@class am.ui.e.TabRemovedEvent:am.ui.e.UIEvent
---@field tabId string
local TabRemovedEvent = UIEvent:extend("am.ui.e.TabRemovedEvent")
e.TabRemovedEvent = TabRemovedEvent
---@param output cc.output
---@param objId string
---@param tabId string
---@return am.ui.e.TabRemovedEvent
function TabRemovedEvent:init(output, objId, tabId)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, tabId, "string")
    h.requireOutput(output)
    TabRemovedEvent.super.init(self, c.e.Events.tab_removed, output, objId)

    self.tabId = tabId
    return self
end

---@class am.ui.e.TabLabelUpdatedEvent:am.ui.e.UIEvent
---@field oldLabel string|string[]
---@field newLabel string|string[]
local TabLabelUpdatedEvent = UIEvent:extend("am.ui.e.TabLabelUpdatedEvent")
e.TabLabelUpdatedEvent = TabLabelUpdatedEvent
---@param output cc.output
---@param objId string
---@param tabId string
---@param oldLabel string|nil
---@param newLabel string
---@return am.ui.e.TabLabelUpdatedEvent
function TabLabelUpdatedEvent:init(output, objId, tabId, oldLabel, newLabel)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(4, tabId, "string")
    v.expect(4, oldLabel, "string", "nil")
    v.expect(5, newLabel, "string", "nil")
    h.requireOutput(output)
    TabLabelUpdatedEvent.super.init(self, c.e.Events.tab_label_update, output, objId)

    self.tabId = tabId
    self.oldLabel = oldLabel
    self.newLabel = newLabel
    return self
end

return e
