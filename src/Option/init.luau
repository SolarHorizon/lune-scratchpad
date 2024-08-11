--- @class Option
local Option = {}
Option.__index = Option

export type Option<T> = typeof(setmetatable(
	{} :: {
		_value: T,
	},
	Option
))

local function new<T>(value: T?): Option<T>
	return setmetatable({
		_value = value :: T,
	}, Option)
end

--- @within Option
function Option.Some<T>(value: T?): Option<T>
	return new(value)
end

local Some = Option.Some

--- @within Option
function Option.None<T>(): Option<T>
	return new()
end

local None = Option.None

--- @within Option
--- Matches against the result.
function Option.match<T, U...>(
	self: Option<T>,
	matches: {
		Some: (T) -> U...,
		None: () -> U...,
	}
)
	if self:isSome() then
		return matches.Some(self._value)
	else
		return matches.None()
	end
end

--- @within Option
--- Returns `true` if the option is a `None` value.
function Option.isSome<T>(self: Option<T>): boolean
	return self._value ~= nil
end

--- @within Option
--- Returns `true` if the option is a `Some` and the value inside of it matches a predicate.
function Option.isSomeAnd<T>(self: Option<T>, f: (T) -> boolean): boolean
	return self:isSome() and f(self._value)
end

--- @within Option
--- Returns `true` if the option is a `Some` value.
function Option.isNone<T>(self: Option<T>): boolean
	return self._value == nil
end

--- @within Option
--- Returns the contained `Some` value, consuming the `self` value.
--- Errors if the value is a `None` with the provided error message.
function Option.expect<T>(self: Option<T>, msg: string): T
	assert(self:isSome(), msg)
	return self._value
end

--- @within Option
--- Returns the contained `Some` value, consuming the `self` value.
--- Errors if the value is a `None`
function Option.unwrap<T>(self: Option<T>): T
	assert(self:isSome(), "Attempted to unwrap an option containing None")
	return self._value
end

--- @within Option
--- Returns the contained `Some` value or a provided default.
function Option.unwrapOr<T>(self: Option<T>, default: T): T
	if self:isSome() then
		return self._value
	end

	return default
end

--- @within Option
--- Returns the contained `Some` value or computes it from a closure.
function Option.unwrapOrElse<T>(self: Option<T>, f: () -> T): T
	if self:isSome() then
		return self._value
	end

	return f()
end

--- @within Option
--- Maps an `Option<T>` to `Option<U>` by applying a function to a contained value (if `Some`) or returns `None` (if `None`)
function Option.map<T, U>(self: Option<T>, f: (T) -> U): Option<U>
	if self:isNone() then
		return None()
	end

	return Some(f(self._value))
end

--- @within Option
--- Calls a function on the contained value if `Some`.
--- Returns the original option.
function Option.inspect<T>(self: Option<T>, f: (T) -> ()): Option<T>
	if self:isSome() then
		f(self._value)
	end

	return self
end

--- @within Option
--- Returns the provided default result (if none), or applies a function to the contained value (if any).
function Option.mapOr<T, U>(self: Option<T>, default: U, f: (T) -> U): U
	if self:isNone() then
		return default
	end

	return f(self._value)
end

--- @within Option
--- Computes a default function result (if none), or applies a different function to the contained value (if any).
function Option.mapOrElse<T, U>(self: Option<T>, default: () -> U, f: (T) -> U): U
	if self:isNone() then
		return default()
	end

	return f(self._value)
end

--- @within Option
--- Returns `None` if the option is `None`, otherwise returns `optb`.
function Option.aand<T, U>(self: Option<T>, optb: Option<U>): Option<U>
	if self:isNone() then
		return None()
	end

	return optb
end

--- @within Option
--- Returns `None` if the option is `None`, otherwise calls `f` with the wrapped value and returns the result.
--- Some languages call this operation flatmap.
function Option.andThen<T, U>(self: Option<T>, f: (T) -> Option<U>): Option<U>
	if self:isNone() then
		return None()
	end

	return f(self._value)
end

--- @within Option
--- Returns `None` if the option is `None`, otherwise calls `predicate` with the wrapped value and returns:
--- - `Some(t)` if `predicate` returns `true` (where `t` is the wrapped value), and
--- - `None` if `predicate` returns `false`.
function Option.filter<T>(self: Option<T>, predicate: (T) -> boolean): Option<T>
	if self:isNone() or not predicate(self._value) then
		return None()
	end

	return Some(self._value)
end

--- @within Option
--- Returns the option if it contains a value, otherwise returns `optb`.
function Option.oor<T>(self: Option<T>, optb: Option<T>): Option<T>
	if self:isNone() then
		return optb
	end

	return self
end

