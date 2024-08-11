-- TODO: required*, conflicts*, exclusive, overrides*, requires*,
-- value*, possible_value(s), group(s), number_of_values, validator*
-- max/min_values, default*, display_order, last
local ArgAction = require("./ArgAction")

type ArgAction = ArgAction.ArgAction

--- @class Arg
local Arg = {}
Arg.__index = Arg

type ArgImpl = typeof(Arg)

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

function Arg.index(self: Arg, index: number): Arg
	assert(
		self._config.short == nil and self._config.long == nil,
		`Cannot use \`index\` with argument "{self._config.name}" because it has \`short\` or \`long\``
	)

	self._config.index = index
	return self
end

function Arg.action(self: Arg, argAction: ArgAction): Arg
	assert(
		ArgAction.isA(argAction),
		`Expected ArgAction, got {typeof(argAction)} {argAction}`
	)
	self._config.action = argAction
	return self
end

function Arg.valueName(self: Arg, name: string): Arg
	self._config.valueName = name
	return self
end

function Arg.help(self: Arg, description: string): Arg
	self._config.help = description
	return self
end

function Arg.required(self: Arg, required: boolean?): Arg
	self._config.required = required ~= false
	return self
end

function Arg.global(self: Arg, global: boolean?): Arg
	self._config.global = global ~= false
	return self
end

function Arg.env(self: Arg, name: string): Arg
	self._config.env = name
	return self
end

-- not implemented
function Arg.hideEnvValues(self: Arg, hide: boolean?): Arg
	self._config.hideEnvValues = hide ~= false
	return self
end

function Arg.alias(self: Arg, name: string): Arg
	table.insert(self._config.aliases, name)
	return self
end

function Arg.shortAlias(self: Arg, name: string): Arg
	table.insert(self._config.shortAliases, name)
	return self
end

function Arg.aliases(self: Arg, names: { string }): Arg
	for _, name in names do
		table.insert(self._config.aliases, name)
	end

	return self
end

-- not implemented
function Arg.numArgs(self: Arg, number: number): Arg
	self._config.numArgs = number
	return self
end

return Arg
