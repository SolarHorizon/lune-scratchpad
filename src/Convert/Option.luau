local Opt = require("@lib/Option")
local Result = require("@lib/Result")

type Option<T> = Opt.Option<T>
type Result<T, E> = Result.Result<T, E>

local Ok, Err = Result.Ok, Result.Err
local Some, None = Opt.Some, Opt.None

--- @class OptionConversion
local Option = {}

--- @within OptionConversion
--- Transforms the `Option<T>` into a `Result<T, E>`, mapping `Some(v)` to `Ok(v)` and `None` to `Err(err())`.
function Option.okOrElse<T, E>(self: Option<T>, err: () -> E): Result<T, E>
	if self:isSome() then
		return Ok(self._value)
	end

	return Err(err())
end

--- @within OptionConversion
--- Transposes an `Option` of a `Result` into a `Result` of an `Option`.
--- `None` will be mapped to `Ok(None)`. `Some(Ok(_))` and `Some(Err(_))` will be mapped to `Ok(Some(_))` and `Err(_)`.
function Option.transpose<T, E>(self: Option<T>): Result<Option<T>, E>
	if self:isNone() then
		return Ok(None())
	end

	if Result.is(self._value) then
		local opt: Option<Result<T, E>> = self :: any

		if opt._value:isErr() then
			return Err(opt._value._error)
		end

		return Ok(Some(opt._value._value))
	end

	return Ok(Some(self._value))
end

--- @within OptionConversion
--- Transforms the `Option<T>` into a `Result<T, E>`, mapping `Some(v)` to `Ok(v)` and `None` to `Err(err)`.
function Option.okOr<T, E>(self: Option<T>, err: E): Result<T, E>
	if self:isNone() then
		return Err(err)
	end

	return Ok(self._value)
end

return Option
