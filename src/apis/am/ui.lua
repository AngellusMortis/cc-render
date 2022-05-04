local v = require("cc.expect")

require(settings.get("ghu.base") .. "core/apis/ghu")
local core = require("am.core")
local textLib = require("am.text")

local b = require("am.ui.base")
local bound = require("am.ui.bound")
local ui = {}
ui.a = require("am.ui.anchor")
ui.c = require("am.ui.const")
ui.e = require("am.ui.event")
ui.h = require("am.ui.helpers")
ui.ScreenPos = b.ScreenPos
ui.UIObject = b.UIObject
ui.UILoop = require("am.ui.loop")

---@class am.ui.Group:am.ui.b.UIObject
---@field i am.ui.b.UIObject[]
local Group = b.UIObject:extend("am.ui.Group")
ui.Group = Group
function Group:init(opt)
    opt = opt or {}
    v.field(opt, "id", "string", "nil")
    Group.super.init(self, opt)

    self.i = {}
    return self
end

---Add UI obj to Group
---@param obj am.ui.b.UIObject
function Group:add(obj)
    v.expect(1, obj, "table")

    ui.h.requireUIObject(obj)
    if ui.h.isUIScreen(obj) then
        error("Cannot nest Screen UIs")
    end

    self.i[obj.id] = obj
end

---Recursively searches for UI Obj by id
---@param id string
---@param output? cc.output
---@return am.ui.b.UIBoundObject?
function Group:get(id, output)
    v.expect(1, id, "string")
    v.expect(2, output, "table", "nil")
    if output ~= nil then
        ui.h.requireOutput(output)
    end

    if self.i[id] ~= nil then
        return self.i[id]:bind(output)
    end

    for _, obj in pairs(self.i) do
        if obj:has(Group) then
            ---@diagnostic disable-next-line: undefined-field
            local subObj = obj:get(id, output)
            if subObj ~= nil then
                return subObj
            end
        end
    end
    return nil
end

---Recursively searches for UI Obj by id and removes it
---@param id string
---@return boolean
function Group:remove(id)
    v.expect(1, id, "string")

    if self.i[id] ~= nil then
        table.remove(self.i, id)
        return true
    end

    for _, obj in pairs(self.i) do
        if obj:is(Group) then
            local removed = table.remove(obj, id)
            if removed then
                return true
            end
        end
    end

    return false
end

---Removes all UI objs
function Group:reset()
    self.i = {}
end

---Binds Group to an output
---@param output cc.output
---@returns am.ui.BoundGroup
function Group:bind(output)
    return bound.BoundGroup(output, self)
end

---Renders Group and all child UI objs
---@param output? cc.output
function Group:render(output)
    if not self.visible then
        return
    end
    v.expect(1, output, "table", "nil")
    if output == nil then
        output = term
    end
    ---@cast output cc.output
    Group.super.render(self, output)

    local oldTextColor = output.getTextColor()
    local oldBackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()

    for _, obj in pairs(self.i) do
        obj:render(output)
    end

    output.setTextColor(oldTextColor)
    output.setBackgroundColor(oldBackgroundColor)
    output.setCursorPos(oldX, oldY)
end

---Handles os event
---@param output cc.output
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function Group:handle(output, event, ...)
---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.h.requireOutput(output)

    -- only do one render call for whole group
    if event == "term_resize" or event == "monitor_resize" then
        self:render(output)
        return false
    end

    for _, obj in pairs(self.i) do
        if obj:handle(output, {event, unpack(args)}) then
            return true
        end
    end
    return false
end

---@class am.ui.Screen:am.ui.Group
---@field output cc.output
---@field textColor number|nil
---@field backgroundColor number|nil
local Screen = Group:extend("am.ui.Screen")
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
    ui.h.requireOutput(output)
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

---Recursively searches for UI Obj by id
---@param id string
---@return am.ui.b.UIBoundObject?
function Screen:get(id)
    v.expect(1, id, "string")
    return Screen.super.get(self, id, self.output)
end

---Renders Screen and all child UI objs
function Screen:render()
    if not self.visible then
        return
    end

    local _, height = self.output.getSize()
    local textColor = ui.h.getColor(self.textColor, self.output.getTextColor())
    local backgroundColor = ui.h.getColor(self.backgroundColor, self.output.getBackgroundColor())

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

