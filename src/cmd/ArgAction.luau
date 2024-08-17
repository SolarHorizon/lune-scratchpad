local Result = require("@lib/Result")

local Error = require("./Error")
local ValueParser = require("./ValueParser")

type Result<T, E> = Result.Result<T, E>
type Error = Error.Error

--- @class ArgAction
local ArgAction = {}
ArgAction.__index = ArgAction

type Parameters = {
	type: string,
	takesValues: boolean?,
	defaultValue: string?,
	defaultMissingValue: string?,
	defaultValueParser: ((value: string) -> Result<any, Error>)?,
}

export type ArgAction = typeof(setmetatable({} :: Parameters, ArgAction))

local function new(params: Parameters): ArgAction
	return setmetatable(params, ArgAction)
end

--- @within ArgAction
--- Checks if a value is an ArgAction
local function isA(value: any)
	return typeof(value) == "table" and getmetatable(value) == ArgAction
end

--- @within ArgAction
--- Deserializes an ArgAction
local function deserialize(self: any, action: string)
	return self[action]
end

--- @within ArgAction
--- Serializes an ArgAction
function ArgAction.serialize(_self: ArgAction, action: ArgAction)
	return action.type
end

function ArgAction.__tostring(self: ArgAction)
	return `ArgAction<{self.type}>`
end

--- @within ArgAction
--- Checks whether or not any of the given `ArgAction`s are equal to this one.
---
--- ```luau
--- action:is(ArgAction.Set, ArgAction.Count)
--- ```
---
--- :::tip
--- This is no different from using `==`, and exists as a workaround for strict Luau types
--- not working well when comparing a value with a metatable.
--- :::
function ArgAction.is(self: ArgAction, ...): boolean
	for i = 1, select("#", ...) do
		if self == select(i, ...) then
			return true
		end
	end

	return false
end

return {
	isA = isA,
	deserialize = deserialize,
	serialize = ArgAction.serialize,

	--- @within ArgAction
	--- @prop Set ArgAction
	---
	--- When encountered, stores the associated value(s) in `ArgMatches`
	---
	--- ## Example
	--- ```luau
	---	local cmd = Command.new("mycmd")
	---		:arg("flag")
	---		:long()
	---		:action(ArgAction.Set)
	---
	---	local matches = cmd:getMatchesFrom({ "mycmd", "--flag", "value" })
	---	print(matches:containsId("flag")) -- true
	---	print(matches:getOne("flag"):unwrap()) -- "value"
	--- ```
	Set = new({
		type = "Set",
		takesValues = true,
	}),

	--- @within ArgAction
	--- @prop Append ArgAction
	---
	--- When encountered, stores the associated value(s) in `ArgMatches`
	---
	--- ## Example
	--- ```luau
	---	local cmd = Command.new("mycmd")
	---		:arg("flag")
	---		:long()
	---		:action(ArgAction.Append)
	---
	---	local matches = cmd:getMatchesFrom({ "mycmd", "--flag", "value1", "--flag", "value2" })
	---	print(matches:containsId("flag")) -- true
	---
	---	local flag = matches:getOne("flag"):unwrap()
	---
	---	print(typeof(flag) == "table") -- true
	---	print(flag) -- { "value1", "value2" }
	--- ```
	Append = new({
		type = "Append",
		takesValues = true,
	}),

	--- @within ArgAction
	--- @prop SetTrue ArgAction
	---
	--- When encountered, act as if "true" was encountered on the command line.
	--- If no `defaultValue` is set, it will be `false`.
	--- No value is allowed.
	---
	--- ## Example
	--- ```luau
	---	local cmd = Command.new("mycmd")
	---		:arg("flag")
	---		:long()
	---		:action(ArgAction.SetTrue)
	---
	---	local matches = cmd:getMatchesFrom({ "mycmd", "--flag" })
	---	print(matches:containsId("flag")) -- true
	---	print(matches:getOne("flag"):unwrap()) -- true
	--- ```
	SetTrue = new({
		type = "SetTrue",
		defaultValue = "false",
		defaultMissingValue = "true",
		defaultValueParser = ValueParser.bool,
	}),

	--- @within ArgAction
	--- @prop SetFalse ArgAction
	---
	--- When encountered, act as if "false" was encountered on the command line.
	--- If no `defaultValue` is set, it will be `true`.
	--- No value is allowed.
	---
	--- ## Example
	--- ```luau
	---	local cmd = Command.new("mycmd")
	---		:arg("flag")
	---		:long()
	---		:action(ArgAction.SetFalse)
	---
	---	local matches = cmd:getMatchesFrom({ "mycmd", "--flag" })
	---	print(matches:containsId("flag")) -- true
	---	print(matches:getOne("flag"):unwrap()) -- false
	--- ```
	SetFalse = new({
		type = "SetFalse",
		defaultValue = "true",
		defaultMissingValue = "false",
		defaultValueParser = ValueParser.bool,
	}),

	--- @within ArgAction
	--- @prop Count ArgAction
	---
	--- When encountered, increments a counter starting from 0.
	--- If no `defaultValue` is set, it will be 0.
	--- No value is allowed.
	---
	--- ## Example
	--- ```luau
	---	local cmd = Command.new("mycmd")
	---		:arg("flag")
	---		:long()
	---		:action(ArgAction.Count)
	---
	---	local matches = cmd:getMatchesFrom({ "mycmd", "--flag", "--flag", "--flag" })
	---	print(matches:containsId("flag")) -- true
	---	print(matches:getOne("flag"):unwrap()) -- 3
	--- ```
	Count = new({
		type = "Count",
		defaultValue = "0",
		defaultValueParser = ValueParser.number,
	}),

	--- @within ArgAction
	--- @prop Help ArgAction
	---
	--- When encountered, display help information.
	---
	--- ## Example
	--- ```luau
	---	local cmd = Command.new("mycmd")
	---		:arg("flag")
	---		:long()
	---		:action(ArgAction.Count)
	---
	---	local matches = cmd:getMatchesFrom({ "mycmd", "--help" })
	---	print(matches:unwrapErr()) -- Error.DisplayHelp
	Help = new({
		type = "Help",
	}),

	--- @within ArgAction
	--- @prop Version ArgAction
	---
	--- When encountered, display version information.
	---
	--- ## Example
	--- ```luau
	---	local cmd = Command.new("mycmd")
	---		:arg("flag")
	---		:long()
	---		:action(ArgAction.Count)
	---
	---	local matches = cmd:getMatchesFrom({ "mycmd", "--version" })
	---	print(matches:unwrapErr()) -- Error.DisplayVersion
	Version = new({
		type = "Version",
	}),

	--	HelpShort
	--	HelpLong
}
