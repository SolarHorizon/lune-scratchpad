local merge = require("@lib/immutable/merge")

local Error = {}
Error.__index = Error

export type Error = typeof(setmetatable(
	{} :: {
		_error: string,
		id: any,
		_context: { any },
		metadata: { [any]: any? },
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

local function new(id: string | Error, value: any?, ...): Error
	local err: string = value :: any

	if not err and Error.is(id) then
		err = (id :: Error)._error
	end

	return setmetatable({
		_error = err or tostring(id),
		id = if Error.is(id) then (id :: Error).id else newId(id :: string),
		_context = { ... },
		metadata = {},
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

function Error.append(self: Error, value: string): Error
	return new(self, self._error .. value, table.unpack(self._context))
end

function Error.prepend(self: Error, value: string): Error
	return new(self, value .. self._error, table.unpack(self._context))
end

function Error.meta(self: Error, value: { [any]: any }): Error
	self.metadata = merge(self.metadata, value)
	return self
end

function Error.is(value: any): boolean
	return typeof(value) == "table" and getmetatable(value) == Error
end

function Error.isAny(self: Error, ...): boolean
	for i = 1, select("#", ...) do
		local other = select(i, ...)
		if Error.is(other) and self.id == other.id then
			return true
		end
	end

	return false
end

function Error.__call(self, ...): Error
	return new(self, nil, ...)
end

function Error.__tostring(self: Error): string
	return format(self._error, table.unpack(self._context))
end

return new
