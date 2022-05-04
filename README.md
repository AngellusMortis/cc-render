# Another Rendering Library

After trying to use a few other exist rendering libraries (bugs, bad readability, etc.), I was not satisfied with what was out there and decided to make my own.

Some things that makes my library stand out a bit:

* Unminified source has full [Lua language server](https://github.com/sumneko/lua-language-server) type annotation support. Works great in VS Code!
* Full OOP
* Virtual screens/outputs (Frames)
* Positional anchoring

----

## Table of Contents

* [Install](#install)
* [Examples](#examples)
* [Quick Start](#quick-start)
* [Binding](#binding)
* [Helpers](#helpers)
  * [Screen](#screen)
  * [UILoop](#uiloop)
* [Elements](#elements)
  * [Anchors](#anchors)
  * [Events](#events)
  * [Frames](#frames)
  * [Text](#text)
  * [Button](#button)
  * [Progress Bar](#progress-bar)

----

## Install

This library uses [cc-updater](https://github.com/AngellusMortis/cc-updater), but that is automatically installed as part of installing this so there are no extra steps needed.

Run the following command in your computer:

```bash
wget run https://raw.githubusercontent.com/AngellusMortis/cc-updater/master/install.lua
```

You can disable autoupdating on computer boot by removing the `startup.lua` that was downloaded and running the following command:

```bash
/ghu/core/programs/ghuconf set autoUpdate false
```

[Go to top](#another-rendering-library)

## Examples

You can find some examples using the rendering library in the [/example folder](https://github.com/AngellusMortis/cc-render/tree/master/example/programs). You can also install these examples on your computer with the following command:

```bash
wget run https://raw.githubusercontent.com/AngellusMortis/cc-render/master/installExamples.lua
```

[Go to top](#another-rendering-library)

## Quick Start

The main file for the project should be pretty well documented, so for anything missing from this readme, check out [that file for more](https://github.com/AngellusMortis/cc-render/blob/master/src/apis/am/ui.lua).

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

uiLoop = ui.UILoop()
screen = ui.Screen(term, {textColor=colors.white, backgroundColor=colors.black})
screen:add(ui.Text(ui.a.Top(), "Title", {id="titleText"})
exitButton = ui.Button(ui.a.Bottom(), "Exit", {fillColor=colors.red})
exitButton:addActivateHandler(function()
    uiLoop:cancel()
end)
screen:add(exitButton)

function runUILoop()
    uiLoop:run(screen)
end

function main()
    -- do stuff
    -- update title
    title = screen:get("titleText")
    title:update("New Title")
end

parallel.waitForAll(runUILoop, main)
```

[Go to top](#another-rendering-library)

## Binding

A UI Object is not directly bound to a computer screen. This makes it easier to move the UI object to another screen in the event of a redirect or just wanting to move it. You can bind a UI Object to an output for rendering. The `Screen` helper allows you to never have to really worry about binding and it essentially just becomes an "under the hood" thing.

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

text = ui.Text(ui.a.Top(), "Title", {id="titleText"}

-- manual binding
boundText = text:bind(term)
boundText:render()

-- using screen
screen = ui.Screen(term)
screen:add(text)
screen:render()
```

[Go to top](#another-rendering-library)

## Helpers

### Screen

Whenever you render a UI object, you need to provide the parent output or Frame to render it to. Since this can be very tedious when dealing with multiple monitors and Frames, the `.Screen` helper exists. You bind the top level output to the Screen and then add the child UI objects to the Screen to handle rendering.

Any more advanced rendering should always use a top level Screen object to handle rendering. Especially when you start using Frames to section off parts of the physical screen.

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

screen = ui.Screen(term, {textColor=colors.white, backgroundColor=colors.black})
screen:add(ui.Text(ui.a.Top(), "Title")
screen:render()
```

[Go to top](#another-rendering-library)

### UILoop

`.UILoop` is a helper to handle rendering UI elements and automatically handling all of the events needed to update the UI for you. It should be ran in the background with [parallel](https://tweaked.cc/module/peripheral.html)

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

uiLoop = ui.UILoop()
screen = ui.Screen(term, {textColor=colors.white, backgroundColor=colors.black})
-- other UI init

function runUILoop()
    uiLoop:run(screen)
end

function main()
    -- non-UI stuff
end

parallel.waitForAll(runUILoop, main)
```

[Go to top](#another-rendering-library)

## Elements

### Anchors

Rather then rendering text, buttons, etc. to specific coords on a computer screen, Anchors are used instead. Usually we do not want to render a button at a specific location, but rather "the bottom of the screen" or the "top right corner". If you do still want a specific coordinate, you can use the base `Anchor` which allows for absolute positioning.

Any of the anchors that let you anchor something to middle of a line also lets you offset that anchor by a specific amount to either the left or right. `offsetDir` is either the value of `.c.Offset.Left` or `.c.Offset.Right` with the value of `offsetAmount` to indicate how much to offset it by.

Available anchors (all anchors are relative to the `require` import):

* `.a.Anchor(x, y)` - Base anchor. Absolute position
* `.a.Left(y)` - Anchors object to left side of screen at specified y position
* `.a.Right(y)` - Anchors object to right side of screen at specified y position
* `.a.Center(y, offsetDir, offsetAmount)` - Anchors object to center of screen at specified y position
* `.a.Middle()` - Anchors object to center of screen
* `.a.Top(offsetDir, offsetAmount)` - Anchors object to center of the first line of the screen
* `.a.Bottom(offsetDir, offsetAmount)` - Anchors object to center of the last line of the screen
* `.a.TopLeft()` - Anchors object to top left corner of a screen (1, 1)
* `.a.TopLeft()` - Anchors object to top right corner of a screen
* `.a.BottomLeft()` - Anchors object to bottom left corner of a screen
* `.a.BottomRight()` - Anchors object to bottom right corner of a screen

[Go to top](#another-rendering-library)

### Events

All events fired by UI objects are pretty consistent. All of the event names are prefixed with `ui.` and they only ever have a single argument: a table with the data encoded into it.

Every UI event has the following event data:

* `.objId` - the ID of the frame the event if for
* `.outputType` - the type of output the frame was rendered on (`term`, `monitor` or `frame`)
* `.outputId` - the ID of the output so you can get a reference to it
  * `nil` for term

[Go to top](#another-rendering-library)

### Frames

All of the more complex items in the library uses Frames, which is essentially a rectangle that gets rendered and allows for a "virtual" computer screen to render children items inside of. For example, a button is a Frame with a Text element Anchored inside (defaults to rendering in the middle of the button Frame.

The most generic usage of the a `.Frame` is just to use to render plain rectangle:

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

-- makes a blue rectangle with no border at (3, 4) on the terminal with the width of 5 and height or 3
frame = ui.Frame(ui.a.Anchor(3, 4), {width=5, height=3, fillColor=colors.blue, border=0})
frame:render(term)
```

However, all of the more complex items in the library uses Frames and they allow you create a "virtual" to let you render things to.

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

width, height = term.getSize()
-- will make a blue rectangle on the right half of the terminal
frame = ui.Frame(ui.a.TopRight(), {width=math.floor(width / 2), height=height, fillColor=colors.blue, textColor=colors.green, border=0})
frame:render(term)

output = frame:makeScreen(term)
width, height = output.getSize()
output.setCursorPos(3, height)

-- writes "Test" to (3, frameHeight) within the Frame
--  which actually becomes (width + 3, height)
output.write("Test")
```

#### Frame Events

Frames also provides click events to mirror the ones for monitors and terminals.

##### Frame Event Data

In addition to the above event data, Frame events also have the following data:

* `.x` - x coord for event (can be 0 or negative if frame has padding or border)
* `.y` - y coord for the event (can be 0 or negative if frame has padding or border)

##### List of Events

* `ui.frame_touch` - Fired when a frame is touched (monitor only)
* `ui.frame_click` - Fired when there is a mouse clicked (terminal only)
  * Has additional data value of `.clickType` for the [mouse button](https://tweaked.cc/event/mouse_click.html)
* `ui.frame_up` - Fired when the a mouse button is released
  * Has additional data value of `.clickType` for the [mouse button](https://tweaked.cc/event/mouse_click.html)

##### Frame Example

Handling events can be completed if you have multiple outputs/monitors. So it is recommended you use a `Screen` object to handle all of the nested outputs and such. `Frame` does not handle anything to determine if output for the raw computer event is the correct output.

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

screen = ui.Screen(term)
screen:add(ui.Frame(ui.a.TopRight(), {width=math.floor(width / 2), height=height, fillColor=colors.blue, textColor=colors.green, border=0}))

while true do
    -- Will fire a Frame click/up event if there is a
    -- `mouse_` event on the right half of the screen
    screen:handle(os.pullEvent())
end
```

[Go to top](#another-rendering-library)

### Text

Text objects allow you to anchor text on the screen. Text objects also support some basic color encoding to let you change the color dynamically based on the "alert level" of the message you are displaying. Great for status lines and such. The encoding is based on [Bootstrap alerts](https://getbootstrap.com/docs/5.0/components/alerts/) and work by adding the alert level as a prefix before the text.

* `error:` will make the text `colors.red`
* `warning:` will make the text `colors.yellow`
* `success:` will make the text `colors.green`
* `info:` will make the text `colors.blue`

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

text = ui.Text(ui.a.Middle(), "Test")
text:render(term)
```

[Go to top](#another-rendering-library)

### Button

Buttons are frames that can be activated and have a Text object inside of them.

#### Button Events

* `ui.button_activate` - Fires when a button is activated
  * Has additional data value of `.touch` for if activation was from a touch event
* `ui.button_deactivate` - Fires when a button is deactivated (eventData = table with `.objId`)

#### Event Handlers

If you are using a `ui.Screen` or `ui.UILoop` there is also a way to automatically handle the events for you. You can call `addActivateHandler` with your a function for to handle a button click.

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

screen = ui.Screen(term)
screen:add(ui.Frame(ui.a.TopRight(), {width=math.floor(width / 2), height=height, fillColor=colors.blue, textColor=colors.green, border=0}))

exitButton = ui.Button(ui.a.Bottom(), "Test")
exitButton:addActivateHandler(function(button, output, event)
    -- button clicked!
end)

while true do
    -- Will fire a Frame click/up event if there is a
    -- `mouse_` event on the right half of the screen
    screen:handle(os.pullEvent())
end
```

[Go to top](#another-rendering-library)

### Progress Bar

```lua
require(settings.get("ghu.base") .. "core/apis/ghu")
ui = require("am.ui")

bar = ui.ProgressBar(ui.a.TopLeft(), "Test")
bar = bar:bind(term)
-- renders bar at 0%
bar:render()
-- renders bar at 50%
bar:update(50)
bar:render()
```

[Go to top](#another-rendering-library)
