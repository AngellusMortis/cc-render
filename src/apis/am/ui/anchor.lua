local v = require("cc.expect")

local b = require("am.ui.base")
local c = require("am.ui.const")
local h = require("am.ui.helpers")

local a = {}

---@class am.ui.a.Anchor:am.ui.b.BaseObject
---@field x number
---@field y number
local Anchor = b.BaseObject:extend("am.ui.a.Anchor")
a.Anchor = Anchor
---@param x number
---@param y number
---@return am.ui.a.Anchor
function Anchor:init(x, y)
    Anchor.super.init(self)
    v.expect(1, x, "number")
    v.expect(2, y, "number")
    v.range(x, 1)
    v.range(y, 1)

    self.x = x
    self.y = y
    return self
end

function Anchor:getXPos(output, width)
    return self.x
end

function Anchor:getYPos(output, height)
    return self.y
end

function Anchor:getPos(output, width, height)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    v.expect(3, height, "number")
    h.requireOutput(output)

    local x = self:getXPos(output, width)
    local y = self:getYPos(output, height)
    return b.ScreenPos(x, y)
end

--region Center Aligned

---@class am.ui.a.Center:am.ui.a.Anchor
---@field offset number
---@field offsetAmount number
local Center = Anchor:extend("am.ui.a.Center")
a.Center = Center
---@param y number
---@param offset number ui.c.Offset.Left or ui.c.Offset.Right
---@param offsetAmount number
---@return am.ui.a.Center
function Center:init(y, offset, offsetAmount)
    v.expect(1, y, "number")
    v.expect(2, offset, "number", "nil")
    v.expect(3, offsetAmount, "number", "nil")
    v.range(y, 1)
    if offset ~= nil then
        v.range(offset, 1, 2)
    end
    if offsetAmount == nil then
        offsetAmount = 1
    end
    v.range(offsetAmount, 1)
    Center.super.init(self, 1, y)
    self.offset = offset
    self.offsetAmount = offsetAmount
    return self
end

function Center:getXPos(output, width)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    h.requireOutput(output)

    local oWidth, _ = output.getSize()
    local center = oWidth / 2
    if self.offset == nil then
        center = center - width / 2
    elseif self.offset == c.Offset.Left then
        center = center - width - self.offsetAmount
    elseif self.offset == c.Offset.Right then
        center = center + self.offsetAmount + 1
    end
    if oWidth % 2 == 0 then
        center = math.ceil(center)
    end
    return math.max(1, center + 1)
end

---@class am.ui.a.Middle:am.ui.a.Center
local Middle = Center:extend("am.ui.a.Middle")
a.Middle = Middle
---@return am.ui.a.Middle
function Middle:init()
    Middle.super.init(self, 1)
    return self
end

function Middle:getYPos(output, height)
    v.expect(1, output, "table")
    v.expect(2, height, "number")
    h.requireOutput(output)

    local _, oHeight = output.getSize()
    return math.max(1, math.floor((oHeight + 1) / 2 - height / 2))
end

---@class am.ui.a.Top:am.ui.a.Center
local Top = Center:extend("am.ui.a.Top")
a.Top = Top
---@param offset number ui.c.Offset.Left or ui.c.Offset.Right
---@param offsetAmount number
---@return am.ui.a.Top
function Top:init(offset, offsetAmount)
    v.expect(1, offset, "number", "nil")
    v.expect(2, offsetAmount, "number", "nil")
    if offset ~= nil then
        v.range(offset, 1, 2)
    end
    Top.super.init(self, 1, offset, offsetAmount)
    return self
end

---@class am.ui.a.Bottom:am.ui.a.Center
local Bottom = Center:extend("am.ui.a.Bottom")
a.Bottom = Bottom
---@param offset number ui.c.Offset.Left or ui.c.Offset.Right
---@param offsetAmount number
---@return am.ui.a.Bottom
function Bottom:init(offset, offsetAmount)
    v.expect(1, offset, "number", "nil")
    v.expect(2, offsetAmount, "number", "nil")
    if offset ~= nil then
        v.range(offset, 1, 2)
    end
    Bottom.super.init(self, 1, offset, offsetAmount)
    return self
