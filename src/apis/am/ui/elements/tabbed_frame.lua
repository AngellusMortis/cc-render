local v = require("cc.expect")

local core = require("am.core")

local Frame = require("am.ui.elements.frame")
local h = require("am.ui.helpers")
local e = require("am.ui.event")
local c = require("am.ui.const")

---@class am.ui.BoundTabbedFrame:am.ui.BoundFrame
---@field obj am.ui.TabbedFrame
local BoundTabbedFrame = Frame.Bound:extend("am.ui.BoundTabbedFrame")

---@param id string
---@return am.ui.Frame
function BoundTabbedFrame:createTab(id)
    return self.obj:createTab(id)
end

---@param index number
---@return am.ui.BoundFrame
function BoundTabbedFrame:getTab(index)
    return self.obj:getTab(self.output, index)
end

---@return am.ui.BoundFrame
function BoundTabbedFrame:getActive()
    return self.obj:getActive(self.output)
end

---@param index number
function BoundTabbedFrame:setActive(index)
    self.obj:setActive(self.output, index)
end

---@class am.ui.TabbedFrame.opt:am.ui.Frame.opt
---@field primaryTabId string|nil

---@class am.ui.TabbedFrame:am.ui.Frame
---@field i nil
---@field tabs am.ui.Frame[]
local TabbedFrame = Frame:extend("am.ui.Popup")
---@param anchor am.ui.a.Anchor
---@param opt am.ui.Frame.opt

---@return am.ui.TabbedFrame
function TabbedFrame:init(anchor, opt)
    opt = opt or {}
    v.expect(1, anchor, "table")
    v.field(opt, "primaryTabId", "string", "nil")
    TabbedFrame.super.init(self, anchor, opt)
    if opt.primaryTabId == nil then
        opt.primaryTabId = "main"
    end

    self.i = nil
    self.tabs = {}
    self:createTab(opt.primaryTabId)
    self:setActive(nil, 1)
    return self
end

---@param id string
---@return am.ui.Frame
function TabbedFrame:createTab(id)
    local index = #self.tabs + 1
    local tab = Frame(self.anchor, {
        id=string.format("%s.%d.%s", self.id, index, id),
        width=self.width,
        height=self.height,
        fillHorizontal=self.fillHorizontal,
        fillVertical=self.fillVertical,
        padLeft=self.padLeft,
        padRight=self.padRight,
        padTop=self.padTop,
        padBottom=self.padBottom,
        backgroundColor=self.backgroundColor,
        borderColor=self.borderColor,
        fillColor=self.fillColor,
        textColor=self.textColor,
        border=self.border,
        scrollBar=self.scrollBar,
        scrollBarTrackColor=self.scrollBarTrackColor,
        scrollBarColor=self.scrollBarColor,
        scrollBarButtonColor=self.scrollBarButtonColor,
        scrollBarTextColor=self.scrollBarTextColor,
        scrollBarDisabledColor=self.scrollBarDisabledColor
    })
    tab:setVisible(false)
    self.tabs[index] = tab
    return tab
end

---@param output cc.output
---@return am.ui.BoundFrame
function TabbedFrame:getTab(output, index)
    v.expect(1, index, "number")
    v.range(index, 1, #self.tabs)

    local tab = self.tabs[index]
    return tab:bind(output)
end

---@param output cc.output
---@return am.ui.BoundFrame
function TabbedFrame:getActive(output)
    return self:getTab(output, self.active)
end

---@param output cc.output
---@param index number
function TabbedFrame:setActive(output, index)
    v.expect(1, index, "number")
    v.range(index, 1, #self.tabs)

    for tabIndex, tab in ipairs(self.tabs) do
        if tabIndex == index then
            tab:setVisible(true)
            if tab.scrollBar then
                tab.currentScroll = 0
            end
        else
            tab:setVisible(false)
        end
    end
    if output ~= nil then
        local event = e.TabChangedEvent(output, self.id, self.active, index)
        os.queueEvent(event.name, event)
    end
    self.active = index
end

---@param visible boolean
function TabbedFrame:setVisible( visible)
    v.expect(1, visible, "boolean")
    if visible then
        self:setActive(nil, self.active)
    else
        for _, tab in ipairs(self.tabs) do
            tab:setVisible(false)
        end
    end
    self.visible = visible
end

---@param output? cc.output
function TabbedFrame:render(output)
    if not self.visible then
        return
    end

    local tab = self:getActive(output)
    tab:render()
end

---@param id string
---@param output? cc.output
---@return am.ui.b.UIBoundObject?
function TabbedFrame:get(id, output)
    v.expect(1, id, "string")
    v.expect(2, output, "table", "nil")
    if output ~= nil then
        h.requireOutput(output)
    end

    if id == self.id then
        return self:bind(output)
    end

    for _, tab in ipairs(self.tabs) do
        if id == tab.id then
            return self:bind(output)
        end
        local obj = tab:get(id, output)
        if obj ~= nil then
            return obj
        end
    end
    return nil
end

---@param output cc.output
---@param pos? am.ui.b.ScreenPos
---@param width? number
---@param height? number
---@param doPadding? boolean
---@return am.ui.FrameScreenCompat
function TabbedFrame:makeScreen(output, pos, width, height, doPadding)
    local tab = self:getActive(output)
    return tab:makeScreen(pos, width, height, doPadding)
end

---@param output cc.output
---@param amount number
function TabbedFrame:scroll(output, amount)
    local tab = self:getActive(output)
    return tab:scroll(amount)
end

---@param x number
---@param y number
---@return boolean
function TabbedFrame:within(output, x, y)
    local tab = self:getActive(output)
    return tab:within(x, y)
end

---@param output cc.output
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function TabbedFrame:handle(output, event, ...)
    ---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)

    if event == c.e.Events.tab_change then
        self:setActive(nil, args[1].newIndex)
        self:render(output)
        return true
    end

    for _, tab in ipairs(self.tabs) do
        if tab:handle(output, event, table.unpack(args)) then
            return true
        end
    end
    return false
end

---@param output cc.output
---@returns am.ui.BoundTabbedFrame
function TabbedFrame:bind(output)
    return BoundTabbedFrame(output, self)
end

return TabbedFrame
