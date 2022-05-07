local v = require("cc.expect")

local object = require("ext.object")
local h = require("am.ui.helpers")
local core = require("am.core")
local c = require("am.ui.const")

local b = {}

local AUTO_ID = 1
local IDS = {}

---@class am.ui.b.BaseObject:lib.object
local BaseObject = object:extend("am.ui.b.BaseObject")
b.BaseObject = BaseObject
function BaseObject:init()
    BaseObject.super.init(self, {})
    getmetatable(self).__tostring = nil

    return self
end

---@class am.ui.b.UIBoundObject:am.ui.b.BaseObject
---@field output cc.output
---@field obj am.ui.b.UIObject
local UIBoundObject = BaseObject:extend("am.ui.b.UIBoundObject")
b.UIBoundObject = UIBoundObject
function UIBoundObject:init(output, obj)
    v.expect(1, output, "table")
    v.expect(2, obj, "table")
    h.requireOutput(output)
    h.requireUIObject(obj)
    UIBoundObject.super.init(self)

    self.output = output
    self.obj = obj
    return self
end

---Validates UI Object
function UIBoundObject:validate()
    self.obj:validate(self.output)
end

---Renders UI Object to output
function UIBoundObject:render()
    self.obj:render(self.output)
end

---Handles os event
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function UIBoundObject:handle(event, ...)
---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, event, "string")

    return self.obj:handle(self.output, {event, unpack(args)})
end

---@class am.ui.b.UIObject:am.ui.b.BaseObject
---@field id string
---@field visible boolean
local UIObject = BaseObject:extend("am.ui.b.UIObject")
b.UIObject = UIObject
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

---Validates UI Object
---@param output? cc.output
function UIObject:validate(output)
end

---Renders UI Object to output
---@param output cc.output
function UIObject:render(output)
    v.expect(1, output, "table", "nil")
    if output == nil then
        output = term
    end
    h.requireOutput(output)
    self:validate(output)
end

---Handles os event
---@param output cc.output
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function UIObject:handle(output, event, ...)
---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    h.requireOutput(output)

    if event == "term_resize" or event == "monitor_resize" then
        self:render(output)
    end

    return false
end

---Binds UIObject to an output
---@param output cc.output
---@returns am.ui.b.UIBoundObject
function UIObject:bind(output)
    return UIBoundObject(output, self)
end

---@class am.ui.b.ScreenPos:am.ui.b.BaseObject
---@field x number
---@field y number
local ScreenPos = BaseObject:extend("am.ui.b.ScreenPos")
b.ScreenPos = ScreenPos
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

---@class am.ui.FrameScreen:am.ui.b.BaseObject
---@field output cc.output
---@field frameId string
---@field basePos am.ui.b.ScreenPos
---@field width number
---@field height number
---@field textColor number|nil
---@field backgroundColor number|nil
local FrameScreen = BaseObject:extend("am.ui.FrameScreen")
b.FrameScreen = FrameScreen
function FrameScreen:init(output, frameId, basePos, width, height, textColor, backgroundColor, currentScroll, viewportHeight)
    FrameScreen.super.init(self)
    v.expect(1, output, "table")
    v.expect(2, frameId, "string")
    v.expect(3, basePos, "table")
    v.expect(4, width, "number")
    v.expect(5, height, "number")
    v.expect(6, textColor, "number", "nil")
    v.expect(7, backgroundColor, "number", "nil")
    v.expect(8, currentScroll, "number")
    v.expect(9, viewportHeight, "number")
    h.requireOutput(output)
    if not h.isPos(basePos) then
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

    if currentScroll == -1 then
        self.viewportStart = 1
        self.viewportEnd = height
    else
        self.viewportStart = 1 + currentScroll
        self.viewportEnd = self.viewportStart + viewportHeight - 1
    end

    self.output = output
    self.frameId = frameId
    self.basePos = basePos
    self.pos = b.ScreenPos(1, 1)
    self.width = width
    self.height = height
    self.textColor = textColor
    self.backgroundColor = backgroundColor
    self.currentScroll = currentScroll
    return self
end

---Returns a ComputerCraft compatible montior/term-like table
---
---Can be reverted with ui.h.getFrameScreen
---@return table
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
    screen.setPaletteColor = function(...)
        return self:setPaletteColor(...)
    end
    screen.setPaletteColour = function(...)
        return self:setPaletteColor(...)
    end
    screen.getPaletteColor = function(color)
        return self:getPaletteColor(color)
    end
    screen.getPaletteColour = function(color)
        return self:getPaletteColor(color)
    end

    return screen
