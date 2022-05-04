require(settings.get("ghu.base") .. "core/apis/ghu")

local ui = require("am.ui")
local s = ui.Screen(term, {textColor=colors.white, backgroundColor=colors.black})

local width, height = term.getSize()

local function progressDemo(progress)
    s:add(ui.ProgressBar(ui.a.TopLeft(), {label=" Test", current=progress}))
    s:add(ui.ProgressBar(
        ui.a.Anchor(10, 4), {current=progress, progressColor=colors.blue, fillColor=colors.lightGray}
    ))
    s:add(ui.ProgressBar(
        ui.a.Anchor(1, 7), {current=progress, width=math.floor(width/2), fillHorizontal=false}
    ))
    s:add(ui.ProgressBar(
        ui.a.Left(10), {
            labelAnchor=ui.a.Middle(),
            current=progress,
            progressTextColor=colors.black,
            progressVertical=true
        }
    ))
    s:render()
    s:reset()
    sleep(2)
end

progressDemo(0)
progressDemo(10)
progressDemo(25)
progressDemo(50)
progressDemo(80)
progressDemo(100)
