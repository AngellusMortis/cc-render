local v = require("cc.expect")

require(settings.get("ghu.base") .. "core/apis/ghu")
local core = require("am.core")

local b = require("am.ui.base")
local a = require("am.ui.anchor")
local c = require("am.ui.const")
local e = require("am.ui.event")
local h = require("am.ui.helpers")
local Group, BoundGroup = require("am.ui.elements.group")

---@class am.ui.BoundFrame:am.ui.BoundGroup
---@field obj am.ui.Frame
local BoundFrame = BoundGroup:extend("am.ui.BoundFrame")

---Gets background color for Frame
---@returns number
function BoundFrame:getBackgroundColor()
    return self.obj:getBackgroundColor(self.output)
end

---Gets fill color for Frame
---@returns number
function BoundFrame:getFillColor()
    return self.obj:getFillColor(self.output)
end

---Gets border color for Frame
---@returns number
function BoundFrame:getBorderColor()
    return self.obj:getBorderColor(self.output)
end

---Gets text color for Frame
---@returns number
function BoundFrame:getTextColor()
    return self.obj:getTextColor(self.output)
end

---Gets width for the Frame without auto filling
---@returns number
function BoundFrame:getBaseWidth()
    return self.obj:getBaseWidth()
end

---Gets width for the Frame
---@param startX? number
function BoundFrame:getWidth(startX)
    return self.obj:getWidth(self.output, startX)
end

---Gets height for the Frame without auto filling
---@returns number
function BoundFrame:getBaseHeight()
    return self.obj:getBaseHeight()
end

---Gets height for the Frame
---@param startY? number
---@returns number
function BoundFrame:getHeight(startY)
    return self.obj:getHeight(self.output, startY)
end

---Makes CC compatible FrameScreen for Frame
---@param pos? am.ui.b.ScreenPos
---@param width? number
---@param height? number
---@param doPadding? boolean
---@return am.ui.FrameScreenCompat
function BoundFrame:makeScreen(pos, width, height, doPadding)
    return self.obj:makeScreen(self.output, pos, width, height, doPadding)
end

---Checks if coords on phyiscal CC screen is is within Frame
---@param x number
---@param y number
---@return boolean
function BoundFrame:within(x, y)
    return self.obj:within(self.output, x, y)
end

---@class am.ui.Frame.opt:am.ui.b.UIObject.opt
---@field width number|nil
---@field height number|nil
---@field fillHorizontal boolean|nil
---@field fillVertical boolean|nil
---@field padLeft number|nil
---@field padRight number|nil
---@field padTop number|nil
---@field padBottom number|nil
---@field backgroundColor number|nil
---@field borderColor number|nil
---@field fillColor number|nil
---@field textColor number|nil
---@field border number|nil
---@field scrollBar boolean|nil
---@field scrollBarTrackColor number|nil
---@field scrollBarColor number|nil
---@field scrollBarButtonColor number|nil
---@field scrollBarTextColor number|nil
---@field scrollBarDisabledColor number|nil

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
---@field scrollBar boolean
---@field scrollBarTrackColor number
---@field scrollBarColor number
---@field scrollBarButtonColor number
---@field scrollBarTextColor number
---@field scrollBarDisabledColor number
---@field currentScroll number
local Frame = Group:extend("am.ui.Frame")
---@param anchor am.ui.a.Anchor
---@param opt am.ui.Frame.opt
---@return am.ui.Frame
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
    v.field(opt, "scrollBar", "boolean", "nil")
    v.field(opt, "scrollBarTrackColor", "number", "nil")
    v.field(opt, "scrollBarColor", "number", "nil")
    v.field(opt, "scrollBarButtonColor", "number", "nil")
    v.field(opt, "scrollBarTextColor", "number", "nil")
    v.field(opt, "scrollBarDisabledColor", "number", "nil")
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
    if opt.scrollBar == nil then
        opt.scrollBar = false
    end
    if opt.scrollBarTrackColor == nil then
        opt.scrollBarTrackColor = colors.lightGray
    end
    if opt.scrollBarColor == nil then
        opt.scrollBarColor = colors.gray
    end
    if opt.scrollBarButtonColor == nil then
        opt.scrollBarButtonColor = opt.scrollBarColor
    end
    if opt.scrollBarTextColor == nil then
        opt.scrollBarTextColor = opt.scrollBarTrackColor
    end
    if opt.scrollBarDisabledColor == nil then
        opt.scrollBarDisabledColor = colors.black
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
    self.scrollBar = opt.scrollBar
    self.scrollBarTrackColor = opt.scrollBarTrackColor
    self.scrollBarColor = opt.scrollBarColor
    self.scrollBarButtonColor = opt.scrollBarButtonColor
    self.scrollBarTextColor = opt.scrollBarTextColor
    self.scrollBarDisabledColor = opt.scrollBarDisabledColor
    if self.scrollBar then
        self.currentScroll = 0
    else
        self.currentScroll = -1
    end
    self.maxScroll = 0
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

    local parts = core.split(id, ".")
    local baseId = parts[1]
    for i = 2, #parts - 1, 1 do
        baseId = baseId .. "." .. parts[i]
    end
    if baseId == self.id then
        return self:bind(output)
    end

    if output ~= nil then
        h.requireOutput(output)
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
    if not h.isAnchor(self.anchor) then
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

    if self.scrollBar and self.height == nil then
        error(string.format("frame (%s) cannot have nil height with a scrollBar"))
    end