end

---Adds padding to the screen and reduces the writable area
---Should be called before the FrameScreen is used for rendering
---@param padLeft number
---@param padRight number
---@param padTop number
---@param padBottom number
function FrameScreen:addPadding(padLeft, padRight, padTop, padBottom)
    v.expect(1, padLeft, "number")
    v.expect(2, padRight, "number")
    v.expect(3, padTop, "number")
    v.expect(4, padBottom, "number")

    self.basePos.x = self.basePos.x + padLeft
    self.basePos.y = self.basePos.y + padTop
    self.width = math.max(0, self.width - padLeft - padRight)
    self.height = math.max(0, self.height - padTop - padBottom)
    self.viewportEnd = self.viewportEnd - padTop - padBottom
end

---Recursively converts a FrameScreen coordinate into real coords on the physical CC screen
---@param x number
---@param y number
---@return number, number
function FrameScreen:toAbsolutePos(x, y)
    local parentX = self.basePos.x + x - 1
    local parentY = self.basePos.y + y - 1

    if h.isFrameScreen(self.output) then
        return h.getFrameScreen(self.output):toAbsolutePos(parentX, parentY)
    end
    return parentX, parentY
end

---Recursively converts a real coords on the physical CC screen info FrameScreen realtive coords
---Numbers may be less then 1 or negative if the coordinates are in the padding or border area
---@param x number
---@param y number
---@return number, number
function FrameScreen:toRealtivePos(x, y)
    if h.isFrameScreen(self.output) then
        x, y = h.getFrameScreen(self.output):toRealtivePos(x, y)
    end

    x = x - self.basePos.x + 1
    y = y - self.basePos.y + 1
    return x, y
end

---Writes text to FrameScreen at current pos
---@param text string
function FrameScreen:write(text)
    if self.pos.y > self.height or self.pos.y < self.viewportStart or self.pos.y > self.viewportEnd then
        return
    end
    if self.pos.x > self.width then
        return
    end
    self.output.setBackgroundColor(self:getBackgroundColor())
    self.output.setTextColor(self:getTextColor())
    self:setCursorPos(self.pos.x, self.pos.y)
    for i = 1, #text, 1 do
        local char = text:sub(i,i)
        self.output.write(char)
        self.pos.x = self.pos.x + 1
        if self.pos.x > self.width then
            return
        end
    end
end

---Writes text to FrameScreen at current pos in specific color
---@param text string
---@param textColor number
---@param backgroundColor number
function FrameScreen:blit(text, textColor, backgroundColor)
    local oldBackgroundColor = self:getBackgroundColor()
    local oldTextColor = self:getTextColor()

    self:setBackgroundColor(backgroundColor)
    self:setTextColor(textColor)
    self:write(text)
    self:setBackgroundColor(oldBackgroundColor)
    self:setTextColor(oldTextColor)
end

---Clears current line for FrameScreen
function FrameScreen:clearLine()
    local oldPos = core.copy(self.pos)
    self:setBackgroundColor(self:getBackgroundColor())
    self:setCursorPos(1, oldPos.y)
    self:write(string.rep(" ", self.width))
    self:setCursorPos(oldPos.x, oldPos.y)
end

---Clears whole FrameScreen, will not clear padding or border area
function FrameScreen:clear()
    local oldPos = core.copy(self.pos)
    self:setCursorPos(self.pos.x, self.viewportStart)
    for y = self.viewportStart, self.viewportEnd, 1 do
        self:clearLine()
        self.pos.y = self.pos.y + 1
    end
    self:setCursorPos(oldPos.x, oldPos.y)
end

---Gets current background color for FrameScreen
---@return number
function FrameScreen:getBackgroundColor()
    return h.getColor(self.backgroundColor, self.output.getBackgroundColor())
end

---Gets current text color for FrameScreen
---@return number
function FrameScreen:getTextColor()
    return h.getColor(self.textColor, self.output.getTextColor())
end

---Gets current cursor blink setting for FrameScreen output
---@return boolean
function FrameScreen:getCursorBlink()
    return self.output.getCursorBlink()
end

---Gets current size for FrameScreen
---@return number, number
function FrameScreen:getSize()
    return self.width, self.height
end

---Gets current cursor position for FrameScreen
---@return number, number
function FrameScreen:getCursorPos()
    return self.pos.x, self.pos.y
end

---Sets background color for FrameScreen
---@param color number
function FrameScreen:setBackgroundColor(color)
    v.expect(1, color, "number")
    v.range(color, 1)
    self.backgroundColor = color
    self.output.setBackgroundColor(self.backgroundColor)
