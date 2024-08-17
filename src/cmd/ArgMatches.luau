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
		_parent: ArgMatches?,
		_subcommand: ArgMatches?,
	},
	ArgMatches
))

function ArgMatches.new(app: Command): ArgMatches
	return setmetatable({
		_app = app,
		_args = {},
		_globals = {},
		_parent = nil,
		_subcommand = nil,
	}, ArgMatches)
end

function ArgMatches._add(self: ArgMatches, arg: Arg, _value: never): ArgMatches
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

	-- TODO: multiple arguments
	table.insert(self._args[arg._config.name], { value })

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

	if self._parent and arg._config.global then
		processArgAction(self._parent, arg)
	end
end

function ArgMatches._setParent(self: ArgMatches, parent: ArgMatches): ArgMatches
	parent._subcommand = self
	self._parent = parent

	for name, value in self._globals do
		self._globals[name] = value

		if self._args[name] == nil then
			self._args[name] = value
		end
	end

	return self
end

function ArgMatches._verifyActionType(
	self: ArgMatches,
	id: string,
	...: ArgAction
): boolean
	local arg = self._app._config.args[id]

	if not arg then
		return false
	end

	return self._app._config.args[id]._config.action:is(...)
end

function ArgMatches._assertActionType(
	self: ArgMatches,
	id: string,
	...: ArgAction
)
	if not self:_verifyActionType(id, ...) then
		assert(self._app._config.args[id], `Invalid Arg id '{id}'`)

		local actionType = tostring(self._app._config.args[id]._config.action)

		local message =
			`\nUnexpected ArgAction for '{id}': {actionType}.\nExpected one of the following:$@`

		for i = 1, select("#", ...) do
			message =
				string.gsub(message, "$@", "\n\t- " .. tostring(select(i, ...)))
		end

		message = string.gsub(message, "$@", "")

		error(message)
	end
end

--- Get the value of the specified `ArgAction.Set` argument.
function ArgMatches.getOne(self: ArgMatches, id: string): Option<string>
	self:_assertActionType(id, ArgAction.Set)
	return Some(self._args[id])
end

--- Get the subcommand, if there is one. Returns an `Option`.
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

--- Get the value of the specified `ArgAction.Count` argument.
function ArgMatches.getCount(self: ArgMatches, id: string): number
	self:_assertActionType(id, ArgAction.Count)
	return self._args[id]
end

--- Get the value of the specified `ArgAction.SetTrue` or `ArgAction.SetFalse` argument.
function ArgMatches.getFlag(self: ArgMatches, id: string): boolean
	self:_assertActionType(id, ArgAction.SetTrue, ArgAction.SetFalse)
	return self._args[id] == true
end

--- Get all of the values for the specified `ArgAction.Append` argument.
function ArgMatches.getMany(self: ArgMatches, id: string): Option<Iter<string>>
	self:_assertActionType(id, ArgAction.Append)

	return Some(self._args[id]):map(function(args)
		local matches = Iter.new(args)
			:fold({}, function(result, _, occurrence: { string })
				for _, value in occurrence do
					table.insert(result, value)
				end

				return result
			end)

		return Iter.new(matches)
	end)
end

--- Get the values of the specified `ArgAction.Append` argument.
---
--- This is different from `getMany` in that it will group each occurrence of the argument into its own array.
---
--- :::tip
--- This is method isn't very useful yet because we do not currently support delimiters or termination
--- for `ArgAction.Append`.
--- :::
function ArgMatches.getOccurrences(
	self: ArgMatches,
	id: string
): Option<Iter<Iter<string>>>
	self:_assertActionType(id, ArgAction.Append)

	return Some(self._args[id]):map(function(args): any
		return Iter.new(args):map(function(_, occurrence)
			return Iter.new(occurrence)
		end)
	end)
end

--- Check whether or not the given argument exists.
function ArgMatches.containsId(self: ArgMatches, id: string): boolean
	return self._args[id] ~= nil
end

--- Returns an iterator over all of the matched arguments.
function ArgMatches.ids(self: ArgMatches): MapIter<unknown>
	return Iter.new(self._args)
end

--- Check whether or not any arguments were matched.
function ArgMatches.argsPresent(self: ArgMatches)
	return next(self._args) ~= nil
end

return ArgMatches
