--- @class Result
local Result = {}
Result.__index = Result

export type Result<T, E> = typeof(setmetatable(
	{} :: {
		_value: T,
		_error: E,
	},
	Result
))

local function new<T, E>(ok: T, err: E)
	return setmetatable({
		_value = ok,
		_error = err,
	}, Result)
end

--- @within Result
function Result.Ok<T, E>(value: T): Result<T, E>
	return new(value, (nil :: any) :: E)
end

local Ok = Result.Ok

--- @within Result
function Result.Err<T, E>(err: E): Result<T, E>
	return new((nil :: any) :: T, err)
end

local Err = Result.Err

--- @within Result
--- Matches against the result.
function Result.match<T, E, U...>(
	self: Result<T, E>,
	matches: {
		Ok: (T) -> U...,
		Err: (E) -> U...,
	}
)
	if self:isOk() then
		return matches.Ok(self._value)
	end

	return matches.Err(self._error)
end

--- @within Result
--- Returns `true` if the result is `Ok`.
function Result.isOk<T, E>(self: Result<T, E>)
	return self._value ~= nil
end

--- @within Result
--- Returns `true` if the result is `Ok` and the value inside of it matches a predicate.
function Result.isOkAnd<T, E>(self: Result<T, E>, f: (T) -> boolean)
	return self:isOk() and f(self._value)
end

--- @within Result
--- Returns `true` if the result is `Err`.
function Result.isErr<T, E>(self: Result<T, E>)
	return self._error ~= nil
end

--- @within Result
--- Returns `true` if the result is `Err` and the error matches a predicate..
function Result.isErrAnd<T, E>(self: Result<T, E>, f: (E) -> boolean)
	return self:isErr() and f(self._error)
end

--- @within Result
--- Maps a `Result<T, E>` to `Result<U, E>` by applying a function to a contained `Ok` value, leaving an `Err` value untouched.
--- This function can be used to compose the results of two functions.
function Result.map<T, U, E>(self: Result<T, E>, op: (T) -> U): Result<U, E>
	if self:isErr() then
		return Err(self._error)
	end

	return Ok(op(self._value))
end

--- @within Result
--- Returns the provided default (if `Err`), or applies a function to the contained value (if `Ok`).
function Result.mapOr<T, U, E>(self: Result<T, E>, default: U, f: (T) -> U): U
	if self:isErr() then
		return default
	end

	return f(self._value)
end

--- @within Result
--- Maps a `Result<T, E>` to `U` by applying fallback function `default` to a contained `Err` value, or function `f` to a contained `Ok` value.
--- This function can be used to unpack a successful result while handling an error.
function Result.mapOrElse<T, U, D, E>(self: Result<T, E>, default: (E) -> U, f: (T) -> U): U
	if self:isErr() then
		return default(self._error)
	end

	return f(self._value)
end

--- @within Result
--- Maps a `Result<T, E>` to `Result<T, F>` by applying a function to a contained `Err` value, leaving an `Ok` value untouched.
--- This function can be used to pass through a successful result while handling an error.
function Result.mapErr<T, E, F>(self: Result<T, E>, op: (E) -> F): Result<T, F>
	if self:isOk() then
		return Ok(self._value)
	end

	return Err(op(self._error))
end

--- @within Result
--- Calls a function with a reference to the contained value if `Ok`.
--- Returns the original result.
function Result.inspect<T, E>(self: Result<T, E>, f: (T) -> ()): Result<T, E>
	if self:isOk() then
		f(self._value)
	end

	return self
end

--- @within Result
--- Calls a function with a reference to the contained value if `Err`.
--- Returns the original result.
function Result.inspectErr<T, E>(self: Result<T, E>, f: (E) -> ()): Result<T, E>
	if self:isErr() then
		f(self._error)
	end

	return self
end

--- @within Result
--- Returns the contained `Ok` value, consuming the `self` value.
--- Because this function may error, its use is generally discouraged. Instead, prefer to handle the `Err` case explicitly, or call `unwrapOr`, `unwrapOrElse`, or `unwrapOrDefault`.
---
--- ## Recommended Message Style
--- It is recommended that `expect` messages are used to describe the reason you expect the `Result` to be `Ok.`
---
--- ```lua
--- 	local attachment = find(crane, "Top/Arm/RopeConstraint")
--- 		:expect("RopeConstraint should be exist before runtime")
--- ```
function Result.expect<T, E>(self: Result<T, E>, msg: string): T
	assert(self:isOk(), `{msg}: {self._error}`)
	return self._value
end

--- @within Result
--- Returns the contained `Ok` value, consuming the `self` value.
--- Because this function may error, its use is generally discouraged. Instead, prefer to handle the `Err` case explicitly, or call `unwrapOr`, `unwrapOrElse`, or `unwrapOrDefault`.
function Result.unwrap<T, E>(self: Result<T, E>): T
	return self:expect("'unwrap' called on result")