end

---Sets text color for FrameScreen
---@param color number
function FrameScreen:setTextColor(color)
    v.expect(1, color, "number")
    v.range(color, 1)
    self.textColor = color
    self.output.setTextColor(self.textColor)
end

---Sets cursor blink for FrameScreen output
---@param blink boolean
function FrameScreen:setCursorBlink(blink)
    v.expect(1, blink, "bool")
    self.output.setCursorBlink(blink)
end

---Sets cursor position for FrameScreen
---@param x number
---@param y number
function FrameScreen:setCursorPos(x, y)
    v.expect(1, x, "number")
    v.expect(2, y, "number")
    v.range(x, 1, self.width)
    v.range(y, 1, self.height)
    self.pos = {x=x, y=y}
    if y < self.viewportStart or y > self.viewportEnd then
        return
    end
    x = x - 1
    y = y - self.viewportStart
    self.output.setCursorPos(self.basePos.x + x, self.basePos.y + y)
end

---Returns of FrameScreen's output supoprts color
---@return boolean
function FrameScreen:isColor()
    return self.output.isColor()
end

---Scrolling is actually handled within the frame
---@param y number
function FrameScreen:scroll(y)
end

---Sets palette color for FrameScreen output
---@vararg number
function FrameScreen:setPaletteColor(...)
    -- TODO
    self.output.setPaletteColor(...)
end

---Gets palette color for FrameScreen output
---@param color number
---@return number
function FrameScreen:getPaletteColor(color)
    self.output.getPaletteColor(color)
end

---Returns click area for a given relative coords
---@param x number
---@param y number
---@param padLeft number
---@param padRight number
---@param padTop number
---@param padBottom number
function FrameScreen:getClickArea(x, y, padLeft, padRight, padTop, padBottom)
    local isPadding = false
    if x < 1 then
        if x < (1 - padLeft) then
            return c.ClickArea.Border
        end
        isPadding = true
    elseif x > self.width then
        if x > self.width + padRight then
            return c.ClickArea.Border
        end
        isPadding = true
    end

    if y < 1 then
        if y < (1 - padTop) then
            return c.ClickArea.Border
        end
        isPadding = true
    elseif y > self.height then
        if y > self.height + padBottom then
            return c.ClickArea.Border
        end
        isPadding = true
    end

    if isPadding then
        return c.ClickArea.Padding
    end
    return c.ClickArea.Screen
end

return b

---@class cc.output
---@field write fun(string)
---@field scroll fun(string)
---@field getCursorPos fun(): number, number
---@field setCursorPos fun(number, number)
---@field getCursorBlink fun(): boolean
---@field setCursorBlink fun(boolean)
---@field getSize fun(): number, number
---@field clear fun()
---@field clearLine fun()
---@field getTextColor fun(): number
---@field getTextColour fun(): number
---@field setTextColor fun(number)
---@field setTextColour fun(number)
---@field getBackgroundColor fun(): number
---@field getBackgroundColour fun(): number
---@field setBackgroundColor fun(number)
---@field setBackgroundColour fun(number)
---@field isColor fun(): boolean
---@field isColour fun(): boolean
---@field blit fun(string, number, number)
---@field getPaletteColor fun(number): number
---@field getPaletteColour fun(number): number
---@field setPaletteColor fun(...)
---@field setPaletteColour fun(...)

---@class am.ui.FrameScreenCompat:cc.output
---@field _frameScreenRef am.ui.FrameScreen

---@class cc.terminal:cc.output
---@field nativePaletteColour fun(number): number
---@field nativePaletteColor fun(number): number
---@field redirect fun(cc.output)
---@field current fun(): cc.output
---@field native fun()

---@class cc.monitor:cc.output
---@field setTextScale fun(number)
---@field getTextScale fun(): number

---@class oslib
---@field pullEvent fun(string?): string, ...
---@field pullEventRaw fun(string?): string, ...
---@field sleep fun(number): number
---@field version fun(): string
---@field run fun(table, string, ...): boolean
---@field queueEvent fun(string, ...)
---@field startTimer fun(number): number
---@field cancelTimer fun(number)
---@field setAlarm fun(number): number
---@field cancelAlarm fun(number)
---@field shutdown fun()
---@field reboot fun()
---@field getComputerID fun(): number
---@field computerLabel fun(): string?
---@field setComputerLabel fun(string)
---@field clock fun(): number
---@field time fun(string): number
---@field day fun(string?): number
---@field epoch fun(string?): number
---@field date fun(string?, number?): any
