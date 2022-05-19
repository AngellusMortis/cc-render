local v = require("cc.expect")

local core = require("am.core")

local a = require("am.ui.anchor")
local c = require("am.ui.const")
local e = require("am.ui.event")
local h = require("am.ui.helpers")
local Text = require("am.ui.elements.text")
local Frame = require("am.ui.elements.frame")

---@class am.ui.BoundButton:am.ui.BoundFrame
---@field obj am.ui.Button
local BoundButton = Frame.Bound:extend("am.ui.BoundButton")

---Updates label text
---@param label string
function BoundButton:updateLabel(label)
    self.obj:updateLabel(self.output, label)
end

---Activates the button
---@param touch? boolean
function BoundButton:activate(touch)
    self.obj:activate(self.output, touch)
end

---Deactivates the button
function BoundButton:deactivate()
    self.obj:deactivate(self.output)
end

---Adds event handler for when button is acitvated
---@param handler fun(button:am.ui.Button, output:table, event:am.ui.e.ButtonActivateEvent)
---@return fun() Unsubcribe method
function BoundButton:addActivateHandler(handler)
    return self.obj:addActivateHandler(handler)
end

---Handler for when button is activated
---Should not be overriden, use `addActivateHandler` instead
---@param event am.ui.e.ButtonActivateEvent
function BoundButton:onActivate(event)
    self.obj:onActivate(self.output, event)
end

---Handler for when button is deactivated
---@param event am.ui.e.ButtonDeactivateEvent
function BoundButton:onDeactivate(event)
    self.obj:onDeactivate(self.output, event)
end

---Handler for when button is touched
---@param event am.ui.e.FrameTouchEvent
function BoundButton:onTouch(event)
    self.obj:onTouch(self.output, event)
end

---Handler for when button is clicked
---@param event am.ui.e.FrameClickEvent
function BoundButton:onClick(event)
    self.obj:onClick(self.output, event)
end

---Handler for when frame click is depressed
---@param event am.ui.e.FrameDeactivateEvent
function BoundButton:onUp(event)
    self.obj:onUp(self.output, event)
end

---@class am.ui.Button.opt:am.ui.Frame.opt
---@field disabled boolean|nil
---@field activated boolean|nil
---@field activateOnTouch boolean|nil
---@field activateOnLeftClick boolean|nil
---@field activateOnRightClick boolean|nil
---@field activateOnMiddleClick boolean|nil

---@class am.ui.Button:am.ui.Frame
---@field label am.ui.Text
---@field disabled boolean
---@field activated boolean
---@field activateOnTouch boolean
---@field activateOnLeftClick boolean
---@field activateOnRightClick boolean
---@field activateOnMiddleClick boolean
---@field activateHandlers fun(button:am.ui.Button, output:table, event:am.ui.e.ButtonActivateEvent)[]
---@field touchTimer number|nil
local Button = Frame:extend("am.ui.Button")
Button.Bound = BoundButton
---@param anchor am.ui.a.Anchor
---@param label string
---@param opt am.ui.Button.opt
---@return am.ui.Button
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
        opt.labelAnchor = a.Middle()
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

---Updates label for Button
---@param output cc.output
---@param label string
function Button:updateLabel(output, label)
    output = self:makeScreen(output)
    self.label:update(output, label)
end

---Gets width for the Frame without auto filling, takes into account of label
---@return number
function Button:getBaseWidth()
    local width = Button.super.getBaseWidth(self)
    if self.width ~= nil then
        return width
    end

    return width + #self.label.label - 1
end

---Gets fill color for Frame
---@param output? cc.output
---@return number
function Button:getFillColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil and self.activated then
        h.requireOutput(output)
        h.getColor(self.borderColor, output.getBackgroundColor())
    end
    if self.activated then
        return self.borderColor
    end
    return self.fillColor
end

---Gets border color for Frame
---@param output? cc.output
---@return number
function Button:getBorderColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil and not self.activated then
        h.requireOutput(output)
        h.getColor(self.borderColor, output.getBackgroundColor())
    end
    if self.activated then
        return self.fillColor
    end
    return self.borderColor