end

--- @within Result
--- Returns the `Err` value, consuming the `self` value.
--- Errors if the value is an `Ok`, with a message including the passed message, and the content of the `Ok`.
function Result.expectErr<T, E>(self: Result<T, E>, msg: string): E
	assert(self:isErr(), `{msg}: {self._value}`)
	return self._error
end

--- @within Result
--- Returns the `Err` value, consuming the `self` value.
--- Errors if the value is an `Ok` with the `Ok`'s value.
function Result.unwrapErr<T, E>(self: Result<T, E>): E
	return self:expectErr("'unwrapErr' called on result")
end

--- @within Result
--- Calls `op` if the result is `Ok`, otherwise returns the `Err` value of `self`.
--- This function can be used for control flow based on `Result` values.
function Result.andThen<T, U, E>(self: Result<T, E>, f: (T) -> Result<U, E>): Result<U, E>
	if self:isErr() then
		return Err(self._error)
	end

	return f(self._value)
end

--- @within Result
--- Returns `res` if the result is `Ok`, otherwise returns the `Err` value of `self`.
--- This is equivalent to Rust's `Result.and`, but `and` is not a valid function name in luau.
function Result.aand<T, U, E>(self: Result<T, E>, res: Result<U, E>): Result<U, E>
	if self:isOk() then
		return res
	end

	return Err(self._error)
end

--- @within Result
--- Returns `res` if the result is `Err`, otherwise returns the `Ok` value of `self`.
function Result.oor<T, E, F>(self: Result<T, E>, res: Result<T, F>): Result<T, F>
	if self:isErr() then
		return res
	end

	return Ok(self._value)
end

--- @within Result
--- Calls `op` if the result is `Err`, otherwise returns the `Ok` value of `self`.
--- This function can be used for control flow based on result values.
function Result.orElse<T, E, F>(self: Result<T, E>, op: (E) -> Result<T, F>): Result<T, F>
	if self:isErr() then
		return op(self._error)
	end

	return Ok(self._value)
end

--- @within Result
--- Returns the `Ok` value or a provided default.
function Result.unwrapOr<T, E>(self: Result<T, E>, default: T): T
	if self:isOk() then
		return self._value
	end

	return default
end

--- @within Result
--- Returns the contained `Ok` value or computes it from a closure.
function Result.unwrapOrElse<T, E>(self: Result<T, E>, op: (E) -> T): T
	if self:isOk() then
		return self._value
	end

	return op(self._error)
end

--- @within Result
--- Converts from `Result<Result<T, E>, E>` to `Result<T, E>`.
--- Flattening only removes one level of nesting at a time.
function Result.flatten<T, E>(self: Result<Result<T, E> | T, E>): Result<T, E>
	if
		self:isErr()
		or Result.is(self._value) and (self._value :: any):isErr()
	then
		return Err(self._error or (self._value :: any)._error)
	end

	if Result.is(self._value) then
		return Ok((self._value :: any)._value)
	end

	return Ok(self._value :: any)
end

--- @within Result
--- Takes a fallible function and turns it into a `Result`. If it fails, returns an `Err` containing the error message
--- received by `pcall`. If it succeeds, returns `Ok` containing the first value returned from the function. If
--- the function returns nothing, returns `Ok` containing `true`. The Luau type will not properly represent this.
---
--- :::warning
--- `from` does not support tuples. Only the first value returned from a function will be used.
function Result.from<T, E, A...>(cb, ...: A...): Result<T, E>
	local ok, content = pcall(cb, ...)

	if not ok then
		return Err(content :: any)
	end

	if content == nil then
		return Ok(true :: any)
	end

	return Ok(content)
end

--- @within Result
--- Returns `true` if `self` is a result.
function Result.is(self: any): boolean
	if type(self) == "table" then
		return getmetatable(self) == Result
	end

	return false
end

do
	local gt = require("@pkg/greentea")

	function Result.fromGtType<T>(gtType: T, ...): Result<T, string>
		local ok, err = gt.build(gtType):matches(...)

		if ok then
			return Ok(select(1, ...))
		end

		return Err(err:formatErr())
	end
end

do
	local process = require("@lune/process")

	type SpawnResult = process.SpawnResult

	--- @within Result
	--- @tag Lune
	--- Takes a `ProcessSpawnResult` and turns it into a `Result`. If it fails, returns an `Err` containing the
	--- `ProcessSpawnResult`. If it succeeds, returns `Ok` containing the `ProcessSpawnResult`.
	function Result.fromSpawnResult(
		spawnResult: SpawnResult
	): Result<SpawnResult, SpawnResult>
		if spawnResult.ok then
			return Ok(spawnResult)
		end

		return Err(spawnResult)
	end
end

return Result
