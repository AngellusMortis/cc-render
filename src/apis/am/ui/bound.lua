
local b = require("am.ui.base")

local bound = {}

---@class am.ui.BoundGroup:am.ui.b.UIBoundObject
---@field obj am.ui.Group
local BoundGroup = b.UIBoundObject:extend("am.ui.BoundGroup")
bound.BoundGroup = BoundGroup

---Add UI obj to Group
---@param obj am.ui.b.UIObject
function BoundGroup:add(obj)
    self.obj:add(obj)
end

---Recursively searches for UI Obj by id
---@param id string
---@return am.ui.b.UIObject?, table
function BoundGroup:get(id)
    return self.obj:get(id, self.output)
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

---@class am.ui.BoundText:am.ui.b.UIBoundObject
---@field obj am.ui.Text
local BoundText = b.UIBoundObject:extend("am.ui.BoundText")
bound.BoundText = BoundText

---Updates label text
---@param label string
function BoundText:update(label)
    self.obj:update(self.output, label)
end


---@class am.ui.BoundFrame:am.ui.BoundGroup
---@field obj am.ui.Frame
local BoundFrame = BoundGroup:extend("am.ui.BoundFrame")
bound.BoundFrame = BoundFrame

---Gets background color for Frame
---@returns number
function BoundFrame:getBackgroundColor()
    return self.obj:getBackgroundColor(self.output)
end

---Gets fill color for Frame
---@returns number
function BoundFrame:getFillColor()
    return self.obj:getFillColor(self.output)
end

---Gets border color for Frame
---@returns number
function BoundFrame:getBorderColor()
    return self.obj:getBorderColor(self.output)
end

---Gets text color for Frame
---@returns number
function BoundFrame:getTextColor()
    return self.obj:getTextColor(self.output)
end

---Gets width for the Frame without auto filling
---@returns number
function BoundFrame:getBaseWidth()
    return self.obj:getBaseWidth()
end

---Gets width for the Frame
---@param startX? number
function BoundFrame:getWidth(startX)
    return self.obj:getWidth(self.output, startX)
end

---Gets height for the Frame without auto filling
---@returns number
function BoundFrame:getBaseHeight()
    return self.obj:getBaseHeight()
end

---Gets height for the Frame
---@param startY? number
---@returns number
function BoundFrame:getHeight(startY)
    return self.obj:getHeight(self.output, startY)
end

---Makes CC compatible FrameScreen for Frame
---@param pos? am.ui.b.ScreenPos
---@param width? number
---@param height? number
---@param doPadding? boolean
---@return am.ui.FrameScreenCompat
function BoundFrame:makeScreen(pos, width, height, doPadding)
    return self.obj:makeScreen(self.output, pos, width, height, doPadding)
end

---Checks if coords on phyiscal CC screen is is within Frame
---@param x number
---@param y number
---@return boolean
function BoundFrame:within(x, y)
    return self.obj:within(self.output, x, y)
end


---@class am.ui.BoundButton:am.ui.BoundFrame
---@field obj am.ui.Button
local BoundButton = BoundFrame:extend("am.ui.BoundButton")
bound.BoundButton = BoundButton

---Updates label text
---@param label string
function BoundButton:updateLabel(label)
    self.obj:updateLabel(self.output, label)
end

---Activates the button
---@param touch? boolean
function BoundButton:activate(touch)
    self.obj:activate(self.output, touch)
end

---Deactivates the button
function BoundButton:deactivate()
    self.obj:deactivate(self.output)
end

---Adds event handler for when button is acitvated
---@param handler fun(button:am.ui.Button, output:table, event:am.ui.e.ButtonActivateEvent)
---@return fun() Unsubcribe method
function BoundButton:addActivateHandler(handler)
    return self.obj:addActivateHandler(handler)
end

---Handler for when button is activated
---Should not be overriden, use `addActivateHandler` instead
---@param event am.ui.e.ButtonActivateEvent
function BoundButton:onActivate(event)
    self.obj:onActivate(self.output, event)
end

---Handler for when button is deactivated
---@param event am.ui.e.ButtonDeactivateEvent
function BoundButton:onDeactivate(event)
    self.obj:onDeactivate(self.output, event)
end

---Handler for when button is touched
---@param event am.ui.e.FrameTouchEvent
function BoundButton:onTouch(event)
    self.obj:onTouch(self.output, event)
end

---Handler for when button is clicked
---@param event am.ui.e.FrameClickEvent
function BoundButton:onClick(event)
    self.obj:onClick(self.output, event)
end

---Handler for when frame click is depressed
---@param event am.ui.e.FrameDeactivateEvent
function BoundButton:onUp(event)
    self.obj:onUp(self.output, event)
end

---@class am.ui.BoundProgressBar:am.ui.BoundFrame
---@field obj am.ui.ProgressBar
local BoundProgressBar = BoundFrame:extend("am.ui.BoundGroup")
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

return bound
