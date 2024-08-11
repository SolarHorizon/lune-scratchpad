local Option = require("@lib/Option")
local Res = require("@lib/Result")

type Result<T, E> = Res.Result<T, E>
type Option<T> = Option.Option<T>

local Some, None = Option.Some, Option.None

--- @class ResultConversion
local Result = {}

--- @within ResultConversion
--- Converts from `Result<T, E>` to `Option<T>`.
--- Converts `self` into an `Option<T>`, consuming `self`, and discarding the error, if any.
function Result.ok<T, E>(self: Result<T, E>): Option<T>
	if self:isOk() then
		return Some(self._value)
	end

	return None()
end

--- @within ResultConversion
--- Converts from `Result<T, E>` to `Option<E>`.
--- Converts `self` into an `Option<E>`, consuming `self`, and discarding the success value, if any.
function Result.err<T, E>(self: Result<T, E>): Option<E>
	if self:isErr() then
		return Some(self._error)
	end

	return None()
end

--- @within ResultConversion
--- Transposes a `Result` of an `Option` into an `Option` of a `Result`.
--- `Ok(None)` will be mapped to `None`. `Ok(Some(_))` and `Err(_)` will be mapped to `Some(Ok(_))` and `Some(Err(_))`.
function Result.transpose<T, E>(self: Result<T, E>): Option<Result<T, E>>
	if Option.is(self._value) and (self._value :: any):isNone() then
		return None()
	end

	return Some(self)
end

return Result
