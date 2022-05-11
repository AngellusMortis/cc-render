local v = require("cc.expect")

local object = require("ext.object")
local c = require("am.ui.const")
local core = require("am.core")

---Get actual FrameScreen object
---@param output am.ui.FrameScreenCompat|am.ui.FrameScreen output
---@return am.ui.FrameScreen
local function getFrameScreen(output)
    v.expect(1, output, "table")

    if output._frameScreenRef ~= nil and type(output._frameScreenRef) == "table" then
        output = output._frameScreenRef
    end

    return output
end

---Tests if object is a is or has a base class
---@param class table
---@param obj any
---@return boolean
local function is(class, obj)
    v.expect(1, class, "string")
    v.expect(2, obj, "table")
    return object.has(obj, class) ~= false
end


---Detect if output is terminal
---@param output cc.output|cc.terminal output
---@return boolean
local function isTerm(output)
    v.expect(1, output, "table")

    return output.redirect ~= nil and output.current ~= nil
end

---Detect if output is a monitor
---@param output cc.output output
---@return boolean
local function isMonitor(output)
    v.expect(1, output, "table")

    local mt = getmetatable(output)
    if mt == nil then
        return false
    end
    return mt.__name == "peripheral" and mt.type == "monitor"
end

---Detect if output is a frame
---@param output cc.output output
---@return boolean
local function isFrameScreen(output)
    v.expect(1, output, "table")
    output = getFrameScreen(output)
    return is("am.ui.FrameScreen", output)
end

-- Detect if output is an output
---@param output cc.output output
---@return boolean
local function isOutput(output)
    return isTerm(output) or isMonitor(output) or isFrameScreen(output)
end

-- Raises error if not an output
---@param output cc.output output
local function requireOutput(output)
    if not isOutput(output) then
        error("Not a terminal, monitor or frame")
    end
end

---Raises error if not an UIObject
---@param obj table
local function requireUIObject(index, obj)
    v.expect(1, obj, "table")
    if not is("am.ui.b.UIObject", obj) then
        local t = type(obj)
        local name
        local ok, info = pcall(debug.getinfo, 3, "nS")
        if ok and info.name and info.name ~= "" and info.what ~= "C" then
            name = info.name
        end

        if name then
            error(("bad argument #%d to '%s' (expected UIObject, got %s)"):format(index, name, t), 3)
        else
            error(("bad argument #%d (expected UIObject, got %s)"):format(index, t), 3)
        end
    end
end

---Detect if obj is a UIObject
---@param obj table
---@return boolean
local function isUIObject(obj)
    v.expect(1, obj, "table")
    return is("am.ui.b.UIObject", obj)
end

---Detect if obj is a UIScreen
---@param obj any
---@return boolean
local function isUIScreen(obj)
    v.expect(1, obj, "table")
    return is("am.ui.Screen", obj)
end

---Detect if obj is an Anchor
---@param obj any
---@return boolean
local function isAnchor(obj)
    v.expect(1, obj, "table")
    return is("am.ui.a.Anchor", obj)
end

---Detect if obj is a ScreenPos
---@param obj any
---@return boolean
local function isPos(obj)
    v.expect(1, obj, "table")
    return is("am.ui.b.ScreenPos", obj)
end

-- Gets output for an event
---@param event string Event name
---@vararg any
---@returns cc.output? event canceled
local function getEventOutput(event, ...)
    ---@diagnostic disable-next-line: redefined-local
    local event, args = core.cleanEventArgs(event, ...)
    v.expect(1, event, "string")

    local output = nil
    if c.l.Events.Terminal[event] then
        output = term
    elseif c.l.Events.Monitor[event] then
        output = peripheral.wrap(args[1])
    end
    return output
end

-- Detect if two outputs are the same
---@param output1 table output
---@param output2? table output
---@return boolean
local function isSameScreen(output1, output2)
    v.expect(1, output1, "table")
    v.expect(2, output2, "table", "nil")

    if output2 == nil then
        return false
    end

    local sameScreen = false
    if isTerm(output1) and isTerm(output2) then
        sameScreen = true
    elseif isMonitor(output1) and isMonitor(output2) then
        sameScreen = peripheral.getName(output1) == peripheral.getName(output2)
    elseif isFrameScreen(output1) and isFrameScreen(output2) then
        output1 = getFrameScreen(output1)
        output2 = getFrameScreen(output2)
        sameScreen = output1.id == output2.id
    end
    return sameScreen
