local Result = require("@lib/Result")

local Error = require("./Error")
local ValueParser = require("./ValueParser")

type Result<T, E> = Result.Result<T, E>
type Error = Error.Error

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

local function isA(value: any)
	return typeof(value) == "table" and getmetatable(value) == ArgAction
end

local function deserialize(self: any, action: string)
	return self[action]
end

function ArgAction.serialize(action: ArgAction)
	return action.type
end

function ArgAction.__tostring(self: ArgAction)
	return `ArgAction<{self.type}>`
end

-- avoiding "can't compare ArgAction with ArgAction" type error
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

	Set = new({
		type = "Set",
		takesValues = true,
	}),
	Append = new({
		type = "Append",
		takesValues = true,
	}),
	SetTrue = new({
		type = "SetTrue",
		defaultValue = "false",
		defaultMissingValue = "true",
		defaultValueParser = ValueParser.bool,
	}),
	SetFalse = new({
		type = "SetFalse",
		defaultValue = "true",
		defaultMissingValue = "false",
		defaultValueParser = ValueParser.bool,
	}),
	Count = new({
		type = "Count",
		defaultValue = "0",
		defaultValueParser = ValueParser.number,
	}),
	--	HelpShort
	--	HelpLong
	Help = new({
		type = "Help",
	}),
	Version = new({
		type = "Version",
	}),
}