end

function Bottom:getYPos(output, height)
    v.expect(1, output, "table")
    v.expect(2, height, "number")
    h.requireOutput(output)

    local _, oHeight = output.getSize()
    return oHeight - height + 1
end

--endregion

--region Left Aligned

---@class am.ui.a.Left:am.ui.a.Anchor
local Left = Anchor:extend("am.ui.a.Left")
a.Left = Left
---@param y number
---@param offsetAmount? number
---@return am.ui.a.Left
function Left:init(y, offsetAmount)
    v.expect(1, y, "number")
    v.expect(2, offsetAmount, "number", "nil")
    v.range(y, 1)
    if offsetAmount == nil then
        offsetAmount = 0
    else
        v.range(offsetAmount, 0)
    end
    Left.super.init(self, 1, y)
    self.offsetAmount = 0
    return self
end

function Left:getXPos(output, width)
    return self.x + self.offsetAmount
end

---@class am.ui.a.TopLeft:am.ui.a.Left
local TopLeft = Left:extend("am.ui.a.TopLeft")
a.TopLeft = TopLeft
---@return am.ui.a.TopLeft
---@param offsetAmount? number
function TopLeft:init(offsetAmount)
    TopLeft.super.init(self, 1, 1, offsetAmount)
    return self
end

---@class am.ui.a.BottomLeft:am.ui.a.Left
local BottomLeft = Left:extend("am.ui.a.BottomLeft")
a.BottomLeft = BottomLeft
---@param offsetAmount? number
---@return am.ui.a.BottomLeft
function BottomLeft:init(offsetAmount)
    BottomLeft.super.init(self, 1, 1, offsetAmount)
    return self
end

function BottomLeft:getYPos(output, height)
    v.expect(1, output, "table")
    v.expect(2, height, "number")
    h.requireOutput(output)

    local _, oHeight = output.getSize()
    return oHeight - height + 1
end

--endregion


--region Right Aligned

---@class am.ui.a.Right:am.ui.a.Anchor
local Right = Anchor:extend("am.ui.a.Right")
a.Right = Right
---@param y number
---@param offsetAmount? number
---@return am.ui.a.Right
function Right:init(y, offsetAmount)
    v.expect(1, y, "number")
    v.expect(2, offsetAmount, "number", "nil")
    v.range(y, 1)
    if offsetAmount == nil then
        offsetAmount = 0
    else
        v.range(offsetAmount, 0)
    end
    Right.super.init(self, 1, y)
    self.offsetAmount = offsetAmount
    return self
end

function Right:getXPos(output, width)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    h.requireOutput(output)

    local oWidth, _ = output.getSize()
    return math.max(1, oWidth - width + 1) - self.offsetAmount
end

---@class am.ui.a.TopRight:am.ui.a.Right
local TopRight = Right:extend("am.ui.a.TopRight")
a.TopRight = TopRight
---@param offsetAmount? number
---@return am.ui.a.TopRight
function TopRight:init(offsetAmount)
    TopRight.super.init(self, 1, 1, offsetAmount)
    return self
end

---@class am.ui.a.BottomRight:am.ui.a.Right
local BottomRight = Right:extend("am.ui.a.BottomRight")
a.BottomRight = BottomRight
---@param offsetAmount? number
---@return am.ui.a.BottomRight
function BottomRight:init(offsetAmount)
    BottomRight.super.init(self, offsetAmount)
    return self
end

function BottomRight:getYPos(output, height)
    v.expect(1, output, "table")
    v.expect(2, height, "number")
    h.requireOutput(output)

    local _, oHeight = output.getSize()
    return oHeight - height + 1
end

--endregion

return a
