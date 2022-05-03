local v = require("cc.expect")
local pp = require("cc.pretty")

local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")
local core = require("am.core")
local textLib = require("am.text")
local object = require("ext.object")

local ui = {}
ui.c = {}

ui.c.Events = {}
ui.c.Events = {
    loop_cancel = "ui.loop_cancel",
    frame_touch = "ui.frame_touch",
    frame_click = "ui.frame_click",
    frame_up = "ui.frame_up",
    text_update = "ui.text_update",
    button_activate = "ui.button_activate",
    button_deactivate = "ui.button_deactivate"
}

ui.l = {}
ui.l.Events = {}

ui.l.Events.Terminal = {
    char=true,
    key=true,
    key_up=true,
    mouse_click=true,
    mouse_drag=true,
    mouse_scroll=true,
    mouse_up=true,
    paste=true
}
ui.l.Events.Monitor = {
    monitor_resize=true,
    monitor_touch=true
}
ui.l.Events.UI = {
    ["ui.frame_touch"]=true,
    ["ui.frame_click"]=true,
    ["ui.frame_up"]=true,
    ["ui.text_update"]=true,
    ["ui.button_activate"]=true,
    ["ui.button_deactivate"]=true,
}


---------------------------------------
-- Detect if output is terminal
---------------------------------------
function ui.isTerm(output)
    v.expect(1, output, "table")

    return output.redirect ~= nil and output.current ~= nil
end

---------------------------------------
-- Detect if output is a monitor
---------------------------------------
function ui.isMonitor(output)
    v.expect(1, output, "table")

    mt = getmetatable(output)
    if mt == nil then
        return false
    end
    return mt.__name == "peripheral" and mt.type == "monitor"
end

---------------------------------------
-- Get actual FrameScreen object
---------------------------------------
function ui.getFrameScreen(output)
    v.expect(1, output, "table")

    if output._frameScreenRef ~= nil and type(output._frameScreenRef) == "table" then
        output = output._frameScreenRef
    end

    return output
end

---------------------------------------
-- Detect if output is a frame
---------------------------------------
function ui.isFrameScreen(output)
    v.expect(1, output, "table")

    output = ui.getFrameScreen(output)
    return object.has(output, "ui.FrameScreen")
end

---------------------------------------
-- Detect if two outputs are the same
---------------------------------------
function ui.isSameScreen(output1, output2)
    v.expect(1, output1, "table")
    v.expect(2, output2, "table")

    local sameScreen = false
    if ui.isTerm(output1) and ui.isTerm(output2) then
        sameScreen = true
    elseif ui.isMonitor(output1) and ui.isMonitor(output2) then
        sameScreen = peripheral.getName(output1) == peripheral.getName(output2)
    elseif ui.isFrameScreen(output1) and ui.isFrameScreen(output2) then
        output1 = ui.getFrameScreen(output1)
        output2 = ui.getFrameScreen(output2)
        sameScreen = output1.id == output2.id
    end

    return sameScreen
end

---------------------------------------
-- Detect if output is an output
---------------------------------------
function ui.isOutput(output)
    return ui.isTerm(output) or ui.isMonitor(output) or ui.isFrameScreen(output)
end

function ui.requireOutput(output)
    if not ui.isOutput(output) then
        error("Not a terminal, monitor or frame")
    end
end

local AUTO_ID = 1
local IDS = {}

local function getColor(color, default, secondDefault)
    v.expect(1, color, "number", "nil")
    v.expect(2, default, "number", "nil")
    v.expect(3, secondDefault, "number", "nil")

    if color ~= nil then
        return color
    elseif default ~= nil then
        return default
    elseif secondDefault ~= nil then
        return secondDefault
    end

    error("Could not determine color")
end

---------------------------------------
-- Detect if obj is a UI object
---------------------------------------
function ui.isUI(obj)
    if type(obj) ~= "table" then
        return false
    end
    return object.has(obj, "ui.UIObject")
end

local BaseObject = object:extend("BaseObject")
function BaseObject:init()
    BaseObject.super.init(self, {})
    getmetatable(self).__tostring = nil

    return self
end

local UIObject = BaseObject:extend("ui.UIObject")
ui.UIObject = UIObject

function UIObject:init(opt)
    opt = opt or {}
    UIObject.super.init(self)
    v.field(opt, "id", "string", "nil")
    if opt.id == nil then
        opt.id = "ui" .. tostring(AUTO_ID)
        AUTO_ID = AUTO_ID + 1
    end

    if IDS[opt.id] then
        error(opt.id .. " already exists")
    end
    IDS[opt.id] = true

    self.id = opt.id
    self.visible = true
    return self
end

function UIObject:validate(object)
end

function UIObject:render(output)
    v.expect(1, output, "table", "nil")
    if output == nil then
        output = term
    end
    ui.requireOutput(output)
    self:validate(output)
end

function UIObject:handle(output, event, ...)
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.requireOutput(output)

    if event == "term_resize" or event == "monitor_resize" then
        self:render(output)
    end

    return false
end

local UILoop = UIObject:extend("ui.UILoop")
ui.UILoop = UILoop
function UILoop:init(id)
    v.expect(1, id, "string", "nil")
    UILoop.super.init(self, id)

    self.running = false
    return self
end

local BaseEvent = BaseObject:extend("ui.BaseEvent")
ui.BaseEvent = BaseEvent
function BaseEvent:init(name)
    v.expect(1, name, "string")
    BaseEvent.super.init(self)

    self.name = name
    return self
end

local LoopCancelEvent = BaseEvent:extend("ui.LoopCancelEvent")
ui.LoopCancelEvent = LoopCancelEvent
function LoopCancelEvent:init(loopId)
    v.expect(1, loopId, "string")
    LoopCancelEvent.super.init(self, ui.c.Events.loop_cancel)

    self.loopId = loopId
    return self
end

function UILoop:cancel()
    if self.running then
        self.running = false
        event = LoopCancelEvent(self.id)
        os.queueEvent(event.name, event)
    end
end