--- @within Option
--- Returns the option if it contains a value, otherwise calls `f` and returns the result.
function Option.orElse<T>(self: Option<T>, f: () -> Option<T>): Option<T>
	if self:isNone() then
		return f()
	end

	return self
end

--- @within Option
--- Returns `Some` if exactly one of `self`, `optb` is `Some`, otherwise returns `None`.
function Option.xor<T>(self: Option<T>, optb: Option<T>): Option<T>
	if self:isSome() == optb:isSome() then
		return None()
	end

	return Some(self._value or optb._value)
end

--- @within Option
--- Inserts `value` into the option and then returns `value`.
--- If the option already contains a value, the old value is overwritten.
--- This operation will mutate the option.
function Option.insert<T>(self: Option<T>, value: T): T
	self._value = value
	return self._value
end

--- @within Option
--- Inserts `value` into the option if it is `None`, then returns `value`.
--- This operation will mutate the option.
function Option.getOrInsert<T>(self: Option<T>, value: T): T
	if self:isNone() then
		self._value = value
	end

	return self._value
end

--- @within Option
--- Inserts a value computed from `f` into the option if it is `None`, then returns the value.
--- This operation will mutate the option.
function Option.getOrInsertWith<T>(self: Option<T>, f: () -> T): T
	if self:isNone() then
		self._value = f()
	end

	return self._value
end

--- @within Option
--- Takes the value out of the option, leaving a `None` in its place.
--- This operation will mutate the option.
function Option.take<T>(self: Option<T>): Option<T>
	if self:isNone() then
		return None()
	end

	local value = self._value
	self._value = nil :: any

	return Some(value)
end

--- @within Option
--- Takes the value out of the option, but only if the predicate evaluates to `true`.
--- In other words, replaces `self` with `None` if the predicate returns `true`. Similar to `take` but conditional.
--- This operation will mutate the option.
function Option.takeIf<T>(self: Option<T>, predicate: (T) -> boolean): Option<T>
	if predicate(self._value) then
		return self:take()
	end

	return self
end

--- @within Option
--- Replaces the actual value in the option by the value given in parameter, returning the old value if present, leaving a `Some` in its place.
--- This operation will mutate the option.
function Option.replace<T>(self: Option<T>, value: T): Option<T>
	local old = if self:isSome() then Some(self._value) else None()
	self._value = value
	return old
end

--- @within Option
--- Zips `self` with another `Option`.
--- If `self` is `Some(T) and `other` is `Some(U)`, this method returns `Some({ T | U })`. Otherwise, `None` is returned.
function Option.zip<T, U>(self: Option<T>, other: Option<U>): Option<{ T | U }>
	if self:isNone() or other:isNone() then
		return None()
	end

	return Some({ self._value, other._value :: any })
end

--- @within Option
--- Zips `self` with another `Option` with function `f`.
--- If `self` is `Some(T) and `other` is `Some(U)`, this method returns `Some(f(T, U))`. Otherwise, `None` is returned.
function Option.zipWith<T, U, R>(
	self: Option<T>,
	other: Option<U>,
	f: (T, U) -> R
): Option<R>
	if self:isNone() or other:isNone() then
		return None()
	end

	return Some(f(self._value, other._value))
end

--- @within Option
--- Unzips an option containing a table with two options.
--- If `self` is `Some({ a, b })` this method returns `(Some(a), Some(b))`. Otherwise, `(None, None)` is returned.
function Option.unzip<T, U, V>(self: Option<T>): (Option<U>, Option<V>)
	if self:isNone() or type(self._value) ~= "table" then
		return None(), None()
	end

	local a, b = unpack(self._value)

	if a == nil or b == nil then
		return None(), None()
	end

	return a, b
end

--- @within Option
--- Converts from `Option<Option<T>>` to `Option<T>`
--- Flattening only removes one level of nesting at a time.
function Option.flatten<T>(self: Option<Option<T> | T>): Option<T>
	if self:isNone() or (self._value :: any):isNone() then
		return None()
	end

	if Option.is(self._value) then
		return Some((self._value :: any)._value)
	end

	return Some(self._value :: any)
end

--- @within Option
--- Takes a fallible function and turns it into an `Option`. If it fails, returns `None`. If it succeeds, returns `Some`
--- containing the first value returned from the function. If the value is `nil`, returns `None`.
---
--- :::warning
--- `from` does not support tuples. Only the first value returned from a function will be used.
function Option.from<T, A...>(cb, ...: A...): Option<T>
	local ok, content = pcall(cb, ...)

	if ok and content ~= nil then
		return Some(content)
	end

	return None()
end

--- @within Option
--- Returns `true` if `self` is an option.
function Option.is(self: any): boolean
	if type(self) == "table" then
		return getmetatable(self) == Option
	end

	return false
end

return Option
