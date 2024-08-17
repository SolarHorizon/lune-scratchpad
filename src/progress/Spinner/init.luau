local animations = require("./animations")
local immutable = require("@lib/immutable")
local stdio = require("@lune/stdio")
local task = require("@lune/task")
local term = require("@lib/term")

type SpinnerOptions = {
	animation: animations.SpinnerAnimation?,
	color: stdio.Color?,
	style: stdio.Style?,
	text: string?,
}

type SpinnerImpl = {
	__index: SpinnerImpl,
	new: (options: SpinnerOptions?) -> Spinner,
	start: (Spinner) -> (),
	stop: (Spinner) -> (),
	complete: (Spinner, string) -> (),
	fail: (Spinner, string) -> (),
}

type Spinner = typeof(setmetatable(
	{} :: {
		_frame: number,
		spinning: boolean,
		_thread: thread?,
		animation: animations.SpinnerAnimation,
		color: stdio.Color,
		style: stdio.Style,
		text: string,
	},
	{} :: SpinnerImpl
))

local Spinner = {} :: SpinnerImpl
Spinner.__index = Spinner

function Spinner.new(options: SpinnerOptions?)
	local self = immutable.merge({
		text = "",
		color = "blue",
		style = "bold",
		animation = animations.dots,
		_frame = 1,
		spinning = false,
		_thread = nil,
	}, options or {})

	return setmetatable(self, Spinner)
end

function Spinner:start()
	if self._thread then
		return
	end

	self._frame = 1

	self._thread = task.spawn(function()
		while true do
			if self._frame > #self.animation.frames then
				self._frame = 1
			end

			stdio.write(
				term.clear
					.. stdio.style(self.style)
					.. stdio.color(self.color)
					.. self.animation.frames[self._frame]
					.. stdio.style("reset")
					.. stdio.color("reset")
					.. " "
					.. self.text
			)

			self._frame += 1

			task.wait(self.animation.interval)
		end
	end)
end

function Spinner:stop()
	if not self._thread then
		return
	end

	task.cancel(self._thread)
	term.clearLine()

	self._thread = nil
end

-- these are soooo stupid but i'm so tired
function Spinner:complete(text: string)
	self:stop()
	print(`{term.color.green("✔")} {text}`)
end

function Spinner:fail(text: string)
	self:stop()
	print(`{term.color.red("✘")} {text}`)
end

return {
	new = Spinner.new,
	animations = animations,
}