function UILoop:run(uiObj, ...)
    local objs = {uiObj, ...}
    self.running = true
    while self.running do
        -- timeout timer
        local timer = os.startTimer(5)

        local event, args = core.cleanEventArgs(os.pullEvent())
        local output = nil
        if ui.l.Events.Terminal[event] then
            output = term
        elseif ui.l.Events.Monitor[event] then
            output = peripheral.wrap(args[1])
        elseif ui.l.Events.UI[event] then
            local eventObj = args[1]
            if eventObj.outputType == "term" then
                output = term
            elseif eventObj.outputType == "monitor" then
                output = peripheral.wrap(eventObj.outputId)
            else
                for _, obj in ipairs(objs) do
                    if obj:is("ui.Screen") then
                        frame, output = obj:get(eventObj.outputId, obj.output)
                        if frame ~= nil and output ~= nil then
                            output = frame:makeScreen(output)
                            break
                        end
                    end
                end
            end
        end

        if event == ui.c.Events.loop_cancel and args[1].id == self.id then
            self.running = false
        else
            for _, obj in ipairs(objs) do
                if output == nil then
                    if obj:is("ui.Screen") then
                        output = obj.output
                    end
                end

                if output ~= nil and obj:handle(output, {event, table.unpack(args)})then
                    break
                end
            end
        end
        os.cancelTimer(timer)
    end
end

local UIEvent = BaseEvent:extend("ui.UIEvent")
ui.UIEvent = UIEvent
function UIEvent:init(name, output, objId)
    v.expect(1, name, "string")
    v.expect(2, output, "table")
    v.expect(3, objId, "string")
    ui.requireOutput(output)
    UIEvent.super.init(self, name)

    self.objId = objId
    if ui.isTerm(output) then
        self.outputType = "term"
        self.outputId = nil
    elseif ui.isMonitor(output) then
        self.outputType = "monitor"
        self.outputId = peripheral.getName(output)
    else
        output = ui.getFrameScreen(output)
        self.outputType = "frame"
        self.outputId = output.frameId
    end

    return self
end

local TextUpdateEvent = UIEvent:extend("ui.TextUpdateEvent")
ui.TextUpdateEvent = TextUpdateEvent
function TextUpdateEvent:init(output, objId, oldLabel, newLabel)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, oldLabel, "string")
    v.expect(4, newLabel, "string")
    ui.requireOutput(output)
    TextUpdateEvent.super.init(self, ui.c.Events.text_update, output, objId)

    self.oldLabel = oldLabel
    self.newLabel = newLabel
    return self
end

local ButtonActivateEvent = UIEvent:extend("ui.ButtonActivateEvent")
ui.ButtonActivateEvent = ButtonActivateEvent
function ButtonActivateEvent:init(output, objId, touch)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, touch, "boolean", "nil")
    ui.requireOutput(output)
    if touch == nil then
        touch = false
    end
    ButtonActivateEvent.super.init(self, ui.c.Events.button_activate, output, objId)

    self.touch = touch
    return self
end

local ButtonDeactivateEvent = UIEvent:extend("ui.ButtonDeactivateEvent")
ui.ButtonDeactivateEvent = ButtonDeactivateEvent
function ButtonDeactivateEvent:init(output, objId)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    ui.requireOutput(output)
    ButtonDeactivateEvent.super.init(self, ui.c.Events.button_deactivate, output, objId)

    return self
end

ui.c.Click = {}
ui.c.Click.Left = 1
ui.c.Click.Right = 2
ui.c.Click.Middle = 3

local FrameActivateEvent = UIEvent:extend("ui.FrameActivateEvent")
ui.FrameActivateEvent = FrameActivateEvent
function FrameActivateEvent:init(name, output, objId, x, y)
    v.expect(1, name, "string")
    v.expect(2, output, "table")
    v.expect(3, objId, "string")
    v.expect(4, x, "number")
    v.expect(5, y, "number")
    ui.requireOutput(output)
    FrameActivateEvent.super.init(self, name, output, objId)

    self.x = x
    self.y = y
    return self
end

local FrameTouchEvent = FrameActivateEvent:extend("ui.FrameTouchEvent")
ui.FrameTouchEvent = FrameTouchEvent
function FrameTouchEvent:init(output, objId, x, y)
    v.expect(1, objId, "string")
    v.expect(2, output, "table")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    ui.requireOutput(output)
    FrameTouchEvent.super.init(self, ui.c.Events.frame_touch, output, objId, x, y)

    return self
end

local FrameClickEvent = FrameActivateEvent:extend("ui.FrameClickEvent")
ui.FrameClickEvent = FrameClickEvent
function FrameClickEvent:init(output, objId, x, y, clickType)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    v.expect(5, clickType, "number")
    v.range(clickType, 1, 3)
    ui.requireOutput(output)
    FrameClickEvent.super.init(self, ui.c.Events.frame_click, output, objId, x, y)

    self.clickType = clickType
    return self
end

local FrameDeactivateEvent = FrameActivateEvent:extend("ui.FrameDeactivateEvent")
ui.FrameDeactivateEvent = FrameDeactivateEvent
function FrameDeactivateEvent:init(output, objId, x, y, clickType)
    v.expect(1, output, "table")
    v.expect(2, objId, "string")
    v.expect(3, x, "number")
    v.expect(4, y, "number")
    v.expect(5, clickType, "number")
    v.range(clickType, 1, 3)
    ui.requireOutput(output)
    FrameDeactivateEvent.super.init(self, ui.c.Events.frame_up, output, objId, x, y)

    self.clickType = clickType
    return self
end

local Group = UIObject:extend("ui.Group")
ui.Group = Group
function Group:init(opt)
    opt = opt or {}
    v.field(opt, "id", "string", "nil")
    Group.super.init(self, opt)

    self.i = {}
    return self
end

function Group:add(obj)
    v.expect(1, obj, "table")
    if not ui.isUI(obj) then
        error("Not a valid UI obj")
    elseif obj:has("ui.Screen") then
        error("Cannot nest Screen UIs")
    end

    self.i[obj.id] = obj
end

function Group:get(id, output)
    v.expect(1, id, "string")
    v.expect(2, output, "table", "nil")
    if output ~= nil then
        ui.requireOutput(output)
    end

    if self.i[id] ~= nil then
        return self.i[id], output
    end

    for _, obj in pairs(self.i) do
        if obj:has(Group) then
            local subObj, output = obj:get(id, output)
            if subObj ~= nil then
                return subObj, output
            end
        end
    end