end

---Gets background color for Frame
---@param output? cc.output
---@returns number
function Frame:getBackgroundColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil then
        h.requireOutput(output)
        return h.getColor(self.backgroundColor, output.getBackgroundColor())
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
        h.requireOutput(output)
        h.getColor(self.borderColor, output.getBackgroundColor())
    end
    return self.borderColor
end

---Gets text color for Frame
---@param output cc.output
---@returns number
function Frame:getTextColor(output)
    v.expect(1, output, "table", "nil")
    if output ~= nil then
        h.requireOutput(output)
        return h.getColor(self.textColor, output.getTextColor())
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
    if self.fillHorizontal and not (self.anchor:is(a.Right) or self.anchor:is(a.TopRight) or self.anchor:is(a.BottomRight)) then
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
    if self.fillVertical and not (self.anchor:is(a.Bottom) and self.anchor:is(a.BottomLeft) and self.anchor:is(a.BottomRight)) then
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
    h.requireOutput(output)
    if pos == nil then
        pos = self.anchor:getPos(output, self:getBaseWidth(), self:getBaseHeight())
    else
        pos = core.copy(pos)
    end
    ---@cast pos am.ui.b.ScreenPos
    if doPadding == nil then
        doPadding = true
    end
    if not h.isPos(pos) then
        error("pos must be a ScreenPos")
    end
    if width == nil then
        width = self:getWidth(output, pos.x)
    end
    if height == nil then
        height = self:getHeight(output, pos.y)
    end

    local viewportHeight = -1
    if self.scrollBar then
        _, viewportHeight = output.getSize()
    end
    if self.border > 0 then
        width = width - 2
        height = height - 2
        pos.x = pos.x + 1
        pos.y = pos.y + 1
        viewportHeight = viewportHeight - 2
    end
    if self.scrollBar then
        width = width - 1
    end

    local frameScreen = b.FrameScreen(
        output, self.id, core.copy(pos), width, height, self:getTextColor(output), self:getFillColor(output), self.currentScroll, viewportHeight
    )
    if doPadding then
        frameScreen:addPadding(self.padLeft, self.padRight, self.padTop, self.padBottom)
    end
    return frameScreen:ccCompat()
end

function Frame:scroll(output, amount)
    local oldScroll = self.currentScroll
    local newScroll = self.currentScroll + amount
    if amount < 0 then
        self.currentScroll = math.max(0, newScroll)
    else
        self.currentScroll = math.min(self.maxScroll, newScroll)
    end
    if self.currentScroll ~= oldScroll then
        local event = e.FrameScrollEvent(output, self.id, oldScroll, self.currentScroll)
        os.queueEvent(event.name, event)
    end