---Handles os event
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function Screen:handle(event, ...)
---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, event, "string")

    local output = ui.h.getEventOutput({event, unpack(args)})
    if not ui.c.l.Events.UI[event] and not ui.h.isSameScreen(self.output, output) then
        return false
    end

    if ui.c.l.Events.UI[event] then
        local obj = self:get(args[1].objId)
        if obj ~= nil then
            if not obj:handle({event, unpack(args)}) then
                return true
            end
        end
        return false
    end

    -- only do one render call for whole group
    if event == "term_resize" or event == "monitor_resize" then
        self:render()
        return false
    end
    for _, obj in pairs(self.i) do
        if obj:handle(output, {event, unpack(args)}) then
            return true
        end
    end

    return true
end

---Does nothing since screens are already bound
---@param output cc.output
---@returns am.ui.Screen
function Screen:bind(output)
    return self
end

---@class am.ui.Text:am.ui.b.UIObject
---@field label string
---@field anchor am.ui.a.Anchor
---@field textColor number
---@field backgroundColor number
local Text = b.UIObject:extend("am.ui.Text")
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

---Validates Frame Object
---@param output? cc.output
function Text:validate(output)
    Text.super.validate(self, output)

    v.field(self, "label", "string")
    v.field(self, "anchor", "table")
    v.field(self, "textColor", "number", "nil")
    v.field(self, "backgroundColor", "number", "nil")
    if not ui.h.isAnchor(self.anchor) then
        error("anchor much be of type Anchor")
    end
end

---Handles os event
---@param output cc.output
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function Text:handle(output, event, ...)
---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.h.requireOutput(output)

    if event == ui.c.e.Events.text_update and args[1].objId == self.id then
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