end

function Group:remove(id)
    v.expect(1, id, "string")

    if self.i[id] ~= nil then
        self.i:remove(obj.id)
        return true
    end

    for _, obj in pairs(self.i) do
        if obj:is(Group) then
            local removed = obj:remove(id)
            if removed then
                return true
            end
        end
    end

    return false
end

function Group:reset()
    self.i = {}
end

function Group:render(output)
    if not self.visible then
        return
    end

    local oldTextColor = output.getTextColor()
    local oldBackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()

    v.expect(1, output, "table", "nil")
    if output == nil then
        output = term
    end
    UIObject.render(self, output)

    for _, obj in pairs(self.i) do
        obj:render(output)
    end

    output.setTextColor(oldTextColor)
    output.setBackgroundColor(oldBackgroundColor)
    output.setCursorPos(oldX, oldY)
end

function Group:handle(output, event, ...)
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.requireOutput(output)

    -- only do one render call for whole group
    if event == "term_resize" or event == "monitor_resize" then
        self:render(output)
        return false
    end

    for _, obj in pairs(self.i) do
        if obj:handle(output, {event, table.unpack(args)}) then
            return true
        end
    end
    return false
end

local Screen = Group:extend("ui.Screen")
ui.Screen = Screen
function Screen:init(output, opt)
    opt = opt or {}
    v.expect(1, output, "table", "nil")
    v.field(opt, "id", "string", "nil")
    v.field(opt, "textColor", "number", "nil")
    v.field(opt, "backgroundColor", "number", "nil")
    if output == nil then
        output = term
    end
    ui.requireOutput(output)
    if opt.textColor ~= nil then
        v.range(opt.textColor, 1)
    end
    if opt.backgroundColor ~= nil then
        v.range(opt.backgroundColor, 1)
    end
    Screen.super.init(self, opt)

    self.output = output
    self.textColor = opt.textColor
    self.backgroundColor = opt.backgroundColor
    return self
end

function Screen:get(id)
    v.expect(1, id, "string")
    return Screen.super.get(self, id, self.output)
end

function Screen:render()
    if not self.visible then
        return
    end

    local _, height = self.output.getSize()
    local textColor = getColor(self.textColor, self.output.getTextColor())
    local backgroundColor = getColor(self.backgroundColor, self.output.getBackgroundColor())

    self.output.setTextColor(textColor)
    self.output.setBackgroundColor(backgroundColor)
    self.output.clear()
    self.output.setCursorPos(1, 1)
    self.output.setCursorBlink(false)
    Screen.super.render(self, self.output)
    self.output.setCursorPos(1, height)
    self.output.setTextColor(textColor)
    self.output.setBackgroundColor(backgroundColor)
end

function Screen:handle(output, event, ...)
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.requireOutput(output)

    if not ui.l.Events.UI[event] and not ui.isSameScreen(self.output, output) then
        return false
    end

    if ui.l.Events.UI[event] then
        local obj, objOutput = self:get(args[1].objId, self.output)
        if obj ~= nil and objOutput ~= nil then
            if not obj:handle(objOutput, {event, table.unpack(args)}) then
                return true
            end
        end
        return false
    end

    -- only do one render call for whole group
    if event == "term_resize" or event == "monitor_resize" then
        self:render(output)
        return false
    end
    for _, obj in pairs(self.i) do
        if obj:handle(output, {event, table.unpack(args)}) then
            return true
        end
    end

    return true
end


local ScreenPos = BaseObject:extend("ui.a.ScreenPos")
ui.ScreenPos = ScreenPos
function ScreenPos:init(x, y)
    ScreenPos.super.init(self)
    v.expect(1, x, "number")
    v.expect(2, y, "number")
    v.range(x, 1)
    v.range(y, 1)

    self.x = x
    self.y = y
    return self
end


ui.a = {}
local Anchor = BaseObject:extend("ui.a.Anchor")
ui.a.Anchor = Anchor
function Anchor:init(x, y)
    Anchor.super.init(self)
    v.expect(1, x, "number")
    v.expect(2, y, "number")
    v.range(x, 1)
    v.range(y, 1)

    self.x = x
    self.y = y
    return self
end

function Anchor:getXPos(output, width)
    return self.x
end

function Anchor:getYPos(output, height)
    return self.y
end

function Anchor:getPos(output, width, height)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    v.expect(3, height, "number")
    ui.requireOutput(output)

    local x = self:getXPos(output, width)
    local y = self:getYPos(output, height)
    return ScreenPos(x, y)
end


local Left = Anchor:extend("ui.a.Left")
ui.a.Left = Left
function Left:init(y)
    v.expect(1, y, "number")
    v.range(y, 1)
    Left.super.init(self, 1, y)
    return self
end


local Right = Anchor:extend("ui.a.Right")
ui.a.Right = Right
function Right:init(y)
    v.expect(1, y, "number")
    v.range(y, 1)
    Right.super.init(self, 1, y)
    return self
end

function Right:getXPos(output, width)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    ui.requireOutput(output)

    local oWidth, _ = output.getSize()
    return math.max(1, oWidth - width + 1)
end

ui.c.Offset = {}
ui.c.Offset.Left = 1
ui.c.Offset.Right = 2

local Center = Anchor:extend("ui.a.Center")
ui.a.Center = Center
function Center:init(y, offset, offsetAmount)
    v.expect(1, y, "number")
    v.expect(2, offset, "number", "nil")
    v.expect(3, offsetAmount, "number", "nil")
    v.range(y, 1)
    if offset ~= nil then
        v.range(offset, 1, 2)
    end
    if offsetAmount == nil then
        offsetAmount = 1
    end
    v.range(offsetAmount, 1)
    Center.super.init(self, 1, y)
    self.offset = offset
    self.offsetAmount = offsetAmount
    return self
end

function Center:getXPos(output, width)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    ui.requireOutput(output)

    local oWidth, _ = output.getSize()
    local center = oWidth / 2
    if self.offset == nil then
        center = center - width / 2
    elseif self.offset == ui.c.Offset.Left then
        center = center - width - self.offsetAmount
    elseif self.offset == ui.c.Offset.Right then
        center = center + self.offsetAmount + 1
    end
    return math.max(1, math.floor(center) + 1)
