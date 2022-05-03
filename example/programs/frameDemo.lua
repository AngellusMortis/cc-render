local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")

local ui = require("am.ui")
s = ui.Screen(term, {textColor=colors.white, backgroundColor=colors.black})

function createFrame(anchor, border, padding, width, height)
    local frame = ui.Frame(anchor, {border=border, fillColor=colors.lightGray, width=width, height=height, padLeft=padding})
    frame:add(ui.Text(ui.a.Middle(), "T"))

    return frame
end

function frameDemo(border, padding, offset, width, height)
    if offset == nil then
        offset = 1
    end
    if padding == nil then
        padding = 0
    end
    s:add(createFrame(ui.a.Anchor(12, 6), border, padding, width, height))
    s:add(createFrame(ui.a.Left(6), border, padding, width, height))
    s:add(createFrame(ui.a.Right(6), border, padding, width, height))
    s:add(createFrame(ui.a.Center(13), border, padding, width, height))
    s:add(createFrame(ui.a.Center(13, ui.c.Offset.Left, offset), border, padding, width, height))
    s:add(createFrame(ui.a.Center(13, ui.c.Offset.Right, offset), border, padding, width, height))
    s:add(createFrame(ui.a.Middle(), border, padding, width, height))
    s:add(createFrame(ui.a.Top(), border, padding, width, height))
    s:add(createFrame(ui.a.TopLeft(), border, padding, width, height))
    s:add(createFrame(ui.a.TopRight(), border, padding, width, height))
    s:add(createFrame(ui.a.Bottom(), border, padding, width, height))
    s:add(createFrame(ui.a.BottomLeft(), border, padding, width, height))
    s:add(createFrame(ui.a.BottomRight(), border, padding, width, height))
    s:render()
    s:reset()
    sleep(2)
end

frameDemo(0)
frameDemo(1)
frameDemo(2)
frameDemo(3)
frameDemo(0, 1, 2)
frameDemo(1, 1, 2)
frameDemo(2, 1, 2)
frameDemo(3, 1, 2)
frameDemo(0, 2, 3)
frameDemo(1, 2, 3)
frameDemo(2, 2, 3)
frameDemo(3, 2, 3)
frameDemo(0, 0, 3, 7, 5)
frameDemo(1, 0, 3, 7, 5)
frameDemo(2, 0, 3, 7, 5)
frameDemo(3, 0, 3, 7, 5)