end

-- Pick color with fallback
---@param color number
---@param default number
---@param secondDefault? number
---@return number
local function getColor(color, default, secondDefault)
    v.expect(1, color, "number", "nil")
    v.expect(2, default, "number", "nil")
    v.expect(3, secondDefault, "number", "nil")

    if color ~= nil then
        return color
    elseif default ~= nil then
        return default
    elseif secondDefault ~= nil then
        return secondDefault
    end

    error("Could not determine color")
end

local function renderBorder1(output, pos, width, height, backgroundColor, borderColor)
    -- top
    output.setCursorPos(pos.x, pos.y)
    output.setTextColor(backgroundColor)
    output.setBackgroundColor(borderColor)
    output.write("\x9f" .. string.rep("\x8f", width - 2))
    output.setTextColor(borderColor)
    output.setBackgroundColor(backgroundColor)
    output.write("\x90")

    for i = 1, height - 2, 1 do
        -- left border
        output.setCursorPos(pos.x, pos.y + i)
        output.setTextColor(backgroundColor)
        output.setBackgroundColor(borderColor)
        output.write("\x95")

        -- right border
        output.setCursorPos(pos.x + width - 1, pos.y + i)
        output.setTextColor(borderColor)
        output.setBackgroundColor(backgroundColor)
        output.write("\x95")
    end

    -- bottom border
    output.setCursorPos(pos.x, pos.y + height - 1)
    output.setTextColor(borderColor)
    output.setBackgroundColor(backgroundColor)
    output.write("\x82" .. string.rep("\x83", width - 2) .. "\x81")
end

local function renderBorder2(output, pos, width, height, backgroundColor, borderColor)
    -- top
    output.setCursorPos(pos.x, pos.y)
    output.setTextColor(backgroundColor)
    output.setBackgroundColor(borderColor)
    output.write(string.rep("\x83", width))

    for i = 1, height - 1, 1 do
        -- left border
        output.setCursorPos(pos.x, pos.y + i)
        output.setTextColor(backgroundColor)
        output.setBackgroundColor(borderColor)
        output.write(" ")

        -- right border
        output.setCursorPos(pos.x + width - 1, pos.y + i)
        output.setTextColor(backgroundColor)
        output.setBackgroundColor(borderColor)
        output.write(" ")
    end

    -- bottom border
    output.setCursorPos(pos.x, pos.y + height - 1)
    output.setTextColor(borderColor)
    output.setBackgroundColor(backgroundColor)
    output.write(string.rep("\x8f", width))
end

local function renderBorder3(output, pos, width, height, borderColor)
    output.setBackgroundColor(borderColor)

    -- top
    output.setCursorPos(pos.x, pos.y)
    output.write(string.rep(" ", width))

    for i = 1, height - 2, 1 do
        -- left border
        output.setCursorPos(pos.x, pos.y + i)
        output.write(" ")

        -- right border
        output.setCursorPos(pos.x + width - 1, pos.y + i)
        output.write(" ")
    end

    -- bottom border
    output.setCursorPos(pos.x, pos.y + height - 1)
    output.write(string.rep(" ", width))
end

local h = {}

h.isTerm = isTerm
h.isMonitor = isMonitor
h.getFrameScreen = getFrameScreen
h.isFrameScreen = isFrameScreen
h.isOutput = isOutput
h.requireOutput = requireOutput
h.getEventOutput = getEventOutput
h.is = is
h.isUIObject = isUIObject
h.requireUIObject = requireUIObject
h.isSameScreen = isSameScreen
h.isUIScreen = isUIScreen
h.isAnchor = isAnchor
h.isPos = isPos
h.getColor = getColor
h.renderBorder1 = renderBorder1
h.renderBorder2 = renderBorder2
h.renderBorder3 = renderBorder3

return h