end

local Middle = Center:extend("ui.a.Middle")
ui.a.Middle = Middle
function Middle:init()
    Middle.super.init(self, 1)
    return self
end

function Middle:getYPos(output, height)
    v.expect(1, output, "table")
    v.expect(2, height, "number")
    ui.requireOutput(output)

    local _, oHeight = output.getSize()
    return math.floor((oHeight + 1) / 2 - height / 2) + 1
end


local Top = Center:extend("ui.a.Top")
ui.a.Top = Top
function Top:init(offset, offsetAmount)
    v.expect(1, offset, "number", "nil")
    v.expect(2, offsetAmount, "number", "nil")
    if offset ~= nil then
        v.range(offset, 1, 2)
    end
    Top.super.init(self, 1, offset, offsetAmount)
    return self
end


local Bottom = Center:extend("ui.a.Bottom")
ui.a.Bottom = Bottom
function Bottom:init(offset, offsetAmount)
    v.expect(1, offset, "number", "nil")
    v.expect(2, offsetAmount, "number", "nil")
    if offset ~= nil then
        v.range(offset, 1, 2)
    end
    Bottom.super.init(self, 1, offset, offsetAmount)
    return self
end

function Bottom:getYPos(output, height)
    v.expect(1, output, "table")
    v.expect(2, height, "number")
    ui.requireOutput(output)

    local _, oHeight = output.getSize()
    return oHeight - height + 1
end


local TopLeft = Anchor:extend("ui.a.TopLeft")
ui.a.TopLeft = TopLeft
function TopLeft:init()
    TopLeft.super.init(self, 1, 1)
    return self
end


local TopRight = Right:extend("ui.a.TopRight")
ui.a.TopRight = TopRight
function TopRight:init()
    TopRight.super.init(self, 1, 1)
    return self
end


local BottomLeft = Anchor:extend("ui.a.BottomLeft")
ui.a.BottomLeft = BottomLeft
function BottomLeft:init()
    BottomLeft.super.init(self, 1, 1)
    return self
end

function BottomLeft:getYPos(output, height)
    v.expect(1, output, "table")
    v.expect(2, height, "number")
    ui.requireOutput(output)

    local _, oHeight = output.getSize()
    return oHeight - height + 1
end


local BottomRight = BottomLeft:extend("ui.a.BottomRight")
ui.a.BottomRight = BottomRight
function BottomRight:init()
    BottomRight.super.init(self)
    return self
end

function BottomRight:getXPos(output, width)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    ui.requireOutput(output)

    local oWidth, _ = output.getSize()
    return oWidth - width
end


local Text = UIObject:extend("ui.Text")
ui.Text = Text
function Text:init(anchor, label, opt)
    opt = opt or {}
    v.expect(1, anchor, "table")
    v.expect(2, label, "string")
    v.field(opt, "id", "string", "nil")
    v.field(opt, "textColor", "number", "nil")
    v.field(opt, "backgroundColor", "number", "nil")
    if opt.textColor ~= nil then
        v.range(opt.textColor, 1)
    end
    if opt.backgroundColor ~= nil then
        v.range(opt.backgroundColor, 1)
    end
    Text.super.init(self, opt)

    self.label = label
    self.anchor = anchor
    self.textColor = opt.textColor
    self.backgroundColor = opt.backgroundColor
    self:validate()
    return self
end

function Text:validate(output)
    Text.super.validate(self, output)

    v.field(self, "label", "string")
    v.field(self, "anchor", "table")
    v.field(self, "textColor", "number", "nil")
    v.field(self, "backgroundColor", "number", "nil")
    if not object.has(self.anchor, Anchor) then
        error("anchor much be of type Anchor")
    end
end

