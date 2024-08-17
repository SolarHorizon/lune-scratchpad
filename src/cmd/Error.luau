local term = require("@lib/term")

local color = term.color

local Error = {}
Error.__index = Error

export type Error = typeof(setmetatable(
	{} :: {
		_error: string,
		id: any,
		_context: { any },
	},
	Error
))

local function newId(str: string)
	local proxy = newproxy(true)

	getmetatable(proxy).__tostring = function()
		return `Error<{str}>`
	end

	return proxy
end

local function err(id: string | Error, value: any?, ...): Error
	local msg: string = value :: any

	if not msg and Error._is(id) then
		msg = (id :: Error)._error
	end

	return setmetatable({
		_error = msg or "",
		id = if Error._is(id) then (id :: Error).id else newId(id :: string),
		_context = { ... },
	}, Error)
end

local function format(str: string, ...)
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		str = string.gsub(str, `%${i}`, tostring(value))
		str = string.gsub(str, `%$@`, tostring(value) .. "$@")
	end

	str = string.gsub(str, `%$@`, "")

	return str
end

function Error.append(self: Error, value: string)
	return err(self, self._error .. value, table.unpack(self._context))
end

function Error.prepend(self: Error, value: string)
	return err(self, value .. self._error, table.unpack(self._context))
end

function Error._is(value: any)
	return typeof(value) == "table" and getmetatable(value) == Error
end

function Error.is(self: Error, ...)
	for i = 1, select("#", ...) do
		local other = select(i, ...)
		if Error._is(other) and self.id == other.id then
			return true
		end
	end

	return false
end

function Error.__call(self: Error, ...)
	return err(self, nil, ...)
end

function Error.__tostring(self: Error)
	return format(self._error, table.unpack(self._context))
end

return {
	DisplayHelp = err("DisplayHelp"),
	DisplayOnMissingArgumentOrSubcommand = err(
		"DisplayOnMissingArgumentOrSubcommand"
	),
	DisplayVersion = err("DisplayVersion"),
	InvalidArgument = err(
		"InvalidArgument",
		`Found argument '{color.yellow("$1")}' which wasn't expected or isn't valid in this context`
	),
	InvalidSubcommand = err(
		"InvalidSubcommand",
		`The subcommand '{color.yellow("$1")}' wasn't recognized`
	),
	--stylua: ignore
	NoValue = err(
		"NoValue",
		`The following required arguments were not supplied:{color.green("$@")}`
	),
	--stylua: ignore
	NoSubcommand = err(
		"NoValue",
		`'{color.yellow("$1")}' requires a subcommand but one was not provided.`
	),
	--stylua: ignore
	UnknownOption = err(
		"UnknownOpt", 
		`Found argument '{color.yellow("$1")}' which wasn't expected or isn't valid in this context` 
		.. `\n\n  {color.green("tip:")} If you tried to supply '{color.yellow("$1")}'` 
		.. ` as a value rather than an option, use '{color.green(`-- {"$1"}`)}'`
	),
}
