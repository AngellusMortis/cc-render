local v = require("cc.expect")

local core = require("am.core")

local Frame = require("am.ui.elements.frame")
local Button = require("am.ui.elements.button")
local a = require("am.ui.anchor")
local h = require("am.ui.helpers")
local e = require("am.ui.event")
local c = require("am.ui.const")

---@class am.ui.BoundTabbedFrame:am.ui.BoundFrame
---@field obj am.ui.TabbedFrame
---@field add nil
local BoundTabbedFrame = Frame.Bound:extend("am.ui.BoundTabbedFrame")

---@param id string
---@return am.ui.Frame
function BoundTabbedFrame:createTab(id)
    return self.obj:createTab(id)
end

---@param lookup number|string
---@return am.ui.BoundFrame
function BoundTabbedFrame:getIndex(lookup)
    return self.obj:getIndex(lookup)
end

---@param lookup string|number
---@return am.ui.Frame
function BoundTabbedFrame:removeTab(lookup)
    return self.obj:removeTab(lookup)
end

---@param lookup number|string
---@param label string
---@return am.ui.BoundFrame
function BoundTabbedFrame:setLabel(lookup, label)
    return self.obj:setLabel(self.output, lookup, label)
end

---@param lookup number|string
---@return am.ui.BoundFrame
function BoundTabbedFrame:getTab(lookup)
    return self.obj:getTab(lookup, self.output)
end

---@return am.ui.BoundFrame
function BoundTabbedFrame:getActive()
    return self.obj:getActive(self.output)
end

---@param lookup number|string
function BoundTabbedFrame:setActive(lookup)
    self.obj:setActive(self.output, lookup)
end

function BoundTabbedFrame:renderTabs()
    self.obj:renderTabs(self.output)
end

---@class am.ui.TabbedFrame.opt:am.ui.Frame.opt
---@field primaryTabId string|nil
---@field showTabs boolean|nil
---@field tabBackgroundColor number|nil
---@field tabFillColor number|nil
---@field tabTextColor number|nil

---@class am.ui.TabbedFrame:am.ui.Frame
---@field i nil
---@field add nil
---@field tabs am.ui.Frame[]
---@field labelFrame am.ui.Frame|nil
local TabbedFrame = Frame:extend("am.ui.Popup")
---@param anchor am.ui.a.Anchor
---@param opt am.ui.Frame.opt

---@return am.ui.TabbedFrame
function TabbedFrame:init(anchor, opt)
    opt = opt or {}
    v.expect(1, anchor, "table")
    v.field(opt, "primaryTabId", "string", "nil")
    v.field(opt, "showTabs", "boolean", "nil")
    v.field(opt, "tabBackgroundColor", "number", "nil")
    v.field(opt, "activeTabFillColor", "number", "nil")
    v.field(opt, "activeTabTextColor", "number", "nil")
    v.field(opt, "tabFillColor", "number", "nil")
    v.field(opt, "tabTextColor", "number", "nil")
    TabbedFrame.super.init(self, anchor, opt)
    if opt.primaryTabId == nil then
        opt.primaryTabId = "main"
    end
    if opt.showTabs == nil then
        opt.showTabs = false
    end
    if opt.activeTabFillColor == nil then
        opt.activeTabFillColor = opt.tabFillColor
    end
    if opt.activeTabTextColor == nil then
        opt.activeTabTextColor = opt.tabTextColor
    end

    self.i = nil
    self.tabs = {}
    self.tabIndexIdMap = {}
    self.tabIdMap = {}
    self.tabLabelMap = {}
    self.tabIndexLabelMap = {}
    self.tabBackgroundColor = opt.tabBackgroundColor
    self.tabFillColor = opt.tabFillColor
    self.tabTextColor = opt.tabTextColor
    self.activeTabFillColor = opt.activeTabFillColor
    self.activeTabTextColor = opt.activeTabTextColor
    self.labelFrame = nil
    if opt.showTabs then
        self.labelFrame = Frame(a.TopLeft(), {
            id=self.id .. ".labelFrame",
            height=1,
            border=0,
            fillHorizontal=true,
            fillColor=opt.tabBackgroundColor
        })
    end
    self:createTab(opt.primaryTabId)
    self:setActive(nil, 1)
    return self