function Text:handle(output, event, ...)
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.requireOutput(output)

    if event == ui.c.Events.text_update and args[1].objId == self.id then
        local oldLabel = args[1].oldLabel
        local newLabel = args[1].newLabel
        if #newLabel < #oldLabel then
            self.label = string.rep(" ", #oldLabel)
            self:render(output)
        end
        self.label = args[1].newLabel
        self:render(output)
        return true
    end
    return false
end

function Text:render(output)
    if not self.visible then
        return
    end

    v.expect(1, output, "table", "nil")
    if output == nil then
        output = term
    end
    Text.super.render(self, output)

    local oldTextColor = output.getTextColor()
    local oldbackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()

    local msg, color = textLib.getTextColor(self.label)
    local pos = self.anchor:getPos(output, #msg, 1)
    local textColor = getColor(self.textColor, color, output.getTextColor())
    local backgroundColor = getColor(self.backgroundColor, output.getBackgroundColor())

    output.setTextColor(textColor)
    output.setBackgroundColor(backgroundColor)
    output.setCursorPos(pos.x, pos.y)
    output.write(msg)

    output.setTextColor(oldTextColor)
    output.setBackgroundColor(oldbackgroundColor)
    output.setCursorPos(oldX, oldY)
end

function Text:update(output, label)
    v.expect(1, output, "table")
    v.expect(2, label, "string")
    ui.requireOutput(output)

    if self.label ~= label then
        local event = TextUpdateEvent(output, self.id, self.label, label)
        self.label = label
        os.queueEvent(event.name, event)
    end
end


local FrameScreen = BaseObject:extend("ui.FrameScreen")
ui.a.FrameScreen = FrameScreen
function FrameScreen:init(output, frameId, basePos, width, height, textColor, backgroundColor)
    FrameScreen.super.init(self)
    v.expect(1, output, "table")
    v.expect(2, frameId, "string")
    v.expect(3, basePos, "table")
    v.expect(4, width, "number")
    v.expect(5, height, "number")
    v.expect(6, textColor, "number", "nil")
    v.expect(7, backgroundColor, "number", "nil")
    ui.requireOutput(output)
    if not object.is(basePos, ScreenPos) then
        error("basePos must be a ScreenPos")
    end
    v.range(width, 1)
    v.range(height, 1)
    if textColor ~= nil then
        v.range(textColor, 1)
    end
    if backgroundColor ~= nil then
        v.range(backgroundColor, 1)
    end

    self.output = output
    self.frameId = frameId
    self.basePos = basePos
    self.pos = ScreenPos(1, 1)
    self.width = width
    self.height = height
    self.textColor = textColor
    self.backgroundColor = backgroundColor
    return self
end

function FrameScreen:ccCompat()
    local screen = {}
    screen._frameScreenRef = self
    screen.write = function(text)
        return self:write(text)
    end
    screen.clear = function()
        return self:clear()
    end
    screen.clearLine = function()
        return self:clearLine()
    end
    screen.getBackgroundColor = function()
        return self:getBackgroundColor()
    end
    screen.getBackgroundColour = function()
        return self:getBackgroundColor()
    end
    screen.getTextColor = function()
        return self:getTextColor()
    end
    screen.getTextColour = function()
        return self:getTextColor()
    end
    screen.getCursorBlink = function()
        return self:getCursorBlink()
    end
    screen.getSize = function()
        return self:getSize()
    end
    screen.getCursorPos = function()
        return self:getCursorPos()
    end
    screen.setBackgroundColor = function(color)
        return self:setBackgroundColor(color)
    end
    screen.setBackgroundColour = function(color)
        return self:setBackgroundColor(color)
    end
    screen.setTextColor = function(color)
        return self:setTextColor(color)
    end
    screen.setTextColour = function(color)
        return self:setTextColor(color)
    end
    screen.setCursorBlink = function(blink)
        return self:setCursorBlink(blink)
    end
    screen.setCursorPos = function(x, y)
        return self:setCursorPos(x, y)
    end
    screen.scroll = function(y)
        return self:scroll(y)
    end
    screen.isColor = function()
        return self:isColor()
    end
    screen.isColour = function()
        return self:isColor()
    end
    screen.blit = function(text, textColor, backgroundColor)
        return self:blit(text, textColor, backgroundColor)
    end

    return screen
end

function FrameScreen:addPadding(padLeft, padRight, padTop, padBottom)
    v.expect(1, padLeft, "number")
    v.expect(2, padRight, "number")
    v.expect(3, padTop, "number")
    v.expect(4, padBottom, "number")

    self.basePos.x = self.basePos.x + padLeft
    self.basePos.y = self.basePos.y + padTop
    self.width = math.max(0, self.width - padLeft - padRight)
    self.height = math.max(0, self.height - padTop - padBottom)
end

function FrameScreen:toAbsolutePos(x, y)
    local parentX = self.basePos.x + x - 1
    local parentY = self.basePos.y + y - 1

    if ui.isFrameScreen(self.output) then
        return ui.getFrameScreen(self.output):toAbsolutePos(parentX, parentY)
    end
    return parentX, parentY
end

function FrameScreen:toRealtivePos(x, y)
    if ui.isFrameScreen(self.output) then
        x, y = ui.getFrameScreen(self.output):toRealtivePos(x, y)
    end

    x = x - self.basePos.x + 1
    y = y - self.basePos.y + 1
    return x, y
end

function FrameScreen:write(text)
    if self.pos.y > self.height then
        return
    end
    self.output.setBackgroundColor(self:getBackgroundColor())
    self.output.setTextColor(self:getTextColor())
    self:setCursorPos(self.pos.x, self.pos.y)
    for i = 1, #text, 1 do
        local char = text:sub(i,i)
        if self.pos.x > self.width then
            return
        end
        self.output.write(char)
        self.pos.x = self.pos.x + 1
    end
end

function FrameScreen:clearLine()
    local oldPos = core.copy(self.pos)
    self:setBackgroundColor(self:getBackgroundColor())
    self:setCursorPos(1, oldPos.y)
    self:write(string.rep(" ", self.width))
    self:setCursorPos(oldPos.x, oldPos.y)
end

function FrameScreen:clear()
    local oldPos = core.copy(self.pos)
    for y = 1, self.height, 1 do
        self:clearLine()
        self.pos.y = self.pos.y + 1
    end
    self:setCursorPos(oldPos.x, oldPos.y)
end

function FrameScreen:getBackgroundColor()
    return getColor(self.backgroundColor, self.output.getBackgroundColor())
end

function FrameScreen:getTextColor()
    return getColor(self.textColor, self.output.getTextColor())
end

function FrameScreen:getCursorBlink()
    return self.output.getCursorBlink()
end

function FrameScreen:getSize()
    return self.width, self.height
end

function FrameScreen:getCursorPos()
    return self.pos.x, self.pos.y
end

function FrameScreen:setBackgroundColor(color)
    v.expect(1, color, "number")
    v.range(color, 1)
    self.backgroundColor = color
    self.output.setBackgroundColor(self.backgroundColor)
end

function FrameScreen:setTextColor(color)
    v.expect(1, color, "number")
    v.range(color, 1)
    self.textColor = color
    self.output.setTextColor(self.textColor)
end

function FrameScreen:setCursorBlink(blink)
    v.expect(1, blink, "bool")
    self.output.setCursorBlink(blink)
end

function FrameScreen:setCursorPos(x, y)
    v.expect(1, x, "number")
    v.expect(2, y, "number")
    v.range(x, 1, self.width)
    v.range(y, 1, self.height)
    self.pos = {x=x, y=y}
    x = x - 1
    y = y - 1
    self.output.setCursorPos(self.basePos.x + x, self.basePos.y + y)
end

function FrameScreen:scroll(y)
    -- TODO
    error("Scrolling for Frame Not Supported")
end

local Frame = Group:extend("ui.Frame")
ui.Frame = Frame
function Frame:init(anchor, opt)
    opt = opt or {}
    v.expect(1, anchor, "table")
    v.field(opt, "id", "string", "nil")
    v.field(opt, "width", "number", "nil")
    v.field(opt, "height", "number", "nil")
    v.field(opt, "fillHorizontal", "boolean", "nil")
    v.field(opt, "fillVertical", "boolean", "nil")
    v.field(opt, "padLeft", "number", "nil")
    v.field(opt, "padRight", "number", "nil")
    v.field(opt, "padTop", "number", "nil")
    v.field(opt, "padBottom", "number", "nil")
    v.field(opt, "backgroundColor", "number", "nil")
    v.field(opt, "borderColor", "number", "nil")
    v.field(opt, "fillColor", "number", "nil")
    v.field(opt, "textColor", "number", "nil")
    v.field(opt, "border", "number", "nil")
    v.field(opt, "bubble", "boolean", "nil")
    Frame.super.init(self, opt)
    if opt.fillHorizontal == nil then
        opt.fillHorizontal = false
    end
    if opt.fillVertical == nil then
        opt.fillVertical = false
    end
    if opt.padding == nil then
        opt.padding = 1
    end
    if opt.borderColor == nil then
        opt.borderColor = colors.gray
    end
    if opt.border == nil then
        opt.border = 1
    end
    if opt.padLeft == nil then
        opt.padLeft = 0
    end
    if opt.padRight == nil then
        opt.padRight = opt.padLeft
    end
    if opt.padTop == nil then
        opt.padTop = math.max(0, opt.padLeft - 1)
    end
    if opt.padBottom == nil then
        opt.padBottom = opt.padTop
    end
    if opt.bubble == nil then
        opt.bubble = true
    end

    self.anchor = anchor
    self.width = opt.width
    self.height = opt.height
    self.fillHorizontal = opt.fillHorizontal
    self.fillVertical = opt.fillVertical
    self.padLeft = opt.padLeft
    self.padRight = opt.padRight
    self.padTop = opt.padTop
    self.padBottom = opt.padBottom
    self.backgroundColor = opt.backgroundColor
    self.borderColor = opt.borderColor
    self.fillColor = opt.fillColor
    self.textColor = opt.textColor
    self.border = opt.border
    self.bubble = opt.bubble
    self:validate()
    return self
end

function Frame:get(id, output)
    v.expect(1, id, "string")
    v.expect(2, output, "table", "nil")
    if output ~= nil then
        ui.requireOutput(output)
        output = self:makeScreen(output)
    end
    return Frame.super.get(self, id, output)
end

function Frame:validate(output)
    v.field(self, "border", "number")
    v.range(self.border, 0, 3)


    v.field(self, "anchor", "table")
    if not object.has(self.anchor, Anchor) then
        error("anchor much be of type Anchor")
    end

    v.field(self, "width", "number", "nil")
    if self.width ~= nil then
        v.range(self.width, 1)
    end
    v.field(self, "height", "number", "nil")
    if self.height ~= nil then
        if self.border > 0 then
            v.range(self.height, 3)
        else
            v.range(self.height, 1)
        end
    end

    if self.backgroundColor ~= nil then
        v.field(self, "backgroundColor", "number")
        v.range(self.backgroundColor, 1)
    end
    if self.fillColor ~= nil then
        v.field(self, "fillColor", "number")
        v.range(self.fillColor, 1)
    end
    if self.borderColor ~= nil then
        v.field(self, "borderColor", "number")
        v.range(self.borderColor, 1)
    end
    if self.textColor ~= nil then
        v.field(self, "textColor", "number")
        v.range(self.textColor, 1)
    end
end

function Frame:getBackgroundColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil then
        ui.requireOutput(output)
        return getColor(self.backgroundColor, output.getBackgroundColor())
    end
    return self.backgroundColor
end

function Frame:getFillColor(output)
    return self.fillColor
end

function Frame:getBorderColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil then
        ui.requireOutput(output)
        getColor(self.borderColor, output.getBackgroundColor())
    end
    return self.borderColor
end

function Frame:getTextColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil then
        ui.requireOutput(output)
        return getColor(self.textColor, output.getTextColor())
    end
    return self.textColor
end

function Frame:getBaseWidth(output)
    local width = self.width
    if width ~= nil then
        return width
    end

    width = 1 + self.padLeft + self.padRight
    if self.border > 0 then
        width = width + 2
    end
    return width
end

function Frame:getWidth(output, startX)
    v.expect(2, startX, "number", "nil")
    if startX == nil then
        startX = self.anchor:getXPos(output, self:getBaseWidth())
    end

    width = self:getBaseWidth()
    if self.fillHorizontal and not (self.anchor:is(Right) or self.anchor:is(TopRight) or self.anchor:is(BottomRight)) then
        local oWidth, _ = output.getSize()
        width = oWidth - startX
    end
    return width
end

function Frame:getBaseHeight(output)
    local height = self.height
    if height ~= nil then
        return height
    end

    height = 1 + self.padTop + self.padBottom
    if self.border > 0 then
        height = height + 2
    end
    return height
end

function Frame:getHeight(output, startY)
    v.expect(2, startY, "number", "nil")
    height = self:getBaseHeight()
    if self.fillVertical and not (self.anchor:is(Bottom) and self.anchor:is(BottomLeft) and self.anchor:is(BottomRight)) then
        local _, oHeight = output.getSize()
        height = oHeight - startY + 1
    end
    return height
end

local function renderBorder1(output, pos, width, height, backgroundColor, borderColor)
    -- top
    output.setCursorPos(pos.x, pos.y)
    output.setTextColor(backgroundColor)
    output.setBackgroundColor(borderColor)
    output.write("\x9f" .. string.rep("\x8f", width - 2))
    output.setTextColor(borderColor)
    output.setBackgroundColor(backgroundColor)
    output.write("\x90")

    for i = 1, height - 2, 1 do
        -- left border
        output.setCursorPos(pos.x, pos.y + i)
        output.setTextColor(backgroundColor)
        output.setBackgroundColor(borderColor)
        output.write("\x95")

        -- right border
        output.setCursorPos(pos.x + width - 1, pos.y + i)
        output.setTextColor(borderColor)
        output.setBackgroundColor(backgroundColor)
        output.write("\x95")
    end

    -- bottom border
    output.setCursorPos(pos.x, pos.y + height - 1)
    output.setTextColor(borderColor)
    output.setBackgroundColor(backgroundColor)
    output.write("\x82" .. string.rep("\x83", width - 2) .. "\x81")
end

local function renderBorder2(output, pos, width, height, backgroundColor, borderColor)
    -- top
    output.setCursorPos(pos.x, pos.y)
    output.setTextColor(backgroundColor)
    output.setBackgroundColor(borderColor)
    output.write(string.rep("\x83", width))

    for i = 1, height - 1, 1 do
        -- left border
        output.setCursorPos(pos.x, pos.y + i)
        output.setTextColor(backgroundColor)
        output.setBackgroundColor(borderColor)
        output.write(" ")

        -- right border
        output.setCursorPos(pos.x + width - 1, pos.y + i)
        output.setTextColor(backgroundColor)
        output.setBackgroundColor(borderColor)
        output.write(" ")
    end

    -- bottom border
    output.setCursorPos(pos.x, pos.y + height - 1)
    output.setTextColor(borderColor)
    output.setBackgroundColor(backgroundColor)
    output.write(string.rep("\x8f", width))
end

local function renderBorder3(output, pos, width, height, borderColor)
    output.setBackgroundColor(borderColor)

    -- top
    output.setCursorPos(pos.x, pos.y)
    output.write(string.rep(" ", width))

    for i = 1, height - 2, 1 do
        -- left border
        output.setCursorPos(pos.x, pos.y + i)
        output.write(" ")

        -- right border
        output.setCursorPos(pos.x + width - 1, pos.y + i)
        output.write(" ")
    end

    -- bottom border
    output.setCursorPos(pos.x, pos.y + height - 1)
    output.write(string.rep(" ", width))
end

function Frame:makeScreen(output, pos, width, height, doPadding)
    v.expect(1, output, "table")
    v.expect(2, pos, "table", "nil")
    v.expect(3, width, "number", "nil")
    v.expect(4, height, "number", "nil")
    v.expect(5, doPadding, "boolean", "nil")
    ui.requireOutput(output)
    if pos == nil then
        pos = self.anchor:getPos(output, self:getBaseWidth(), self:getBaseHeight())
    else
        pos = core.copy(pos)
    end
    if doPadding == nil then
        doPadding = true
    end
    if not object.is(pos, ScreenPos) then
        error("pos must be a ScreenPos")
    end
    if width == nil then
        width = self:getWidth(output, pos.x)
    end
    if height == nil then
        height = self:getHeight(output, pos.y)
    end

    if self.border > 0 then
        width = width - 2
        height = height - 2
        pos.x = pos.x + 1
        pos.y = pos.y + 1
    end

    frameScreen = FrameScreen(
        output, self.id, core.copy(pos), width, height, self:getTextColor(output), self:getFillColor(output)
    )
    if doPadding then
        frameScreen:addPadding(self.padLeft, self.padRight, self.padTop, self.padBottom)
    end
    local f = fs.open("debug.log", "a")
    f.writeLine(string.format("%s %s %s %s %s", self.id, frameScreen.basePos.x, frameScreen.basePos.y, frameScreen.width, frameScreen.height))
    f.close()
    return frameScreen:ccCompat()
end

function Frame:render(output)
    if not self.visible then
        return
    end

    v.expect(1, output, "table", "nil")
    v.expect(2, children, "boolean", "nil")
    if output == nil then
        output = term
    end
    if children == nil then
        children = true
    end
    self:validate(output)

    local oldTextColor = output.getTextColor()
    local oldBackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()

    local pos = self.anchor:getPos(output, self:getBaseWidth(), self:getBaseHeight())
    local width = self:getWidth(output, pos.x)
    local height = self:getHeight(output, pos.y)
    local backgroundColor = self:getBackgroundColor(output)
    local borderColor = self:getBorderColor(output)
    local textColor = self:getTextColor(output)

    if self.border > 0 and (self:getBackgroundColor() ~= nil or self:getBorderColor() ~= nil) then
        if self.border == 1 then
            renderBorder1(output, pos, width, height, backgroundColor, borderColor)
        elseif self.border == 2 then
            renderBorder2(output, pos, width, height, backgroundColor, borderColor)
        else
            renderBorder3(output, pos, width, height, borderColor)
        end
    end

    output.setTextColor(textColor)
    output.setBackgroundColor(getColor(self:getFillColor(output), oldBackgroundColor))
    local frameScreen = self:makeScreen(output, pos, width, height, false)
    if self:getFillColor() ~= nil then
        frameScreen.clear()
    end
    ui.getFrameScreen(frameScreen):addPadding(
        self.padLeft, self.padRight, self.padTop, self.padBottom
    )
    Frame.super.render(self, frameScreen)

    output.setTextColor(oldTextColor)
    output.setBackgroundColor(oldBackgroundColor)
    output.setCursorPos(oldX, oldY)
end

function Frame:within(output, x, y, absolute)
    if not self.visible then
        return false
    end

    v.expect(1, output, "table")
    ui.requireOutput(output)
    v.expect(2, x, "number")
    v.expect(3, y, "number")
    v.expect(4, absolute, "boolean", "nil")
    v.range(x, 1)
    v.range(y, 1)
    if absolute == nil then
        absolute = false
    end
    self:validate()

    local topLeft = self.anchor:getPos(output, self:getBaseWidth(), self:getBaseHeight())
    if ui.isFrameScreen(output) and absolute then
        output = ui.getFrameScreen(output)
        topLeft = ScreenPos(output:toAbsolutePos(topLeft.x, topLeft.y))
    end

    local width = self:getWidth(output, topLeft.x)
    local height = self:getHeight(output, topLeft.y)
    local bottomRight = ScreenPos(topLeft.x + width - 1, topLeft.y + height - 1)

    return x >= topLeft.x and x <= bottomRight.x and y >= topLeft.y and y <= bottomRight.y
end

function Frame:handle(output, event, ...)
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.requireOutput(output)

    local frameScreen = self:makeScreen(output)
    for _, obj in pairs(self.i) do
        if obj:handle(frameScreen, {event, table.unpack(args)}) then
            return self.bubble
        end
    end

    if event == "mouse_click" or event == "mouse_up" or event == "monitor_touch" then
        local pos = ScreenPos(args[2], args[3])
        local frameEvent = nil
        if self:within(output, pos.x, pos.y, true) then
            local x, y = ui.getFrameScreen(frameScreen):toRealtivePos(pos.x, pos.y)
            if event == "mouse_click" then
                frameEvent = FrameClickEvent(output, self.id, x, y, args[1])
            elseif event == "mouse_up" then
                frameEvent = FrameDeactivateEvent(output, self.id, x, y, args[1])
            else
                frameEvent = FrameTouchEvent(output, self.id, x, y)
            end
            if frameEvent ~= nil then
                os.queueEvent(frameEvent.name, frameEvent)
            end
            return self.bubble
        end
    end
    return false
end

local Button = Frame:extend("ui.Button")
ui.Button = Button
function Button:init(anchor, label, opt)
    opt = opt or {}
    v.expect(1, anchor, "table")
    v.expect(2, label, "string")
    v.field(opt, "labelAnchor", "table", "nil")
    v.field(opt, "disabled", "boolean", "nil")
    v.field(opt, "activateOnTouch", "boolean", "nil")
    v.field(opt, "activateOnLeftClick", "boolean", "nil")
    v.field(opt, "activateOnRightClick", "boolean", "nil")
    v.field(opt, "activateOnMiddleClick", "boolean", "nil")
    if opt.labelAnchor == nil then
        opt.labelAnchor = Middle()
    end
    if opt.padLeft == nil then
        opt.padLeft = 1
    end
    if opt.disabled == nil then
        opt.disabled = false
    end
    if opt.activateOnTouch == nil then
        opt.activateOnTouch = true
    end
    if opt.activateOnLeftClick == nil then
        opt.activateOnLeftClick = true
    end
    if opt.activateOnRightClick == nil then
        opt.activateOnRightClick = true
    end
    if opt.activateOnMiddleClick == nil then
        opt.activateOnMiddleClick = true
    end
    Button.super.init(self, anchor, opt)

    self.label = Text(opt.labelAnchor, label, {id=string.format("%s.label", self.id)})
    self.disabled = opt.disabled
    self.activated = false
    self.activateOnTouch = opt.activateOnTouch
    self.activateOnLeftClick = opt.activateOnLeftClick
    self.activateOnRightClick = opt.activateOnRightClick
    self.activateOnMiddleClick = opt.activateOnMiddleClick
    self.activateHandlers = {}
    self.touchTimer = nil
    self:add(self.label)
    self:validate()
    return self
end

function Button:updateLabel(output, label)
    local output = self:makeScreen(output)
    self.label:update(output, label)
end

function Button:getBaseWidth(output)
    local width = Button.super.getBaseWidth(self, output)
    if self.width ~= nil then
        return width
    end

    return width + #self.label.label - 1
end

function Button:activate(output, touch)
    if self.disabled or self.activated then
        return
    end
    v.expect(2, touch, "boolean", "nil")

    self.activated = true
    local event = ButtonActivateEvent(output, self.id, touch)
    os.queueEvent(event.name, event)
end

function Button:deactivate(output)
    if not self.activated then
        return
    end

    self.activated = false
    local event = ButtonDeactivateEvent(output, self.id)
    os.queueEvent(event.name, event)
end

function Button:addActivateHandler(handler)
    v.expect(1, handler, "function")

    local id = tostring(handler)
    self.activateHandlers[id] = handler
    return function()
        self.activateHandlers[id] = nil
    end
end

function Button:onActivate(output, event)
    if self.disabled then
        return
    end
    self.activated = true
    for _, handler in pairs(self.activateHandlers) do
        handler(self, output, event)
    end
    self:render(output)
    if event.touch then
        self.touchTimer = os.startTimer(0.5)
    end
end

function Button:onDeactivate(output, event)
    self.activated = false
    self:render(output)
end

function Button:onTouch(output, event)
    if self.disabled or self.activated or not self.activateOnTouch then
        return
    end
    self:activate(output, true)
end

function Button:onClick(output, event)
    if self.disabled or self.activated then
        return
    end

    if event.clickType == ui.c.Click.Left and self.activateOnLeftClick then
        self:activate(output)
    elseif event.clickType == ui.c.Click.Right and self.activateOnRightClick then
        self:activate(output)
    elseif event.clickType == ui.c.Click.Middle and self.activateOnMiddleClick then
        self:activate(output)
    end
end

function Button:onUp(output, event)
    if self.disabled or not self.activated then
        return
    end
    self:deactivate(output)
end

function Button:get(id, output)
    v.expect(1, id, "string")
    v.expect(2, output, "table", "nil")

    if id == self.label.id then
        return self, output
    end

    if output ~= nil then
        ui.requireOutput(output)
        output = self:makeScreen(output)
    end
    return Frame.super.get(self, id, output)
end

function Button:handle(output, event, ...)
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.requireOutput(output)

    if ui.l.Events.UI[event] then
        local eventData = args[1]
        if eventData.objId == self.id then
            if event == ui.c.Events.frame_touch then
                self:onTouch(output, eventData)
            elseif event == ui.c.Events.frame_click then
                self:onClick(output, eventData)
            elseif event == ui.c.Events.frame_up then
                self:onUp(output, eventData)
            elseif event == ui.c.Events.button_activate then
                self:onActivate(output, eventData)
            elseif event == ui.c.Events.button_deactivate then
                self:onDeactivate(output, eventData)
            end
        elseif event == ui.c.Events.text_update then
            if eventData.objId == self.label.id then
                local oldLabel = eventData.oldLabel
                local newLabel = eventData.newLabel
                if #newLabel < #oldLabel then
                    local oldBackgroundColor = self.backgroundColor
                    local oldBorderColor = self.borderColor
                    local oldFillColor = self.fillColor
                    self.backgroundColor = output.getBackgroundColor()
                    self.borderColor = output.getBackgroundColor()
                    self.fillColor = output.getBackgroundColor()
                    self.label.label = string.rep(" ", #oldLabel)
                    self:render(output)
                    self.backgroundColor = oldBackgroundColor
                    self.borderColor = oldBorderColor
                    self.fillColor = oldFillColor
                end
                self.label.label = newLabel
                self:render(output)
                return true
            end
        end
        return self.bubble
    elseif event == "timer" then
        if args[1] == self.touchTimer then
            self.touchTimer = nil
            self:deactivate(output)
        end
    end

    return Button.super.handle(self, output, {event, table.unpack(args)})
end

function Button:getFillColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil and self.activated then
        ui.requireOutput(output)
        getColor(self.borderColor, output.getBackgroundColor())
    end
    if self.activated then
        return self.borderColor
    end
    return self.fillColor
end

function Button:getBorderColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil and not self.activated then
        ui.requireOutput(output)
        getColor(self.borderColor, output.getBackgroundColor())
    end
    if self.activated then
        return self.fillColor
    end
    return self.borderColor
end

return ui