end

---Renders Frame scrollbar
---@param output cc.output
---@param width number
---@param height number
---@param rHeight number
---@param startY number
function Frame:renderScrollBar(output, width, height, rHeight, startY)
    local anchor = a.Anchor(width, startY)
    if self.border > 0 then
        anchor.x = anchor.x - 1
        anchor.y = anchor.y + 1
        rHeight = rHeight - 2
    end

    self.maxScroll = height - rHeight
    local tHeight = rHeight - 2
    local sHeight = math.max(1, math.floor(rHeight / height * tHeight))
    local relScroll = 1
    if self.maxScroll > 0 then
        relScroll = math.floor(self.currentScroll / self.maxScroll * tHeight)
        relScroll = math.min(tHeight - sHeight, relScroll)
        relScroll = math.max(0, relScroll)
    end
    local sAnchor = a.Anchor(1, startY + relScroll)

    local frame = self
    local scrollBarId = self.id .. ".scrollBar"
    local scrollUpButtonId = self.id .. ".scrollUp"
    local scrollDownButtonId = self.id .. ".scrollDown"
    if self.scrollFrame == nil then
        local Button = require("am.ui.elements.button")

        self.scrollFrame = Frame(anchor, {
            id=self.id .. ".scrollFrame",
            width=1,
            height=rHeight,
            border=0,
            fillColor=self.scrollBarTrackColor,
        })
        local scrollUpButton = Button(a.TopLeft(), "\x1e", {
            id=scrollUpButtonId,
            fillColor=self.scrollBarDisabledColor,
            textColor=self.scrollBarTextColor,
            border=0,
            disabled=true,
            padLeft=0,
        })
        scrollUpButton:addActivateHandler(function()
            frame:scroll(output, -1)
        end)
        local scrollDownButton = Button(a.BottomLeft(), "\x1f", {
            id=scrollDownButtonId,
            fillColor=self.scrollBarButtonColor,
            textColor=self.scrollBarTextColor,
            border=0,
            padLeft=0,
        })
        scrollDownButton:addActivateHandler(function()
            frame:scroll(output, 1)
        end)
        local scrollBar = Frame(sAnchor, {
            id = scrollBarId,
            width=1,
            height=sHeight,
            border=0,
            fillColor=self.scrollBarColor
        })
        self.scrollFrame:add(scrollUpButton)
        self.scrollFrame:add(scrollDownButton)
        self.scrollFrame:add(scrollBar)
    else
        self.scrollFrame.anchor = anchor
        self.scrollFrame.height = rHeight
        self.scrollFrame.fillColor = self.scrollBarTrackColor
        local scrollUp = self.scrollFrame.i[scrollUpButtonId]
        scrollUp.disabled = self.currentScroll == 0
        if scrollUp.disabled then
            scrollUp.fillColor = self.scrollBarDisabledColor
        else
            scrollUp.fillColor = self.scrollBarButtonColor
        end
        local scrollDown = self.scrollFrame.i[scrollDownButtonId]
        scrollDown.disabled = self.currentScroll == self.maxScroll
        if scrollDown.disabled then
            scrollDown.fillColor = self.scrollBarDisabledColor
        else
            scrollDown.fillColor = self.scrollBarButtonColor
        end
        local scrollBar = self.scrollFrame.i[scrollBarId]
        scrollBar.height = sHeight
        scrollBar.fillColor = self.scrollBarColor
        scrollBar.anchor = sAnchor
    end

    self.scrollFrame:render(output)
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

    local rHeight = height
    if self.scrollBar then
        local _, oHeight = output.getSize()
        rHeight = math.min(rHeight, oHeight - pos.y + 1)
    end
    -- actual content height
    local sHeight = height - self.padTop - self.padBottom
    if self.border > 0 then
        sHeight = sHeight - 2
        if self:getBackgroundColor() ~= nil or self:getBorderColor() ~= nil then
            if self.border == 1 then
                h.renderBorder1(output, pos, width, rHeight, backgroundColor, borderColor)
            elseif self.border == 2 then
                h.renderBorder2(output, pos, width, rHeight, backgroundColor, borderColor)
            else
                h.renderBorder3(output, pos, width, rHeight, borderColor)
            end
        end
    end

    output.setTextColor(textColor)
    output.setBackgroundColor(h.getColor(self:getFillColor(output), oldBackgroundColor))
    local frameScreen = self:makeScreen(output, pos, width, height, false)
    if self:getFillColor() ~= nil then
        frameScreen.clear()
    end
    h.getFrameScreen(frameScreen):addPadding(
        self.padLeft, self.padRight, self.padTop, self.padBottom
    )
    if self.scrollBar then
        sHeight = sHeight + self.padTop + self.padBottom
        self:renderScrollBar(output, width, sHeight, rHeight, pos.y)
    end
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
    h.requireOutput(output)
    v.expect(2, x, "number")
    v.expect(3, y, "number")
    v.range(x, 1)
    v.range(y, 1)
    self:validate(output)

    local topLeft = self.anchor:getPos(output, self:getBaseWidth(), self:getBaseHeight())
    if h.isFrameScreen(output) then
        local fs = h.getFrameScreen(output)
        topLeft = b.ScreenPos(fs:toAbsolutePos(topLeft.x, topLeft.y))
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
    h.requireOutput(output)

    if event == c.e.Events.frame_scroll and args[1].objId == self.id then
        if self.scrollBar then
            self.currentScroll = args[1].newScroll
            self:render(output)
        end
        return true
    elseif self.scrollBar then
        if self.scrollFrame ~= nil then
            if event ~= "mouse_scroll" then
                if self.scrollFrame:handle(output, {event, unpack(args)}) then
                    return true
                end
            end
        end
    end

    local frameScreen = self:makeScreen(output)
    for _, obj in pairs(self.i) do
        if obj:handle(frameScreen, {event, unpack(args)}) then
            return true
        end
    end

    local events = {
        mouse_click = true,
        mouse_up = true,
        monitor_touch = true,
        mouse_scroll = true,
    }
    if events[event] then
        local pos
        if args[2] > 0 and args[3] > 0 then
            pos = b.ScreenPos(args[2], args[3])
        end
        local frameEvent = nil
        if event == "mouse_scroll" or (pos ~= nil and self:within(output, pos.x, pos.y)) then
            local handled = false
            if event == "mouse_scroll" then
                if self.scrollBar then
                    if pos == nil or self:within(output, pos.x, pos.y) then
                        local scrollAmount = args[1]
                        -- CraftOS PC bug
                        if scrollAmount == 0 then
                            scrollAmount = -1
                        end
                        self:scroll(output, scrollAmount)
                    end
                end
                return false
            else
                local fs = h.getFrameScreen(frameScreen)
                local x, y = fs:toRealtivePos(pos.x, pos.y)
                local clickArea = fs:getClickArea(
                    x, y, self.padLeft, self.padRight, self.padTop, self.padBottom
                )
                if event == "mouse_click" and self.visible then
                    handled = true
                    frameEvent = e.FrameClickEvent(
                        output, self.id, x, y, clickArea, args[1]
                    )
                elseif event == "mouse_up" then
                    frameEvent = e.FrameDeactivateEvent(
                        output, self.id, x, y, clickArea, args[1]
                    )
                elseif event == "monitor_touch" and self.visible then
                    handled = true
                    frameEvent = e.FrameTouchEvent(output, self.id, x, y, clickArea)
                end

                if frameEvent ~= nil then
                    os.queueEvent(frameEvent.name, frameEvent)
                end
            end
            return handled
        end
    end
    return false
end

---Binds Frame to an output
---@param output cc.output
---@returns am.ui.BoundFrame
function Frame:bind(output)
    return BoundFrame(output, self)
end

return Frame, BoundFrame
