local v = require("cc.expect")

local core = require("am.core")

local a = require("am.ui.anchor")
local c = require("am.ui.const")
local e = require("am.ui.event")
local h = require("am.ui.helpers")
local Text = require("am.ui.elements.text")
local Frame = require("am.ui.elements.frame")

---@class am.ui.BoundProgressBar:am.ui.BoundFrame
---@field obj am.ui.ProgressBar
local BoundProgressBar = Frame.Bound:extend("am.ui.BoundGroup")
bound.BoundProgressBar = BoundProgressBar

---@return string
function BoundProgressBar:getLabelText()
    self.obj:getLabelText()
end

---Updates label for ProgressBar
---@param label? string
---@param showProgress? boolean
---@param showPercent? boolean
function BoundProgressBar:updateLabel(label, showProgress, showPercent)
    self.obj:updateLabel(self.output, label, showProgress, showPercent)
end

---Updates progress for ProgressBar
---@param current number
function BoundProgressBar:update(current)
    self.obj:update(self.output, current)
end

---@class am.ui.ProgressBar.opt:am.ui.Frame.opt
---@field label string|nil
---@field labelAnchor am.ui.a.Anchor|nil
---@field current number|nil
---@field displayTotal number|nil
---@field total number|nil
---@field progressColor number|nil
---@field progressTextColor number|nil
---@field progressVertical boolean|nil
---@field showProgress boolean|nil
---@field showPercent boolean|nil

---@class am.ui.ProgressBar:am.ui.Frame
---@field baseLabel string
---@field label am.ui.Text
---@field fillFrame am.ui.Frame
---@field fillLabel am.ui.Text
---@field current number
---@field displayTotal number
---@field total number
---@field progressColor number
---@field progressTextColor number
---@field progressVertical boolean
---@field showProgress boolean
---@field showPercent boolean
local ProgressBar = Frame:extend("am.ui.ProgressBar")
ProgressBar.Bound = BoundProgressBar
---@param anchor am.ui.a.Anchor
---@param opt am.ui.ProgressBar.opt
---@return am.ui.ProgressBar
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
        opt.labelAnchor = a.Anchor(2, 1)
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
    ProgressBar.super.init(self, anchor, opt)

    self.baseLabel = opt.label
    self.current = opt.current
    self.displayTotal = opt.displayTotal
    self.total = opt.total
    self.progressColor = opt.progressColor
    self.progressTextColor = opt.progressTextColor
    self.progressVertical = opt.progressVertical
    self.showProgress = opt.showProgress
    self.showPercent = opt.showPercent

    self.label = Text(opt.labelAnchor, self:getLabelText(), {id=string.format("%s.label", self.id)})
    self.fillFrame = Frame(
        a.BottomLeft(), {id=string.format("%s.fill", self.id), fillVertical=true, border=0}
    )
    self.fillLabel = Text(a.Anchor(1, 1), self:getLabelText(), {id=string.format("%s.fillLabel", self.id)})
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

    v.field(self, "displayTotal", "number", "nil")

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
        h.requireOutput(output)
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
        local displayCurrent = self.current
        local displayTotal = self.total
        if self.displayTotal ~= nil then
            displayCurrent = math.floor(percent * self.displayTotal)
            displayTotal = self.displayTotal
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

    local screen = self:makeScreen(output)
    local oldTextColor = output.getTextColor()
    local oldBackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()
    local label = self:getLabelText()
    self.label.label = label
    self.label.textColor = self:getTextColor(output)
    ProgressBar.super.render(self, output)

    local current = math.min(self.current, self.total)
    local percent = current / self.total

    local screenWidth, screenHeight = screen.getSize()
    local labelPos = self.label.anchor:getPos(screen, #label, 1)
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

---Updates label for ProgressBar
---@param output cc.output
---@param label? string
---@param showProgress? boolean
---@param showPercent? boolean
function ProgressBar:updateLabel(output, label, showProgress, showPercent)
    v.expect(1, output, "table")
    v.expect(2, label, "string", "nil")
    v.expect(3, showProgress, "boolean", "nil")
    v.expect(4, showPercent, "boolean", "nil")
    h.requireOutput(output)

    local labelChanged = label ~= nil and self.baseLabel ~= label
    local progressChanged = showProgress ~= nil and self.showProgress ~= showProgress
    local percentChanged = showPercent ~= nil and self.showPercent ~= showPercent

    if not (labelChanged or progressChanged or percentChanged) then
        return
    end

    local event = e.ProgressBarLabelUpdateEvent(output, self.id)
    if labelChanged then
        event.oldLabel = self.baseLabel
        event.newLabel = label
        self.baseLabel = label
    end
    if progressChanged then
        event.oldShowProgress = self.showProgress
        event.newShowProgress = showProgress
        self.showProgress = showProgress
    end
    if percentChanged then
        event.oldShowPercent = self.showPercent
        event.newShowPercent = showPercent
        self.showPercent = showPercent
    end

    -- Event is used instead of re-rendering directly to allow parent objects
    --  to capture the update and handle it themselves
    os.queueEvent(event.name, event)
end

---Updates progress for ProgressBar
---@param output cc.output
---@param current number
function ProgressBar:update(output, current)
    v.expect(1, output, "table")
    v.expect(2, current, "number")
    h.requireOutput(output)

    current = math.min(self.total, math.max(0, current))
    if self.current == current then
        return
    end

    -- Event is used instead of re-rendering directly to allow parent objects
    --  to capture the update and handle it themselves
    local event = e.ProgressBarUpdateEvent(output, self.id, self.current, current)
    self.current = current
    os.queueEvent(event.name, event)
end

---Handles os event
---@param output cc.output
---@param event string Event name
---@vararg any
---@returns boolean event canceled
function ProgressBar:handle(output, event, ...)
---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, output, "table")
    v.expect(2, event, "string")
    h.requireOutput(output)

    if event == c.e.Events.progress_label_update and args[1].objId == self.id then
        if args[1].newLabel ~= nil then
            self.baseLabel = args[1].newLabel
        elseif args[1].newShowProgress ~= nil then
            self.showProgress = args[1].newShowProgress
        elseif args[1].newShowPercent ~= nil then
            self.showPercent = args[1].newShowPercent
        end
        self:render(output)
        return true
    elseif event == c.e.Events.progress_update and args[1].objId == self.id then
        self.current = math.min(self.total, math.max(0, args[1].newCurrent))
        self:render(output)
        return true
    end
    ProgressBar.super.handle(self, output, {event, table.unpack(args)})
    return false
end

return ProgressBar
