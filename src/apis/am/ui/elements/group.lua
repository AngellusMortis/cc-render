local v = require("cc.expect")

require(settings.get("ghu.base") .. "core/apis/ghu")
local core = require("am.core")

local b = require("am.ui.base")
local h = require("am.ui.helpers")

---@class am.ui.BoundGroup:am.ui.b.UIBoundObject
---@field obj am.ui.Group
local BoundGroup = b.UIBoundObject:extend("am.ui.BoundGroup")

---Add UI obj to Group
---@param obj am.ui.b.UIObject
function BoundGroup:add(obj)
    self.obj:add(obj)
end

---Recursively searches for UI Obj by id
---@param id string
---@return am.ui.b.UIObject?, table
function BoundGroup:get(id)
    v.expect(1, id, "string")
    return self.obj:get(id, self.output)
end

---Recursively sets visible
---@param visible boolean
function BoundGroup:setVisible(visible)
    self.obj:setVisible(visible)
end

---Recursively searches for UI Obj by id and removes it
---@param id string
---@return boolean
function BoundGroup:remove(id)
    return self.obj:remove(id)
end

---Removes all UI objs
function BoundGroup:reset()
    self.obj:reset()
end

---@class am.ui.Group:am.ui.b.UIObject
---@field i am.ui.b.UIObject[]
local Group = b.UIObject:extend("am.ui.Group")
---@param opt? am.ui.b.UIObject.opt
---@return am.ui.Group
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

    h.requireUIObject(obj)
    if h.isUIScreen(obj) then
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
        h.requireOutput(output)
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

---Recursively sets visible
---@param visible boolean
function Group:setVisible(visible)
    v.expect(1, visible, "boolean")
    self.visible = visible
    for _, obj in pairs(self.i) do
        if obj:has(Group) then
            ---@cast obj am.ui.Group
            obj:setVisible(visible)
        else
            obj.visible = visible
        end
    end
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
    return BoundGroup(output, self)
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
    local oldTextColor = output.getTextColor()
    local oldBackgroundColor = output.getBackgroundColor()
    local oldX, oldY = output.getCursorPos()
    Group.super.render(self, output)

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
    h.requireOutput(output)

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

return Group, BoundGroup