end

---@param id string
---@param output? cc.output
---@return am.ui.Frame
function TabbedFrame:createTab(id, output)
    if self.tabIdMap[id] ~= nil then
        error(string.format("Tab with id %s already exists", id))
        return
    end

    local anchor = a.Anchor(1, 1)
    local height = self.height
    if self.labelFrame ~= nil then
        anchor.y = 2
        if height ~= nil then
            height = height - 1
        end
    end
    local index = #self.tabs + 1
    local tabId = string.format("%s.%s", self.id, id)
    local tab = Frame(anchor, {
        id=tabId,
        width=self.width,
        height=height,
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

    if self.labelFrame ~= nil then
        local labelButton = Button(a.Anchor(1, 1), "", {
            id=tabId .. "Label"
        })
        local tabs = self
        ---@diagnostic disable-next-line: redefined-local
        labelButton:addActivateHandler(function(button, output)
            -- labelFrame FrameScreen -> tabs FrameScreen -> output
            output = h.getFrameScreen(h.getFrameScreen(output).output).output
            tabs:setActive(output, id)
        end)
        self.labelFrame:add(labelButton)
    end

    tab:setVisible(false)
    self.tabs[index] = tab
    self.tabIdMap[id] = index
    self.tabIndexIdMap[index] = id

    if output ~= nil then
        local event = e.TabCreatedEvent(output, self.id, id)
        os.queueEvent(event.name, event)
    end
    return tab
end

---@param lookup string|number
---@return number|nil
function TabbedFrame:getIndex(lookup)
    v.expect(1, lookup, "number", "string")
    local index = nil
    --- @cast index number|nil
    if type(lookup) == "number" then
        v.range(lookup, 1, #self.tabs)
        index = lookup
    else
        index = self.tabIdMap[lookup]
    end
    return index
end

---@param lookup string|number
---@param output? cc.output
---@return number|nil
function TabbedFrame:removeTab(lookup, output)
    v.expect(1, lookup, "number", "string")
    if #self.tabs == 1 then
        error("Cannot remove last tab")
    end

    local tabIndex = self:getIndex(lookup)
    local oldIdMap = self.tabIndexIdMap
    local oldLabelMap = self.tabIndexLabelMap
    local tabId = oldIdMap[tabIndex]

    self.tabIndexIdMap = {}
    self.tabIdMap = {}
    self.tabLabelMap = {}
    self.tabIndexLabelMap = {}

    for index, id in ipairs(oldIdMap) do
        if index ~= tabIndex then
            local label = oldLabelMap[index]
            if index > tabIndex then
                index = index - 1
            end
            self.tabIndexIdMap[index] = id
            self.tabIdMap[id] = index
            self.tabLabelMap[label] = index
            self.tabIndexLabelMap[id] = label
        end
    end

    table.remove(self.tabs, tabIndex)

    if output ~= nil then
        local event = e.TabRemovedEvent(output, self.id, tabId)
        os.queueEvent(event.name, event)
    end
    if tabIndex > #self.tabs then
        if output ~= nil then
            self:setActive(output, #self.tabs)
        else
            self.active = #self.tabs
        end
    end
end

---@param output cc.output
---@param lookup string|number
---@param label string
---@return am.ui.Frame
function TabbedFrame:setLabel(output, lookup, label)
    v.expect(1, lookup, "number", "string")
    v.expect(2, label, "string")
    local index = self:getIndex(lookup)
    if index == nil then
        error("Could not find tab")
    end
    if self.tabLabelMap[label] ~= nil then
        error(string.format("Label %s already exists", label))
    end

    local oldLabel = self.tabIndexLabelMap[index]
    if oldLabel ~= nil then
        self.tabLabelMap[oldLabel] = nil
    end

    self.tabLabelMap[label] = index
    self.tabIndexLabelMap[index] = label
    local event = e.TabLabelUpdatedEvent(output, self.id, self.tabIndexIdMap[index], oldLabel, label)
    os.queueEvent(event.name, event)
end

---@param lookup number|string
---@param output? cc.output
---@return am.ui.BoundFrame|am.ui.Frame
---@overload fun(lookup: number|string): am.ui.Frame
---@overload fun(lookup: number|string, output: cc.output): am.ui.BoundFrame
function TabbedFrame:getTab(lookup, output)
    v.expect(1, lookup, "number", "string")
    local index = self:getIndex(lookup)
    local tab = nil
    if index ~= nil then
        tab = self.tabs[index]
    end

    if tab == nil then
        error("Could not find tab")
    end
    ---@cast tab am.ui.Frame
    if output ~= nil then
        return tab:bind(self:makeScreen(output))
    end
    return tab
end

---@param output cc.output
---@return am.ui.BoundFrame
function TabbedFrame:getActive(output)
    return self:getTab(self.active, output)
end

---@param output cc.output
---@param lookup number|string
function TabbedFrame:setActive(output, lookup)
    v.expect(2, lookup, "number", "string")
    local index = self:getIndex(lookup)

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
        local event = e.TabChangedEvent(output, self.id, self.tabIndexIdMap[self.active], self.tabIndexIdMap[index])
        os.queueEvent(event.name, event)
    end
    self.active = index
end

---@param visible boolean
function TabbedFrame:setVisible(visible)
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

---@param output cc.output
function TabbedFrame:renderTabs(output)
    if not self.visible then
        return
    end
    if self.labelFrame == nil then
        return
    end

    local offset = 1
    local fillColor = h.getColor(self.tabFillColor, self.fillColor, output.getBackgroundColor())
    local textColor = h.getColor(self.tabTextColor, self.textColor, output.getTextColor())
    for index, id in ipairs(self.tabIndexIdMap) do
        local labelText = self.tabIndexLabelMap[index] or id
        local labelId = string.format("%s.%sLabel", self.id, id)
        local label = self.labelFrame:get(labelId, output)
        ---@cast label am.ui.BoundButton
        label.obj.label.label = labelText
        label.obj.anchor.x = offset
        if index == self.active then
            label.obj.fillColor = h.getColor(self.activeTabFillColor, fillColor)
            label.obj.textColor = h.getColor(self.activeTabTextColor, textColor)
        else
            label.obj.fillColor = fillColor
            label.obj.textColor = textColor
        end
        offset = #labelText + 2
    end

    local fs = self:makeScreen(output)
    self.labelFrame:render(fs)
end

---@param output? cc.output
function TabbedFrame:render(output)
    if not self.visible then
        return
    end

    self:renderTabs(output)
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

    if id == self.id or (self.labelFrame ~= nil and id == self.labelFrame.id) then
        return self:bind(output)
    end

    if output ~= nil then
        output = self:makeScreen(output)
    end

    if self.labelFrame ~= nil and self.labelFrame.i[id] ~= nil then
        return self.labelFrame:bind(output)
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
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function TabbedFrame:handle(output, event, ...)
    ---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)

    if event == c.e.Events.tab_created or event == c.e.Events.tab_removed or event == c.e.Events.tab_label_update then
        self:renderTabs(output)
    elseif event == c.e.Events.tab_change then
        self:setActive(nil, args[1].newTabId)
        self:render(output)
        return true
    end

    if self.labelFrame ~= nil and self.labelFrame:handle(output, event, table.unpack(args)) then
        return true
    end

    if output ~= nil then
        output = self:makeScreen(output)
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
