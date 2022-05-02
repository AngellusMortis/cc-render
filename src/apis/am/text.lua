local v = require("cc.expect")

local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")
local core = require("am.cc")

local text = {}

---------------------------------------
-- Simple Color Encoding
--
-- error: will result in red text
-- warning: will result in yellow text
-- success: will result in green text
-- info: will result in blue text
---------------------------------------
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

---------------------------------------
-- Writes Color Encoded Text
--
-- output: monitor or term to output to can be left out and will default to terminal
-- msg: text to write to output
-- x: x position to output to, default to current x pos for output
-- y: y position to output to, default to current y pos for output
---------------------------------------
function text.write(output, msg, x, y)
    if type(output) ~= "table" then
        y = x
        x = msg
        msg = output
        output = term
    end
    local oldX, oldY = output.getCursorPos()
    local oldColor = output.getTextColor()

    if x == nil then
        x = oldX
    end
    if y == nil then
        y = oldY
    end
    v.expect(1, output, "table")
    v.expect(2, msg, "string")
    v.expect(3, x, "number")
    v.expect(4, y, "number")

    local actualMsg, color = text.getTextColor(msg)
    output.setCursorPos(x, y)
    if color ~= nil then
        output.setTextColor(color)
    end
    output.write(actualMsg)
    output.setTextColor(oldColor)
    output.setCursorPos(oldX, oldY)
end

---------------------------------------
-- Writes Color Encoded Text Centered
--
-- output: monitor or term to output to can be left out and will default to terminal
-- msg: text to write to output centered on line
-- y: y position to output to, default to current y pos for output
-- clear: clear the line before writing, default to true
---------------------------------------
function text.center(output, msg, y, clear)
    if type(output) ~= "table" then
        y = msg
        msg = output
        output = term
    end
    local oldX, oldY = output.getCursorPos()
    local oldColor = output.getTextColor()
    local width, _ = output.getSize()

    if y == nil then
        y = oldY
    end
    if clear == nil then
        clear = true
    end
    v.expect(1, output, "table")
    v.expect(2, msg, "string")
    v.expect(3, y, "number")
    v.expect(4, clear, "boolean")

    local actualMsg, color = text.getTextColor(msg)
    if clear then
        output.setCursorPos(1, y)
        output.clearLine()
        output.setCursorPos(oldX, oldY)
    end
    text.write(output, msg, (width - #actualMsg) / 2, y)
end

return text
