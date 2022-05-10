local v = require("cc.expect")

require(settings.get("ghu.base") .. "core/apis/ghu")
local core = require("am.core")

local c = require("am.ui.const")
local h = require("am.ui.helpers")
local Group = require("am.ui.elements.group")

---@class am.ui.Screen.opt:am.ui.b.UIObject.opt
---@field textColor number|nil
---@field backgroundColor number|nil

---@class am.ui.Screen:am.ui.Group
---@field output cc.output
---@field textColor number|nil
---@field backgroundColor number|nil
local Screen = Group:extend("am.ui.Screen")
---@param opt? am.ui.Screen.opt
---@return am.ui.Screen
function Screen:init(output, opt)
    opt = opt or {}
    v.expect(1, output, "table", "nil")
    v.field(opt, "id", "string", "nil")
    v.field(opt, "textColor", "number", "nil")
    v.field(opt, "backgroundColor", "number", "nil")
    if output == nil then
        output = term
    end
    h.requireOutput(output)
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
    local textColor = h.getColor(self.textColor, self.output.getTextColor())
    local backgroundColor = h.getColor(self.backgroundColor, self.output.getBackgroundColor())

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

    local output
    if c.l.Events.Always[event] then
        output = self.output
    else
        output = h.getEventOutput({event, unpack(args)})
        if not c.l.Events.UI[event] and not h.isSameScreen(self.output, output) then
            return false
        end
    end

    if c.l.Events.UI[event] then
        local obj = self:get(args[1].objId)
        if obj ~= nil then
            if obj:handle({event, unpack(args)}) then
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

return Screen
