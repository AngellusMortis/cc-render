require(settings.get("ghu.base") .. "core/apis/ghu")

local ui = require("am.ui")
local s = ui.Screen(term, {textColor=colors.white, backgroundColor=colors.black})

local width, _ = term.getSize()

local function progressDemo(progress)
    local percent = progress / 100

    s:add(ui.ProgressBar(ui.a.TopLeft(), {label=" Test", current=progress}))
    local pb1 = ui.ProgressBar(
        ui.a.Anchor(10, 4), {progressColor=colors.blue, fillColor=colors.lightGray}
    )
    pb1:update(term, progress)
    s:add(pb1)
    local pb2 = ui.ProgressBar(
        ui.a.Anchor(1, 7), {width=math.floor(width/2), fillHorizontal=false, total=1, displayTotal=50}
    )
    pb2:update(term, percent)
    s:add(pb2)
    local pb3 = ui.ProgressBar(
        ui.a.Left(10), {
            labelAnchor=ui.a.Middle(),
            progressTextColor=colors.black,
            progressVertical=true
        }
    )
    pb3:update(term, progress)
    s:add(pb3)
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