end

---Activates the button
---@param output cc.output
---@param touch? boolean
function Button:activate(output, touch)
    if self.disabled or self.activated then
        return
    end
    v.expect(2, touch, "boolean", "nil")

    self.activated = true
    local event = e.ButtonActivateEvent(output, self.id, touch)
    os.queueEvent(event.name, event)
end

---Deactivates the button
---@param output cc.output
function Button:deactivate(output)
    if not self.activated then
        return
    end

    self.activated = false
    local event = e.ButtonDeactivateEvent(output, self.id)
    os.queueEvent(event.name, event)
end

---Adds event handler for when button is acitvated
---@param handler fun(button:am.ui.Button, output:cc.output, event:am.ui.e.ButtonActivateEvent)
---@return fun() Unsubcribe method
function Button:addActivateHandler(handler)
    v.expect(1, handler, "function")

    local id = tostring(handler)
    self.activateHandlers[id] = handler
    return function()
        self.activateHandlers[id] = nil
    end
end

---Handler for when button is activated
---Should not be overriden, use `addActivateHandler` instead
---@param output cc.output
---@param event am.ui.e.ButtonActivateEvent
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

---Handler for when button is deactivated
---@param output cc.output
---@param event am.ui.e.ButtonDeactivateEvent
function Button:onDeactivate(output, event)
    self.activated = false
    self:render(output)
end

---Handler for when button is touched
---@param output cc.output
---@param event am.ui.e.FrameTouchEvent
function Button:onTouch(output, event)
    if self.disabled or self.activated or not self.activateOnTouch then
        return
    end
    self:activate(output, true)
end

---Handler for when button is clicked
---@param output cc.output
---@param event am.ui.e.FrameClickEvent
function Button:onClick(output, event)
    if self.disabled or self.activated then
        return
    end

    if event.clickType == c.Click.Left and self.activateOnLeftClick then
        self:activate(output)
    elseif event.clickType == c.Click.Right and self.activateOnRightClick then
        self:activate(output)
    elseif event.clickType == c.Click.Middle and self.activateOnMiddleClick then
        self:activate(output)
    end
end

---Handler for when frame click is depressed
---@param output cc.output
---@param event am.ui.e.FrameDeactivateEvent
function Button:onUp(output, event)
    if self.disabled or not self.activated then
        return
    end
    self:deactivate(output)
end

---Recursively searches for UI Obj by id
---@param id string
---@param output? cc.output
---@return am.ui.b.UIObject?
function Button:get(id, output)
    v.expect(1, id, "string")
    v.expect(2, output, "table", "nil")

    if id == self.label.id then
        return self:bind(output)
    end

    if output ~= nil then
        h.requireOutput(output)
        output = self:makeScreen(output)
    end
    return Frame.super.get(self, id, output)
end

---Handles os event
---@param output cc.output
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function Button:handle(output, event, ...)
---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    h.requireOutput(output)

    if event == "mouse_up" then
        self:deactivate(output)
        return false
    end
    if c.l.Events.UI[event] then
        local eventData = args[1]
        if eventData.objId == self.id then
            if event == c.e.Events.frame_touch then
                self:onTouch(output, eventData)
            elseif event == c.e.Events.frame_click then
                self:onClick(output, eventData)
            elseif event == c.e.Events.frame_up then
                self:onUp(output, eventData)
            elseif event == c.e.Events.button_activate then
                self:onActivate(output, eventData)
            elseif event == c.e.Events.button_deactivate then
                self:onDeactivate(output, eventData)
            end
        elseif event == c.e.Events.text_update then
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
        return eventData.objId == self.id or eventData.objId == self.label.id
    elseif event == "timer" then
        if args[1] == self.touchTimer then
            self.touchTimer = nil
            self:deactivate(output)
        end
    end

    return Button.super.handle(self, output, {event, table.unpack(args)})
end

---Binds Button to an output
---@param output cc.output
---@returns am.ui.BoundButton
function Button:bind(output)
    return BoundButton(output, self)
end

return Button
