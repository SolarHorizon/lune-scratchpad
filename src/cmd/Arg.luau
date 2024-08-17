-- TODO: required*, conflicts*, exclusive, overrides*, requires*,
-- value*, possible_value(s), group(s), number_of_values, validator*
-- max/min_values, default*, display_order, last
local ArgAction = require("./ArgAction")

type ArgAction = ArgAction.ArgAction

--- @class Arg
local Arg = {}
Arg.__index = Arg

type ArgImpl = typeof(Arg)

--- @interface ArgConfig
--- .aliases { string }?
--- .action ArgAction?
--- .env string?
--- .global boolean?
--- .help string?
--- .hideEnvValues boolean?
--- .index number?
--- .long (string | boolean)?
--- .name string
--- .numArgs number?
--- .required boolean?
--- .short (string | boolean)?
--- .shortAliases { string }?
--- .valueName string?

type ArgConfig<Action, ValueName, ShortLongType, Aliases> = {
	aliases: Aliases,
	action: Action,
	env: string?,
	global: boolean?,
	help: string?,
	hideEnvValues: boolean?,
	index: number?,
	long: ShortLongType?,
	name: string,
	numArgs: number?,
	required: boolean?,
	short: ShortLongType?,
	shortAliases: Aliases,
	valueName: ValueName,
}

export type Config = ArgConfig<string?, string?, string | boolean, { string }?>

export type Arg = typeof(setmetatable(
	{} :: {
		_config: ArgConfig<ArgAction, string, string, { string }>,
	},
	{} :: ArgImpl
))

--- Construct a new `Arg` with a unique name.
---
--- `name` is used as an identifier for the argument.
---
--- :::note
--- In the case of arguments that take values and positional arguments, the name will also
--- be displayed when the user prints usage or help information for the program.
--- :::
function Arg.new(name: string): Arg
	return setmetatable({
		_config = {
			aliases = {},
			action = ArgAction.Set,
			name = name,
			shortAliases = {},
			valueName = name,
		},
	}, Arg)
end

local deserialize = {
	action = function(action)
		return ArgAction:deserialize(action)
	end,
}

--- Construct a new `Arg` from a table
function Arg.from(config: Config): Arg
	local arg = Arg.new(config.name)

	for name, value in config do
		if name == "name" then
			continue
		end

		if deserialize[name] then
			value = deserialize[name](value)
		end

		assert(arg[name], `Arg does not have a '{name}' property.`)
		arg[name](arg, value)
	end

	return arg
end

--- Sets a short version of the argument.
---
--- ## Example
---
--- Calling `short` without any arguments is the same as calling `short` with the first letter
--- of the `Arg`'s name.
--- ```luau
--- -- these are the same
--- Arg.new("foo"):short()
--- Arg.new("foo"):short("f")
--- ```
function Arg.short(self: Arg, short: (string | boolean)?): Arg
	assert(
		self._config.index == nil,
		`Cannot assign \`short\` to positional argument "{self._config.name}"`
	)

	if short == true or short == nil then
		short = string.sub(self._config.name, 1, 1)
	elseif short == false then
		short = nil
	end

	self._config.short = short :: string?

	assert(
		#self._config.short :: string == 1,
		"short options cannot be longer than 1 character"
	)

	return self
end

--- Sets a long version of the argument.
---
--- ## Example
---
--- Calling `long` without any arguments is the same as calling `long` with the `Arg`'s name.
--- ```luau
--- -- these are the same
--- Arg.new("foo"):long()
--- Arg.new("foo"):long("foo")
--- ```
function Arg.long(self: Arg, long: (string | boolean)?): Arg
	assert(
		self._config.index == nil,
		`Cannot assign \`long\` to positional argument "{self._config.name}"`
	)

	if long == true or long == nil then
		long = self._config.name
	elseif long == false then
		long = nil
	end

	self._config.long = long :: string?
	return self
end

--- Sets the index of a positional argument.
--- By default, when creating an argument without `short` or `long`, the
--- `index` will be incremented sequentially based on any previous positional
--- arguments.
---
--- :::tip Positional arguments are just arguments without a `short` or `long`:::
---
---	## Example
---
---	In this example, you'd use the command like so:
---	```
---	program <bar> <foo>
--- ```
---
---	```luau
--- Command.new("program")
--- 	:arg(
---			Arg.new("bar")
--- 	)
--- 	:arg(
---			Arg.new("foo")
--- 	)
---	```
---
---	Whereas in this example, the command would be:
--- ```
---	program <foo> <bar>
--- ```
---
---	```luau
--- Command.new("program")
--- 	:arg(
---			Arg.new("bar"):index(2)
--- 	)
--- 	:arg(
---			Arg.new("foo")
--- 	)
---	```
function Arg.index(self: Arg, index: number): Arg
	assert(
		self._config.short == nil and self._config.long == nil,
		`Cannot use \`index\` with argument "{self._config.name}" because it has \`short\` or \`long\``
	)

	self._config.index = index
	return self
end

--- Sets the `ArgAction` of an argument.
function Arg.action(self: Arg, argAction: ArgAction): Arg
	assert(
		ArgAction.isA(argAction),
		`Expected ArgAction, got {typeof(argAction)} {argAction}`
	)
	self._config.action = argAction
	return self
end

--- Sets the `valueName` of an argument to be displayed in help information.
function Arg.valueName(self: Arg, name: string): Arg
	self._config.valueName = name
	return self
end

--- Sets the `help` of an argument to be displayed in help information.
function Arg.help(self: Arg, description: string): Arg
	self._config.help = description
	return self
end

--- Make this argument required.
--- :::warning Global arguments cannot be required.:::
function Arg.required(self: Arg, required: boolean?): Arg
	assert(not self._config.global, "Global arguments cannot be required.")
	self._config.required = required ~= false
	return self
end

--- Make this argument global. It will be propagated to any subcommands.
function Arg.global(self: Arg, global: boolean?): Arg
	assert(not self._config.required, "Global arguments cannot be required.")
	self._config.global = global ~= false
	return self
end

--- Read from the given environment variable when the argument isn't present.
function Arg.env(self: Arg, name: string): Arg
	self._config.env = name
	return self
end

--- Not implemented - we do not print values passed to arguments anywhere. You
--- should still use this method for any sensitive data you're passing (like api keys)
--- through environment variables incase this changes.
function Arg.hideEnvValues(self: Arg, hide: boolean?): Arg
	self._config.hideEnvValues = hide ~= false
	return self
end

--- Sets an `long` alias for this argument
function Arg.alias(self: Arg, name: string): Arg
	table.insert(self._config.aliases, name)
	return self
end

--- Sets a `short` alias for this argument
function Arg.shortAlias(self: Arg, name: string): Arg
	table.insert(self._config.shortAliases, name)
	return self
end

--- Sets multiple `long` aliases for this argument
function Arg.aliases(self: Arg, names: { string }): Arg
	for _, name in names do
		table.insert(self._config.aliases, name)
	end

	return self
end

--- Sets multiple `short` aliases for this argument
function Arg.shortAliases(self: Arg, names: { string }): Arg
	for _, name in names do
		table.insert(self._config.shortAliases, name)
	end

	return self
end

--- Not yet implemented
function Arg.numArgs(self: Arg, number: number): Arg
	self._config.numArgs = number
	return self
end

return Arg
