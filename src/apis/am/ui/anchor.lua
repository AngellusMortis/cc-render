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

---@class am.ui.a.Left:am.ui.a.Anchor
local Left = Anchor:extend("am.ui.a.Left")
a.Left = Left
function Left:init(y)
    v.expect(1, y, "number")
    v.range(y, 1)
    Left.super.init(self, 1, y)
    return self
end

---@class am.ui.a.Right:am.ui.a.Anchor
local Right = Anchor:extend("am.ui.a.Right")
a.Right = Right
function Right:init(y)
    v.expect(1, y, "number")
    v.range(y, 1)
    Right.super.init(self, 1, y)
    return self
end

function Right:getXPos(output, width)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    h.requireOutput(output)

    local oWidth, _ = output.getSize()
    return math.max(1, oWidth - width + 1)
end

---@class am.ui.a.Center:am.ui.a.Anchor
---@field offset number
---@field offsetAmount number
local Center = Anchor:extend("am.ui.a.Center")
a.Center = Center
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
    return math.max(1, math.floor(center) + 1)
end

---@class am.ui.a.Middle:am.ui.a.Center
local Middle = Center:extend("am.ui.a.Middle")
a.Middle = Middle
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

---@class am.ui.a.TopLeft:am.ui.a.Anchor
local TopLeft = Anchor:extend("am.ui.a.TopLeft")
a.TopLeft = TopLeft
function TopLeft:init()
    TopLeft.super.init(self, 1, 1)
    return self
end

---@class am.ui.a.TopRight:am.ui.a.Right
local TopRight = Right:extend("am.ui.a.TopRight")
a.TopRight = TopRight
function TopRight:init()
    TopRight.super.init(self, 1, 1)
    return self
end

---@class am.ui.a.BottomLeft:am.ui.a.Anchor
local BottomLeft = Anchor:extend("am.ui.a.BottomLeft")
a.BottomLeft = BottomLeft
function BottomLeft:init()
    BottomLeft.super.init(self, 1, 1)
    return self
end

function BottomLeft:getYPos(output, height)
    v.expect(1, output, "table")
    v.expect(2, height, "number")
    h.requireOutput(output)

    local _, oHeight = output.getSize()
    return oHeight - height + 1
end

---@class am.ui.a.BottomRight:am.ui.a.BottomLeft
local BottomRight = BottomLeft:extend("am.ui.a.BottomRight")
a.BottomRight = BottomRight
function BottomRight:init()
    BottomRight.super.init(self)
    return self
end

function BottomRight:getXPos(output, width)
    v.expect(1, output, "table")
    v.expect(2, width, "number")
    h.requireOutput(output)

    local oWidth, _ = output.getSize()
    return oWidth - width
end

return a
