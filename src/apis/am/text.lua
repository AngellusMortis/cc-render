local v = require("cc.expect")

local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")
local core = require("am.core")

local text = {}

---Simple Color Encoding
---
---error: will result in red text
---warning: will result in yellow text
---success: will result in green text
---info: will result in blue text
---@param msg string
---@return string, number?
function text.getTextColor(msg)
    local parts = core.split(msg, ":")
    local color = nil
    if #parts == 2 then
        if string.lower(parts[1]) == "error" then
            color = colors.red
            msg = parts[2]
        elseif string.lower(parts[1]) == "warning" then
            color = colors.yellow
            msg = parts[2]
        elseif string.lower(parts[1]) == "success" then
            color = colors.green
            msg = parts[2]
        elseif string.lower(parts[1]) == "info" then
            color = colors.blue
            msg = parts[2]
        end
    end

    return msg, color
end

---Writes Color Encoded Text
---
---@param output cc.output|string monitor or term to output to can be left out and will default to terminal
---@param msg? string text to write to output
---@param x? number x position to output to, default to current x pos for output
---@param y? number y position to output to, default to current y pos for output
function text.write(output, msg, x, y)
    if type(output) ~= "table" then
        y = x
        x = msg
        msg = output
        output = term
    end
    v.expect(1, output, "table")
    v.expect(2, msg, "string")
    v.expect(3, x, "number", "nil")
    v.expect(4, y, "number", "nil")
    local oldX, oldY = output.getCursorPos()
    local oldColor = output.getTextColor()

    if x == nil then
        x = oldX
    end
    if y == nil then
        y = oldY
    end

    local actualMsg, color = text.getTextColor(msg)
    output.setCursorPos(x, y)
    if color ~= nil then
        output.setTextColor(color)
    end
    output.write(actualMsg)
    output.setTextColor(oldColor)
    output.setCursorPos(oldX, oldY)
end

---Writes Color Encoded Text Centered
---
---@param output cc.output|string monitor or term to output to can be left out and will default to terminal
---@param msg? string text to write to output centered on line
---@param y? number y position to output to, default to current y pos for output
---@param clear? boolean clear the line before writing, default to true
---------------------------------------
function text.center(output, msg, y, clear)
    if type(output) ~= "table" then
        y = msg
        msg = output
        output = term
    end
    ---@cast output cc.output
    v.expect(1, output, "table")
    v.expect(2, msg, "string")
    v.expect(3, y, "number", "nil")
    v.expect(4, clear, "boolean", "nil")
    local oldX, oldY = output.getCursorPos()
    local oldColor = output.getTextColor()
    local width, _ = output.getSize()

    if y == nil then
        y = oldY
    end
    if clear == nil then
        clear = true
    end

    local actualMsg, color = text.getTextColor(msg)
    if clear then
        output.setCursorPos(1, y)
        output.clearLine()
        output.setCursorPos(oldX, oldY)
    end
    text.write(output, msg, (width - #actualMsg) / 2, y)
end

return text
