local v = require("cc.expect")

local core = require("am.core")
local textLib = require("am.text")

local b = require("am.ui.base")
local c = require("am.ui.const")
local e = require("am.ui.event")
local h = require("am.ui.helpers")

---@class am.ui.BoundText:am.ui.b.UIBoundObject
---@field obj am.ui.Text
local BoundText = b.UIBoundObject:extend("am.ui.BoundText")

---Updates label text
---@param label string
function BoundText:update(label)
    self.obj:update(self.output, label)
end

---@class am.ui.Text.opt:am.ui.b.UIObject.opt
---@field textColor number|nil
---@field backgroundColor number|nil

---@class am.ui.Text:am.ui.b.UIObject
---@field label string|string[]
---@field anchor am.ui.a.Anchor
---@field textColor number
---@field backgroundColor number
local Text = b.UIObject:extend("am.ui.Text")
Text.Bound = BoundText
---@param anchor am.ui.a.Anchor
---@param label string|string[]
---@param opt? am.ui.Text.opt
---@return am.ui.Text
function Text:init(anchor, label, opt)
    opt = opt or {}
    v.expect(1, anchor, "table")
    v.expect(2, label, "string", "table")
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

    v.field(self, "label", "string", "table")
    v.field(self, "anchor", "table")
    v.field(self, "textColor", "number", "nil")
    v.field(self, "backgroundColor", "number", "nil")
    if not h.isAnchor(self.anchor) then
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
    h.requireOutput(output)

    if c.l.Events.UI[event] and args[1].objId == self.id then
        if event == c.e.Events.text_update then
            local oldLabel, oldMaxWidth = self:getLines(args[1].oldLabel)
            local newLabel, newMaxWidth = self:getLines(args[1].newLabel)
            if newMaxWidth < oldMaxWidth then
                self.label = {}
                for i = 1, #oldLabel, 1 do
                    self.label[i] = string.rep(" ", oldMaxWidth)
                end
                local oldBackgroundColor = self.backgroundColor
                local oldTextColor = self.textColor
                self.backgroundColor = output.getBackgroundColor()
                self.textColor = output.getBackgroundColor()
                self:render(output)
                self.backgroundColor = oldBackgroundColor
                self.textColor = oldTextColor
            end
            self.label = args[1].newLabel
            self:render(output)
            return true
        end
    end
    return false
end

--- @class am.ui.linedef
--- @field text string
--- @field color number|nil

---@param label? string|string[]
---@return am.ui.linedef[], number
function Text:getLines(label)
    local lines
    if label == nil then
        label = self.label
    end

    if type(label) == "string" then
        lines = {label}
    else
        lines = core.copy(label)
    end

    local maxWidth = 0
    for i, line in ipairs(lines) do
        local text, color = textLib.getTextColor(line)
        local newLine = {text=text, color=color}
        if #text > maxWidth then
            maxWidth = #text
        end
        lines[i] = newLine
    end
    return lines, maxWidth
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
    local oldTextColor = output.getTextColor()
    local oldBackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()
    Text.super.render(self, output)

    local lines, width = self:getLines()
    local pos = self.anchor:getPos(output, width, #lines)
    local backgroundColor = h.getColor(self.backgroundColor, output.getBackgroundColor())

    for i = 0, #lines - 1, 1 do
        local line = lines[i + 1]
        local textColor = h.getColor(self.textColor, line.color, output.getTextColor())

        output.setTextColor(textColor)
        output.setBackgroundColor(backgroundColor)
        output.setCursorPos(pos.x, pos.y + i)
        output.write(line.text)
    end

    output.setTextColor(oldTextColor)
    output.setBackgroundColor(oldBackgroundColor)
    output.setCursorPos(oldX, oldY)
end

---Updates label text to output
---@param output cc.output
---@param label string|string[]
function Text:update(output, label)
    v.expect(1, output, "table")
    v.expect(2, label, "string", "table")
    h.requireOutput(output)

    local changed = false
    if type(label) == "string" then
        changed = self.label ~= label
    elseif type(label) ~= type(self.label) or #label ~= #self.label then
        changed = true
    else
        for i, line in ipairs(self.label) do
            if line ~= label[i] then
                changed = true
                break
            end
        end
    end

    if changed then
        -- TextUpdate event is used instead of re-rendering directly to allow parent objects
        --  to capture the update and handle it themselves
        local event = e.TextUpdateEvent(output, self.id, self.label, label)
        self.label = label
        os.queueEvent(event.name, event)
    end
end

---Binds Text to an output
---@param output cc.output
---@returns am.ui.BoundText
function Text:bind(output)
    return BoundText(output, self)
end

return Text
