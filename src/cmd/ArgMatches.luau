local Iter = require("@lib/Iter")
local Option = require("@lib/Option")

local Arg = require("./Arg")
local ArgAction = require("./ArgAction")

type Arg = Arg.Arg
type Iter<V> = Iter.Iter<number, V>
type MapIter<V> = Iter.Iter<string, V>
type ArgAction = ArgAction.ArgAction
type Option<T> = Option.Option<T>
--type Command = typeof(require("./Command").new(""))
type Command = any

local Some = Option.Some

--- @class ArgMatches
local ArgMatches = {}
ArgMatches.__index = ArgMatches

export type ArgMatches = typeof(setmetatable(
	{} :: {
		_app: Command,
		_args: { [string]: any },
		_globals: { [string]: any },
		_subcommand: ArgMatches?,
	},
	ArgMatches
))

function ArgMatches.new(app: Command): ArgMatches
	return setmetatable({
		_app = app,
		_args = {},
		_globals = {},
		_subcommand = nil,
	}, ArgMatches)
end

function ArgMatches._add(self: ArgMatches, arg: Arg, value: any): ArgMatches
	assert(
		arg._config.action:is(ArgAction.Count),
		"[blam]\narg._config.argAction:is(ArgAction.Count)"
	)

	if self._args[arg._config.name] == nil then
		self._args[arg._config.name] = 1
	else
		assert(
			typeof(self._args[arg._config.name]) == "number",
			'[blam]\ntypeof(self._args[arg._config.name]) == "number"'
		)
		self._args[arg._config.name] += 1
	end

	if arg._config.global then
		self._globals[arg._config.name] = self._args[arg._config.name]
	end

	return self
end

function ArgMatches._set(self: ArgMatches, arg: Arg, value: any): ArgMatches
	assert(
		arg._config.action:is(ArgAction.Set),
		"[blam]\narg._config.argAction:is(ArgAction.Set)"
	)

	self._args[arg._config.name] = value

	if arg._config.global then
		self._globals[arg._config.name] = value
	end

	return self
end

function ArgMatches._setTrue(self: ArgMatches, arg: Arg): ArgMatches
	assert(
		arg._config.action:is(ArgAction.SetTrue),
		"[blam]\narg._config.argAction:is(ArgAction.SetTrue)"
	)

	self._args[arg._config.name] = true

	if arg._config.global then
		self._globals[arg._config.name] = true
	end

	return self
end

function ArgMatches._setFalse(self: ArgMatches, arg: Arg): ArgMatches
	assert(
		arg._config.action:is(ArgAction.SetFalse),
		"[blam]\narg._config.argAction:is(ArgAction.SetFalse)"
	)

	self._args[arg._config.name] = false

	if arg._config.global then
		self._globals[arg._config.name] = false
	end

	return self
end

function ArgMatches._append(self: ArgMatches, arg: Arg, value: any): ArgMatches
	assert(
		arg._config.action:is(ArgAction.Append),
		"[blam]\narg._config.argAction:is(ArgAction.Append)"
	)

	if not self._args[arg._config.name] then
		self._args[arg._config.name] = {}
	end

	table.insert(self._args[arg._config.name], value)

	if arg._config.global then
		self._globals[arg._config.name] = self._args[arg._config.name]
	end

	return self
end

local processMap = {
	[ArgAction.Append] = ArgMatches._append,
	[ArgAction.SetTrue] = ArgMatches._setTrue,
	[ArgAction.SetFalse] = ArgMatches._setFalse,
	[ArgAction.Set] = ArgMatches._set,
	[ArgAction.Count] = ArgMatches._add,
}

function ArgMatches._process(self: ArgMatches, arg: Arg, ...)
	local processArgAction = processMap[arg._config.action]
	assert(processArgAction ~= nil, "[blam]\nprocessArgAction ~= nil")
	processArgAction(self, arg, ...)
end

function ArgMatches._addSubcommand(
	self: ArgMatches,
	subcommand: ArgMatches
): ArgMatches
	for name, value in self._globals do
		subcommand._globals[name] = value

		if subcommand._args[name] == nil then
			subcommand._args[name] = value
		end
	end

	self._subcommand = subcommand

	return self
end

function ArgMatches._verifyActionType(
	self: ArgMatches,
	id: string,
	action: ArgAction
)
	return self._app._config.args[id]._config.argAction == action
end

function ArgMatches.getOne(self: ArgMatches, id: string): Option<string>
	assert(
		self:_verifyActionType(id, ArgAction.Set),
		"[blam]\nself:_verifyActionType(id, ArgAction.Set)"
	)

	return Some(self._args[id])
end

function ArgMatches.getSubcommand(self: ArgMatches): Option<{
	matches: ArgMatches,
	name: string,
}>
	return Some(self._subcommand):map(function(subcommand: ArgMatches)
		return {
			matches = subcommand,
			name = subcommand._app._config.name,
		}
	end)
end

function ArgMatches.getCount(self: ArgMatches, id: string): number
	assert(
		self:_verifyActionType(id, ArgAction.Count),
		"[blam]\nself:_verifyActionType(id, ArgAction.Count)"
	)

	return self._args[id]
end

function ArgMatches.getFlag(self: ArgMatches, id: string): boolean
	assert(
		self:_verifyActionType(id, ArgAction.SetTrue)
			or self:_verifyActionType(id, ArgAction.SetFalse),
		"[blam]\n\t\tself:_verifyActionType(id, ArgAction.SetTrue)"
			.. "\n\t\t\tor self:_verifyActionType(id, ArgAction.SetFalse)\n"
	)

	return self._args[id] == true
end

function ArgMatches.getMany(self: ArgMatches, id: string): Option<Iter<string>>
	assert(
		self:_verifyActionType(id, ArgAction.Append),
		"[blam]\nself:_verifyActionType(id, ArgAction.Append)"
	)

	return Some(self._args[id]):map(function(args)
		local result = Iter.new(args)
			:fold({}, function(result, _, occurrence: { string })
				for _, value in occurrence do
					table.insert(result, value)
				end

				return result
			end)

		return Iter.new(result)
	end)
end

function ArgMatches.getOccurrences(
	self: ArgMatches,
	id: string
): Option<Iter<Iter<string>>>
	assert(
		self:_verifyActionType(id, ArgAction.Append),
		"[blam]\nself:_verifyActionType(id, ArgAction.Append)"
	)

	return Some(self._args[id]):map(function(args): any
		return Iter.new(args):map(function(_, occurrence)
			return Iter.new(occurrence)
		end)
	end)
end

function ArgMatches.containsId(self: ArgMatches, id: string): boolean
	return (self._args[id] :: any) ~= nil
end

function ArgMatches.ids(self: ArgMatches): MapIter<unknown>
	return Iter.new(self._args)
end

function ArgMatches.argsPresent(self: ArgMatches)
	return next(self._args) ~= nil
end

return ArgMatches