---Renders Group and all child UI objs
---@param output? cc.output
function Text:render(output)
    if not self.visible then
        return
    end

    v.expect(1, output, "table", "nil")
    if output == nil then
        output = term
    end
    ---@cast output cc.output
    Text.super.render(self, output)

    local oldTextColor = output.getTextColor()
    local oldbackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()

    local msg, color = textLib.getTextColor(self.label)
    local pos = self.anchor:getPos(output, #msg, 1)
    local textColor = ui.h.getColor(self.textColor, color, output.getTextColor())
    local backgroundColor = ui.h.getColor(self.backgroundColor, output.getBackgroundColor())

    output.setTextColor(textColor)
    output.setBackgroundColor(backgroundColor)
    output.setCursorPos(pos.x, pos.y)
    output.write(msg)

    output.setTextColor(oldTextColor)
    output.setBackgroundColor(oldbackgroundColor)
    output.setCursorPos(oldX, oldY)
end

---Updates label text to output
---@param output cc.output
---@param label string
function Text:update(output, label)
    v.expect(1, output, "table")
    v.expect(2, label, "string")
    ui.h.requireOutput(output)

    if self.label ~= label then
        -- TextUpdate event is used instead of re-rendering directly to allow parent objects
        --  to capture the update and handle it themselves
        local event = ui.e.TextUpdateEvent(output, self.id, self.label, label)
        self.label = label
        os.queueEvent(event.name, event)
    end
end

---Binds Text to an output
---@param output cc.output
---@returns am.ui.BoundText
function Text:bind(output)
    return bound.BoundText(output, self)
end


---@class am.ui.Frame:am.ui.Group
---@field anchor am.ui.a.Anchor
---@field width number|nil
---@field height number|nil
---@field fillHorizontal boolean
---@field fillVertical boolean
---@field padLeft number
---@field padRight number
---@field padTop number
---@field padBottom number
---@field backgroundColor number|nil
---@field borderColor number|nil
---@field fillColor number|nil
---@field textColor number|nil
---@field border number
---@field bubble boolean
local Frame = Group:extend("am.ui.Frame")
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

---Recursively searches for UI Obj by id
---@param id string
---@param output? cc.output
---@return am.ui.b.UIObject?
function Frame:get(id, output)
    v.expect(1, id, "string")
    v.expect(2, output, "table", "nil")
    if output ~= nil then
        ui.h.requireOutput(output)
        output = self:makeScreen(output)
    end
    return Frame.super.get(self, id, output)
end

---Validates Frame Object
---@param output? cc.output
function Frame:validate(output)
    v.field(self, "border", "number")
    v.range(self.border, 0, 3)

    v.field(self, "anchor", "table")
    if not ui.h.isAnchor(self.anchor) then
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

---Gets background color for Frame
---@param output? cc.output
---@returns number
function Frame:getBackgroundColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil then
        ui.h.requireOutput(output)
        return ui.h.getColor(self.backgroundColor, output.getBackgroundColor())
    end
    return self.backgroundColor
end

---Gets fill color for Frame
---@param output? cc.output
---@returns number
function Frame:getFillColor(output)
    return self.fillColor
end

---Gets border color for Frame
---@param output? cc.output
---@returns number
function Frame:getBorderColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil then
        ui.h.requireOutput(output)
        ui.h.getColor(self.borderColor, output.getBackgroundColor())
    end
    return self.borderColor
end

---Gets text color for Frame
---@param output cc.output
---@returns number
function Frame:getTextColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil then
        ui.h.requireOutput(output)
        return ui.h.getColor(self.textColor, output.getTextColor())
    end
    return self.textColor
end

---Gets width for the Frame without auto filling
---@returns number
function Frame:getBaseWidth()
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

---Gets width for the Frame
---@param output cc.output
---@param startX? number
---@returns number
function Frame:getWidth(output, startX)
    v.expect(2, startX, "number", "nil")
    if startX == nil then
        startX = self.anchor:getXPos(output, self:getBaseWidth())
    end

    local width = self:getBaseWidth()
    if self.fillHorizontal and not (self.anchor:is(ui.a.Right) or self.anchor:is(ui.a.TopRight) or self.anchor:is(ui.a.BottomRight)) then
        local oWidth, _ = output.getSize()
        width = oWidth - startX + 1
    end
    return width
end

---Gets height for the Frame without auto filling
---@returns number
function Frame:getBaseHeight()
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

---Gets height for the Frame
---@param output cc.output
---@param startY? number
---@returns number
function Frame:getHeight(output, startY)
    v.expect(2, startY, "number", "nil")
    local height = self:getBaseHeight()
    if self.fillVertical and not (self.anchor:is(ui.a.Bottom) and self.anchor:is(ui.a.BottomLeft) and self.anchor:is(ui.a.BottomRight)) then
        local _, oHeight = output.getSize()
        height = oHeight - startY + 1
    end
    return height
end

---Makes CC compatible FrameScreen for Frame
---@param output cc.output
---@param pos? am.ui.b.ScreenPos
---@param width? number
---@param height? number
---@param doPadding? boolean
---@return am.ui.FrameScreenCompat
function Frame:makeScreen(output, pos, width, height, doPadding)
    v.expect(1, output, "table")
    v.expect(2, pos, "table", "nil")
    v.expect(3, width, "number", "nil")
    v.expect(4, height, "number", "nil")
    v.expect(5, doPadding, "boolean", "nil")
    ui.h.requireOutput(output)
    if pos == nil then
        pos = self.anchor:getPos(output, self:getBaseWidth(), self:getBaseHeight())
    else
        pos = core.copy(pos)
    end
    ---@cast pos am.ui.b.ScreenPos
    if doPadding == nil then
        doPadding = true
    end
    if not ui.h.isPos(pos) then
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

    local frameScreen = b.FrameScreen(
        output, self.id, core.copy(pos), width, height, self:getTextColor(output), self:getFillColor(output)
    )
    if doPadding then
        frameScreen:addPadding(self.padLeft, self.padRight, self.padTop, self.padBottom)
    end
    return frameScreen:ccCompat()
end

---Renders Group and all child UI objs
---@param output? cc.output
function Frame:render(output)
    if not self.visible then
        return
    end

    v.expect(1, output, "table", "nil")
    if output == nil then
        output = term
    end
    ---@cast output cc.output
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
            ui.h.renderBorder1(output, pos, width, height, backgroundColor, borderColor)
        elseif self.border == 2 then
            ui.h.renderBorder2(output, pos, width, height, backgroundColor, borderColor)
        else
            ui.h.renderBorder3(output, pos, width, height, borderColor)
        end
    end

    output.setTextColor(textColor)
    output.setBackgroundColor(ui.h.getColor(self:getFillColor(output), oldBackgroundColor))
    local frameScreen = self:makeScreen(output, pos, width, height, false)
    if self:getFillColor() ~= nil then
        frameScreen.clear()
    end
    ui.h.getFrameScreen(frameScreen):addPadding(
        self.padLeft, self.padRight, self.padTop, self.padBottom
    )
    Frame.super.render(self, frameScreen)

    output.setTextColor(oldTextColor)
    output.setBackgroundColor(oldBackgroundColor)
    output.setCursorPos(oldX, oldY)
end

---Checks if coords on phyiscal CC screen is is within Frame
---@param x number
---@param y number
---@return boolean
function Frame:within(output, x, y)
    if not self.visible then
        return false
    end

    v.expect(1, output, "table")
    ui.h.requireOutput(output)
    v.expect(2, x, "number")
    v.expect(3, y, "number")
    v.range(x, 1)
    v.range(y, 1)
    self:validate(output)

    local topLeft = self.anchor:getPos(output, self:getBaseWidth(), self:getBaseHeight())
    if ui.h.isFrameScreen(output) then
        output = ui.h.getFrameScreen(output)
        topLeft = b.ScreenPos(output:toAbsolutePos(topLeft.x, topLeft.y))
    end

    local width = self:getWidth(output, topLeft.x)
    local height = self:getHeight(output, topLeft.y)
    local bottomRight = b.ScreenPos(topLeft.x + width - 1, topLeft.y + height - 1)

    return x >= topLeft.x and x <= bottomRight.x and y >= topLeft.y and y <= bottomRight.y
end

---Handles os event
---@param output cc.output
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function Frame:handle(output, event, ...)
---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    ui.h.requireOutput(output)

    local frameScreen = self:makeScreen(output)
    for _, obj in pairs(self.i) do
        if obj:handle(frameScreen, {event, unpack(args)}) then
            return self.bubble
        end
    end

    if event == "mouse_click" or event == "mouse_up" or event == "monitor_touch" then
        local pos = b.ScreenPos(args[2], args[3])
        local frameEvent = nil
        if self:within(output, pos.x, pos.y) then
            local x, y = ui.h.getFrameScreen(frameScreen):toRealtivePos(pos.x, pos.y)
            if event == "mouse_click" then
                frameEvent = ui.e.FrameClickEvent(output, self.id, x, y, args[1])
            elseif event == "mouse_up" then
                frameEvent = ui.e.FrameDeactivateEvent(output, self.id, x, y, args[1])
            else
                frameEvent = ui.e.FrameTouchEvent(output, self.id, x, y)
            end
            if frameEvent ~= nil then
                os.queueEvent(frameEvent.name, frameEvent)
            end
            return self.bubble
        end
    end
    return false
end

---Binds Frame to an output
---@param output cc.output
---@returns am.ui.BoundFrame
function Frame:bind(output)
    return bound.BoundFrame(output, self)
end

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
        opt.labelAnchor = ui.a.Middle()
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
        ui.h.requireOutput(output)
        ui.h.getColor(self.borderColor, output.getBackgroundColor())
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
        ui.h.requireOutput(output)
        ui.h.getColor(self.borderColor, output.getBackgroundColor())
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
    local event = ui.e.ButtonActivateEvent(output, self.id, touch)
    os.queueEvent(event.name, event)
end

---Deactivates the button
---@param output cc.output
function Button:deactivate(output)
    if not self.activated then
        return
    end

    self.activated = false
    local event = ui.e.ButtonDeactivateEvent(output, self.id)
    os.queueEvent(event.name, event)
end

---Adds event handler for when button is acitvated
---@param handler fun(button:am.ui.Button, output:table, event:am.ui.e.ButtonActivateEvent)
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

    if event.clickType == ui.c.Click.Left and self.activateOnLeftClick then
        self:activate(output)
    elseif event.clickType == ui.c.Click.Right and self.activateOnRightClick then
        self:activate(output)
    elseif event.clickType == ui.c.Click.Middle and self.activateOnMiddleClick then
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
        ui.h.requireOutput(output)
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
    ui.h.requireOutput(output)

    if ui.c.l.Events.UI[event] then
        local eventData = args[1]
        if eventData.objId == self.id then
            if event == ui.c.e.Events.frame_touch then
                self:onTouch(output, eventData)
            elseif event == ui.c.e.Events.frame_click then
                self:onClick(output, eventData)
            elseif event == ui.c.e.Events.frame_up then
                self:onUp(output, eventData)
            elseif event == ui.c.e.Events.button_activate then
                self:onActivate(output, eventData)
            elseif event == ui.c.e.Events.button_deactivate then
                self:onDeactivate(output, eventData)
            end
        elseif event == ui.c.e.Events.text_update then
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

    return Button.super.handle(self, output, {event, unpack(args)})
end

---Binds Button to an output
---@param output cc.output
---@returns am.ui.BoundButton
function Button:bind(output)
    return bound.BoundButton(output, self)
end

---@class am.ui.ProgressBar:am.ui.Frame
---@field baseLabel string
---@field label am.ui.Text
---@field fillFrame am.ui.Frame
---@field fillLabel am.ui.Text
---@field current number
---@field displayCurrent number
---@field displayTotal number
---@field total number
---@field progressColor number
---@field progressTextColor number
---@field progressVertical boolean
---@field showProgress boolean
---@field showPercent boolean
local ProgressBar = Frame:extend("am.ui.ProgressBar")
ui.ProgressBar = ProgressBar
function ProgressBar:init(anchor, opt)
    opt = opt or {}
    v.expect(1, anchor, "table")
    v.field(opt, "label", "string", "nil")
    v.field(opt, "labelAnchor", "table", "nil")
    v.field(opt, "current", "number", "nil")
    v.field(opt, "total", "number", "nil")
    v.field(opt, "displayTotal", "number", "nil")
    v.field(opt, "progressColor", "number", "nil")
    v.field(opt, "progressTextColor", "number", "nil")
    v.field(opt, "progressVertical", "boolean", "nil")
    v.field(opt, "showProgress", "boolean", "nil")
    v.field(opt, "showPercent", "boolean", "nil")
    if opt.label == nil then
        opt.label = ""
    end
    if opt.labelAnchor == nil then
        opt.labelAnchor = ui.a.TopLeft()
    end
    if opt.total == nil then
        opt.total = 100
    end
    if opt.current == nil then
        opt.current = 0
    end
    if opt.progressColor == nil then
        opt.progressColor = colors.green
    end
    if opt.progressTextColor == nil then
        opt.progressTextColor = opt.textColor
    end
    if opt.showProgress == nil then
        opt.showProgress = true
    end
    if opt.showPercent == nil then
        opt.showPercent = true
    end
    if opt.progressVertical == nil then
        opt.progressVertical = false
    end
    if opt.fillHorizontal == nil then
        opt.fillHorizontal = true
    end
    if opt.fillVertical == nil then
        if opt.progressVertical then
            opt.fillVertical = true
        end
    end
    Button.super.init(self, anchor, opt)

    self.baseLabel = opt.label
    self.label = Text(opt.labelAnchor, "", {id=string.format("%s.label", self.id)})
    self.fillFrame = Frame(
        ui.a.BottomLeft(), {id=string.format("%s.fill", self.id), fillVertical=true, border=0}
    )
    self.fillLabel = Text(ui.a.Anchor(1, 1), "", {id=string.format("%s.fillLabel", self.id)})
    self.current = opt.current
    self.displayCurrent = nil
    self.displayTotal = opt.displayTotal
    self.total = opt.total
    self.progressColor = opt.progressColor
    self.progressTextColor = opt.progressTextColor
    self.progressVertical = opt.progressVertical
    self.showProgress = opt.showProgress
    self.showPercent = opt.showPercent
    self:add(self.label)
    self:validate()
    return self
end

---Validates Frame Object
---@param output? cc.output
function ProgressBar:validate(output)
    ProgressBar.super.validate(self, output)

    if self.fillFrame == nil then
        return
    end

    v.field(self, "baseLabel", "string")

    v.field(self, "current", "number")
    v.range(self.current, 0)

    v.field(self, "total", "number")
    v.range(self.total, math.floor(self.current))

    v.field(self, "displayCurrent", "number", "nil")
    v.field(self, "displayTotal", "number", "nil")
    if self.displayCurrent ~= nil and self.displayTotal ~= nil then
        v.range(self.displayTotal, math.floor(self.displayCurrent))
    end

    v.field(self, "progressColor", "number")
    v.range(self.progressColor, 1)

    v.field(self, "showPercent", "boolean")
    v.field(self, "showProgress", "boolean")

    self.padLeft = 0
    self.padRight = 0
    self.padTop = 0
    self.padBottom = 0
end

---Binds ProgressBar to an output
---@param output cc.output
---@returns am.ui.BoundProgressBar
function ProgressBar:bind(output)
    return bound.BoundProgressBar(output, self)
end

---Recursively searches for UI Obj by id
---@param id string
---@param output? cc.output
---@return am.ui.b.UIObject?
function ProgressBar:get(id, output)
    v.expect(1, id, "string")
    v.expect(2, output, "table", "nil")

    if id == self.label.id or id == self.fillFrame.id or id == self.fillLabel.id then
        return self:bind(output)
    end

    if output ~= nil then
        ui.h.requireOutput(output)
        output = self:makeScreen(output)
    end
    return Frame.super.get(self, id, output)
end

---@return string
function ProgressBar:getLabelText()
    local label = self.baseLabel
    local current = math.min(self.current, self.total)
    local percent = current / self.total

    if self.showPercent then
        label = label .. string.format(" %d%%", percent * 100)
    end
    if self.showProgress then
        local displayCurrent = self.displayCurrent
        local displayTotal = self.displayTotal
        if displayCurrent == nil or displayTotal == nil then
            displayCurrent = self.current
            displayTotal = self.total
        end
        label = label .. string.format(" [%d/%d]", displayCurrent, displayTotal)
    end

    return label
end

---Renders Group and all child UI objs
---@param output? cc.output
function ProgressBar:render(output)
    if not self.visible then
        return
    end
    v.expect(1, output, "table", "nil")
    if output == nil then
        output = term
    end
    ---@cast output cc.output

    local oldTextColor = output.getTextColor()
    local oldBackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()

    local screen = self:makeScreen(output)
    local screenWidth, screenHeight = screen.getSize()
    local current = math.min(self.current, self.total)
    local percent = current / self.total
    local label = self:getLabelText()
    local labelPos = self.label.anchor:getPos(screen, #label, 1)
    self.label.label = label
    ProgressBar.super.render(self, output)

    local fillAmount
    if self.progressVertical then
        fillAmount = math.floor(screenHeight * percent)
    else
        fillAmount = math.floor(screenWidth * percent)
    end
    if fillAmount > 0 then
        self.fillLabel.label = label
        self.fillLabel.textColor = self.progressTextColor
        local renderText = false
        if self.progressVertical then
            labelPos.y = labelPos.y - (screenHeight - fillAmount)
            if labelPos.y > 0 then
                renderText = true
            end
            self.fillFrame.width = screenWidth
            self.fillFrame.height = fillAmount
            self.fillFrame.fillVertical = false
            self.fillFrame.fillHorizontal = true
        else
            if labelPos.x <= fillAmount then
                renderText = true
            end
            self.fillFrame.width = fillAmount
            self.fillFrame.height = screenHeight
            self.fillFrame.fillVertical = true
            self.fillFrame.fillHorizontal = false
        end
        if renderText then
            self.fillLabel.anchor.x = labelPos.x
            self.fillLabel.anchor.y = labelPos.y
            self.fillFrame:add(self.fillLabel)
        else
            self.fillFrame:reset()
        end

        self.fillFrame.fillColor = self.progressColor
        self.fillFrame:render(screen)
    end

    output.setTextColor(oldTextColor)
    output.setBackgroundColor(oldBackgroundColor)
    output.setCursorPos(oldX, oldY)
end

return ui
