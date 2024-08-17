--!native
local Option = require("@lib/Option")
local Result = require("@lib/Result")

local Chain = require("./Chain")
local controlFlow = require("./controlFlow")

local Ok = Result.Ok
local Some = Option.Some

type Option<T> = Option.Option<T>
type Result<T, E> = Result.Result<T, E>
type None = controlFlow.None
type Break<T> = controlFlow.Break<T>
type Maybe<T> = T | None

local term = require("@lib/term")
local warn = term.warn

--- @class Iter
local Iter = {}
Iter.__index = Iter

export type Iter<K, V> = typeof(setmetatable(
	{} :: {
		_value: { [K]: V },
		_lastKey: K?,
		_asMut: boolean,
		_iterationCount: number,
	},
	Iter
))

--- Constructs a new iterator over the given value
function Iter.new<K, V>(value: { [K]: V }): Iter<K, V>
	return Iter._new(value)
end

--- Creates a new iterator that yields an element exactly once.
---
--- This is commonly used to adapt a single value into a `chain()` of other kinds of iteration. Maybe you
--- have an iterator that covers almost everything, but you need an extra special case. Maybe you have a
--- function which works on iterators, but you only need to process one value.
function Iter.once<K, V>(value: V, key: K?): Iter<K, V>
	if key then
		return Iter.new({ [key] = value })
	end

	return Iter.new({ value } :: { [any]: any })
end

function Iter._new<K, V>(value: { [K]: V }, prevIter: Iter<K, V>?): Iter<K, V>
	assert(
		typeof(value) == "table",
		"iter expected table, got " .. typeof(value)
	)

	return setmetatable({
		_value = value,
		_lastKey = nil,
		_asMut = if prevIter then prevIter._asMut else false,
		_iterationCount = 0,
	}, Iter)
end

function Iter._next<K, V>(self: Iter<K, V>, last: K?): (K?, V?)
	local key, value = next(self._value, last)

	if key == nil then
		self._lastKey = nil
		return nil
	end

	self._iterationCount = 1 + self._iterationCount :: number
	self._lastKey = key
	return key, value
end

function Iter.__iter<K, V>(self: Iter<K, V>)
	return Iter._next, self
end

--- Advances the iterator and returns the next value.
---
--- Returns `nil` when iteration is finished.
---
--- # Examples
--- Basic usage:
---
--- ```lua
--- local a = {1, 2, 3}
---
--- local iterator = iter.new(a)
---
--- -- A call to next() returns the next value...
--- assert(1 == iter.next())
--- assert(2 == iter.next())
--- assert(3 == iter.next())
---
--- -- ... and then `nil` once it's over.
--- assert(nil == iter.next())
--- ```
function Iter.next<K, V>(self: Iter<K, V>): (Maybe<K>, V?)
	self:_next(self._lastKey)
	return self:_getInputTuple()
end

--- Tests if every element of the iterator matches a predicate.
---
--- `all()` takes a closure that returns true or false. It applies this closure
--- to each element of the iterator, and if they all return true, then so does
--- all(). If any of them return false, it returns false.
---
--- `all()` is short-circuiting; in other words, it will stop processing as soon
--- as it finds a false, given that no matter what else happens, the result will
--- also be false.
---
--- An empty iterator returns true.
---
--- # Examples
---
--- Basic usage:
---
--- ```lua
--- local a = {1, 2, 3}
---
--- assert(iter(a):all(function(_, x)
--- 	return x > 0
--- end))
---
--- assert(not iter(a):all(function(_, x)
--- 	return x > 2
--- end))
--- ```
---
--- Stopping at the first false:
---
--- ```lua
--- local a = {1, 2, 3}
---
--- local iterator = iter(a)
---
--- assert(not iterator:all(function(_, x)
--- 	return x ~= 2
--- end))
---
--- -- we can still use `iter`, as there are more elements.
--- assert(next(iterator) == 3)
--- ```
function Iter.all<K, V>(self: Iter<K, V>, f: (K, V) -> boolean): boolean
	local res = self:tryFold(true, function(_, ...)
		if f(...) then
			return true
		end
		return controlFlow.Break(true)
	end)

	return not controlFlow.isBreak(res)
end

--- Ensures `table.freeze` doesn't get called when iterator gets collected.
---
--- # Deviations
--- In Rust this is done by specifying `mut` to the assigning variable,
--- but this is not a feature in Lua.
---
--- @return iter
function Iter.asMut<K, V>(self: Iter<K, V>)
	self._asMut = true
	return self
end

--- Tests if any element of the iterator matches a predicate.
---
--- `any()` takes a function that returns `true` or `false`. It applies this
--- function to each element of the iterator, and if any of them return
--- `true`, then so does `any()`. If they all return `false`, it returns `false`.
---
--- `any()` is short-circuiting; in other words, it will stop processing
--- as soon as it finds a true, given that no matter what else happens,
--- the result will also be true.
---
--- An empty iterator returns `false`.
---
--- # Examples
---
--- Basic usage:
---
--- ```lua
--- local a = {1, 2, 3}
---
--- assert(iter(a):all(function(_, x)
--- 	return x > 0
--- end))
---
--- assert(not iter(a):all(function(_, x)
--- 	return x > 5
--- end))
--- ```
---
--- Stopping at the first true:
---
--- ```lua
--- local a = {1, 2, 3}
---
--- local iterator = iter(a)
---
--- assert(not iterator:all(function(_, x)
--- 	return x ~= 2
--- end))
---
--- -- we can still use `iter`, as there are more elements.
--- assert(next(iterator) == 2)
--- ```
function Iter.any<K, V>(self: Iter<K, V>, f: (K, V) -> boolean): boolean
	local hasAny = false

	self:tryFold(true, function(_, ...)
		if f(...) then
			hasAny = true
			return nil
		end
		return true
	end)

	return hasAny
end

--- Consumes the iterator, counting the number of iterations and returning it.
---
--- This method will call [`next`] repeatedly until `nil` is encountered, returning the
--- number of times it saw values. Note that [`next`] has to be called at least once even
--- if the iterator does not have any elements.
function Iter.count<K, V>(self: Iter<K, V>): number
	return self:fold(0, function(count: number)
		return count + 1
	end)
end

--- Transforms an iterator into a table.
---
--- `collect()` can take anything iterable, and turn it into a relevant table.
--- This is one of the more powerful methods in the standard library, used in a variety of contexts.
---
--- The most basic pattern in which `collect()` is used is to turn one table into
--- another. You take a table, call [`iter`] on it, do a bunch of transformations,
--- and then `collect()` at the end.
---
--- # Deviations
--- The returned table is frozen by default if [`asMut`] was never called.
function Iter.collect<K, V>(self: Iter<K, V>): { [K]: V }
	local res: { [any]: any } = {}

	self:tryFold(true, function(_, key, value)
		res[key] = value
		return true
	end)

	if not self._asMut then
		res = table.freeze(res)
	end

	return res
end

--- Same thing as [`collect`], but turns table into arrays of its values and discards its keys.
---
--- # Deviations
--- * In Rust this would be done by using [`collect`] and specifying the type, but types in lua
--- do not affect the runtime.
--- * The returned table is frozen by default if [`asMut`] was never called.
function Iter.collectArray<K, V>(self: Iter<K, V>): { V }
	local res: { V } = {}

	self:tryFold(true, function(_, key, value)
		table.insert(res, value :: V)
		return true
	end)

	if not self._asMut then
		res = table.freeze(res)
	end

	return res
end

--- Turns an `Iter<K, Result<V, E>>` into a `Result<{ [K]: V }, E>`
---
--- # Deviations
--- * In Rust this would be done by using [`collect`] and specifying the type, but types in lua
--- do not affect the runtime.
function Iter.intoResult<K, V, E>(self: Iter<K, Result<V, E>>): Result<{ [K]: V }, E>
	local res = self:tryFold({}, function(x, key, value: Result<V, E>)
		assert(Result.is(value), `Expected Result, got {typeof(value)}`)

		if value:isOk() then
			x[key] = value:unwrap()
			return x
		else
			return controlFlow.Break(value)
		end
	end)

	if controlFlow.isBreak(res) then
		return (res :: any).value
	end

	return Ok(res :: any)
end

--- Converts an `Iter<K, Option<V>>` into an `Option<{ [K]: V }>`.
---
--- # Deviations
--- * In Rust this would be done by using [`collect`] and specifying the type, but types in lua
--- do not affect the runtime.
function Iter.intoOption<K, V>(self: Iter<K, Option<V>>): Option<{ [K]: V }>
	local res = self:tryFold({}, function(x, key: K, value: Option<V>)
		if value:isSome() then
			x[key] = value:unwrap()
			return x
		else
			return controlFlow.Break(value) :: any
		end
	end)

	if controlFlow.isBreak(res) then
		return (res :: any).value
	end

	return Some(res)
end

local function createFilter<K, V>(iter: Iter<K, V>, new, predicate): Iter<K, V>
	local newIter = new(iter._value, iter)

	function newIter:next()
		return iter:find(predicate)
	end

	function newIter:fold<T>(init, g)
		return iter:fold(init, function(acc, ...)
			if predicate(...) then
				return g(acc, ...)
			else
				return acc
			end
		end)
	end

	function newIter:tryFold<T>(init, g)
		return iter:tryFold(init, function(acc, ...)
			if predicate(...) then
				return g(acc, ...)
			else
				return acc
			end
		end)
	end

	return newIter
end

--- Creates an iterator which uses a closure to determine if an element should be yielded.
---
--- Given an element the closure must return true or false. The returned iterator will yield
--- only the elements for which the closure returns true.
---
--- @return Iter
function Iter.filter<K, V>(self: Iter<K, V>, predicate: (K, V) -> boolean): Iter<K, V>
	return createFilter(self, Iter._new, predicate)
end

local function isContiguous(index: number?, currentKey: any)
	if typeof(currentKey) ~= "number" and index then
		return false
	end

	return index == currentKey - 1
end

local function createFilterMap<K, V, T>(iter: Iter<K, V>, new, f: (K, V) -> T): Iter<K, V>
	local newIter = new(iter._value, iter)

	-- Used to check whether table is still a contiguous array
	local lastTableIndex: number? = 0

	-- For the resulting array index. This can deviate from real index if values are filtered out
	local currentArrayIndex = 0

	function newIter:next(): ...any
		return iter:findMap(f)
	end

	function newIter:fold<T>(init: T, fold: (T, ...any) -> T): T
		return iter:fold(init, function(acc, key, value)
			local isArray = false
			if isContiguous(lastTableIndex, key) then
				lastTableIndex = lastTableIndex and lastTableIndex + 1
				currentArrayIndex += 1
				isArray = true
			else
				lastTableIndex = nil
			end

			local newValue = f(key, value)
			if newValue ~= nil then
				if isArray then
					currentArrayIndex += 1
				end
				return fold(
					acc,
					if isArray then currentArrayIndex else key,
					newValue
				)
			else
				return acc
			end
		end)
	end

	function newIter:tryFold(init, fold)
		return iter:tryFold(init, function(acc, key, value)
			local isArray = false
			if isContiguous(lastTableIndex, key) then
				lastTableIndex = lastTableIndex and lastTableIndex + 1
				isArray = true
			else
				lastTableIndex = nil
			end

			local newValue = f(key, value)
			if newValue ~= nil then
				if isArray then
					currentArrayIndex += 1
				end
				return fold(
					acc,
					if isArray then currentArrayIndex else key,
					newValue
				)
			else
				return acc
			end
		end)
	end

	return newIter
end

--- Creates an iterator that both filters and maps.
---
--- The returned iterator yields only the values for which the supplied closure returns non-nil.
---
--- `filterMap` can be used to make chains of [`filter`] and [`map`] more concise.
---
--- # Examples
--- Basic usage:
---
--- ```lua
--- local a = {"1", "two", "hi", "four", "5"}
---
--- local iterator = iter.new(a):filterMap(function(s)
--- 	return tonumber(a)
--- end)
---
--- iterator:next() -> 1, 1
--- iterator.next() -> 1, 5
--- iterator.next() -> iter.None
--- ```
---
--- # Deviations
--- `filterMap` will assume arrays the table is an array and will slide entries down if values are
--- removed as long as the table is contiguous. The first time a non-array key is encountered (key
--- that jumps or non-numeric key), `filterMap` will act the same as `map`.
function Iter.filterMap<K, V, T>(self: Iter<K, V>, f: (K, V) -> T?): Iter<K, V>
	return createFilterMap(self, Iter._new, f)
end

--- Searches for an element of an iterator that satisfies a predicate.
---
--- `find()` takes a closure that returns true or false. It applies this closure to each element
--- of the iterator, and if any of them return true, then `find()` returns the element. If
--- they all return false, it returns `None`.
---
--- `find()` is short-circuiting; in other words, it will stop processing as soon as the closure
--- returns `true`
function Iter.find<K, V>(
	self: Iter<K, V>,
	predicate: (K, V) -> boolean
): (Maybe<K>, V?)
	local res = self:tryFold(false, function(_, key, value)
		if predicate(key, value) then
			return controlFlow.Break({ key, value :: any })
		end
		return false
	end)

	if controlFlow.isBreak(res) then
		return table.unpack((res :: any).value)
	end

	return controlFlow.None
end

--- Applies function to the elements of iterator and returns the first non-nil result.
---
--- `iter:findMap(f)` is equivalent to `iter:filterMap(f):next()`.
---
--- # Examples
--- ```lua
--- local a = {"lol", "hi", "2", "5"}
---
--- local _, firstNumber = iter.new(a):findMap(function(_k, s)
--- 	return tonumber(s)
--- end)
---
--- assert(firstNumber == 2)
--- ```
function Iter.findMap<K, V, T>(self: Iter<K, V>, f: (K, V) -> T): (K?, T?)
	local res = self:tryFold(true, function(_, key, value)
		local x = f(key, value)
		return if x == nil then true else controlFlow.Break({ key, x :: any })
	end)

	if controlFlow.isBreak(res) then
		return table.unpack((res :: any).value)
	end
	return nil
end

--- Folds every element into an accumulator by applying an operation, returning the final result.
---
--- `fold()` takes two arguments: an initial value, and a closure with two arguments: an
--- 'accumulator', and an element. The closure returns the value that the accumulator should
--- have for the next iteration.
---
--- The initial value is the value the accumulator will have on the first call.
---
--- After applying this closure to every element of the iterator, `fold()` returns the accumulator.
---
--- This operation is sometimes called 'reduce' or 'inject'.
---
--- Folding is useful whenever you have a collection of something, and want to produce a single
--- value from it.
---
--- # Errors
--- * If the iterator is an infinite iterator (DEVIATION)
---
--- # Examples
--- Basic usage:
---
--- ```lua
--- local a = {1, 2, 3}
---
--- -- the sum of all of the elements of the array
--- local sum = iter.new(a):fold(0, function(acc, x)
--- 	return acc + x
--- end)
---
--- assert(sum == 6)
--- ```
---
---
--- This example demonstrates the left-associative nature of fold(): it builds a string, starting
--- with an initial value and continuing with each element from the front until the back:
---
--- ```lua
--- local numbers = {1, 2, 3, 4, 5}
---
--- local result = iter.new(numbers):fold("0", function(acc, x)
--- 	return `({acc} + {x})`
--- end);
---
--- assert(result, "(((((0 + 1) + 2) + 3) + 4) + 5)");
--- ```
function Iter.fold<K, V, T>(
	self: Iter<K, V>,
	init: T,
	f: (T, K, V) -> Break<T> | Maybe<T>
): T
	local accum = init
	local next: { any } = { self:next() }
	while next[1] ~= controlFlow.None do
		local value = if #next == 2 then next[2] else next[3]
		accum = (f :: any)(accum, self:_getInputTuple(nil, value))
		next = { self:next() }
	end
	return accum
end

--- Calls a closure on each element of an iterator.
---
--- This is equivalent to using a for loop on the iterator, although break
--- and continue are not possible from a closure. It's generally more idiomatic
--- to use a for loop, but for_each may be more legible when processing items at
--- the end of longer iterator chains.
---
--- # Examples
--- Basic usage:
---
--- ```lua
--- iter.new({ 0, 1, 2 })
--- 	:map(function(_, x: number)
--- 		return x * 100
--- 	end)
--- 	:filter(function(i: number, x: number)
--- 		return (i + x) % 3 == 0
--- 	end)
--- 	:for_each(function(i: number, x: number)
--- 		print(`{i}:{x}`)
--- 	end)
--- ```
function Iter.forEach<K, V>(self: Iter<K, V>, f: (K, V) -> ())
	self:fold(nil, function(_, key, value): nil
		f(key, value)
		return nil
	end)
end

--- Does something with each element of an iterator, passing the value on.
---
--- When using iterators, you'll often chain several of them together. While working
--- on such code, you might want to check out what's happening at various parts in
--- the pipeline. To do that, insert a call to `inspect()`.
---
--- It's more common for `inspect()` to be used as a debugging tool than to exist in
--- your final code, but applications may find it useful in certain situations when
--- errors need to be logged before being discarded.
---
--- # Examples
--- Basic usage:
---
--- ```lua
--- local a = {1, 4, 2, 3}
---
--- -- this iterator sequence is complex.
--- local sum = iter.new(a)
--- 	:cloned()
--- 	:filter(function(x)
--- 		return x % 2 == 0
--- 	end)
--- 	:fold(0, function(sum, i)
--- 		return sum + i
--- 	end)
---
--- print("{sum}")
---
--- -- let's add some inspect() calls to investigate what's happening
--- local sum = a.iter()
--- 	:inspect(function(x)
--- 		print("about to filter: {x}")
--- 	end)
--- 	:filter(function(x)
--- 		return x % 2 == 0
--- 	end)
--- 	:inspect(function(x)
--- 		print("made it through filter: {x}")
--- 	end)
--- 	:fold(0, function(sum, i)
--- 		return sum + i
--- 	end)
---
--- print(`{sum}`)
--- ```
--- This will print:
---
--- ```
--- 6
--- about to filter: 1
--- about to filter: 4
--- made it through filter: 4
--- about to filter: 2
--- made it through filter: 2
--- about to filter: 3
--- 6
--- ```
function Iter.inspect<K, V>(self: Iter<K, V>, f: (K, V) -> ())
	for key, value in self do
		(f :: any)(self:_getInputTuple(key, value))
	end
end

--- Consumes the iterator, returning the last element.
---
--- For non-arrays, this method will evaluate the iterator until it returns `nil`.
--- While doing so, it keeps track of the current element. After `nil` is returned,
--- `last()` will then return the last element it saw.
---
--- # Examples
--- Basic usage:
---
--- ```lua
--- local a = {1, 2, 3}
--- assert(iter.new(a).last() == 3)
---
--- local a = {1, 2, 3, 4, 5}
--- assert(iter.new(a).last() == 5)
--- ```
function Iter.last<K, V>(self: Iter<K, V>): (K, V)
	local res: { any } = self:fold({}, function(_, ...)
		return { ... }
	end)

	return table.unpack(res)
end

local function createMap<K, V, T>(iter: any, new, f: (K, V) -> T?): Iter<K, T>
	local newIter = new(iter._value, iter)

	function newIter:next(): ...any
		local next = { iter:next() }

		if next[1] == controlFlow.None then
			return controlFlow.None
		end

		-- Must fallback to `Nil` as `_getInputTuple` uses default value for nil values
		local newValue = f(table.unpack(next)) or controlFlow.Nil

		return iter:_getInputTuple(nil, newValue)
	end

	function newIter:fold<T>(init: T, g): T
		return iter:fold(init, function(acc, key, value)
			return g(acc, key, f(key, value))
		end)
	end

	function newIter:tryFold<T>(init: T, g): T?
		return iter:tryFold(init, function(acc, key, value)
			return g(acc, key, f(key, value))
		end)
	end

	return newIter
end

--- Takes a closure and creates an iterator which calls that closure on each element.
---
--- `map()` transforms one iterator into another. It produces a new iterator which calls this
--- closure on each element of the original iterator.
---
--- If you are good at thinking in types, you can think of `map()` like this: If you have an
--- iterator that gives you elements of some type `A`, and you want an iterator of some other
--- type `B`, you can use `map()`, passing a closure that takes an `A` and returns a `B`.
---
--- `map()` is conceptually similar to a `for` loop. If you're doing some sort of looping for a side
--- effect, it's considered more idiomatic to use `for` than `map()`.
---
--- @return iter
function Iter.map<K, V, T>(self: Iter<K, V>, f: (K, V) -> T?): Iter<K, T>
	return createMap(self, Iter._new, f)
end

local function createMapWhile<K, V, T>(
	iter: Iter<K, V>,
	new,
	predicate: (any, any) -> ...any
): Iter<K, T>
	local newIter = new(iter._value, iter)

	function newIter:next(): any
		local x = { iter:next() }

		if x[1] == controlFlow.None :: any then
			return controlFlow.None
		end

		local res = predicate(table.unpack(x))

		if res == 0 then
			return controlFlow.None
		end

		return iter:_getInputTuple(nil, res)
	end

	function newIter:fold(init, g)
		return self:tryFold(init, g)
	end

	function newIter:tryFold(init, g)
		local res = iter:tryFold(init, function(acc, key, value)
			local newValue = predicate(key, value)
			if newValue ~= nil then
				return g(acc, key, newValue)
			else
				return controlFlow.Break(acc)
			end
		end)

		if controlFlow.isBreak(res) then
			return res.value
		end
		return res
	end

	return newIter
end

--- Creates an iterator that both yields elements based on a predicate and maps.
---
--- `mapWhile()` takes a function as an argument. It will call this function on each element
--- of the iterator, and yield elements while it returns non-nil.
---
--- @return iter
function Iter.mapWhile<K, V, T>(self: Iter<K, V>, predicate: (K, V) -> T): Iter<K, V>
	return createMapWhile(self, Iter._new, predicate)
end

--- Reduces the elements to a single one, by repeatedly applying a reducing operation.
---
--- If the iterator is empty, returns `iter.None`; otherwise, returns the result of the reduction.
---
--- The reducing function is a closure with two arguments: an 'accumulator', and an element.For iterators
--- with at least one element, this is the same as [`fold`] with the first element of the iterator as the
--- initial accumulator value, folding every subsequent element into it.
---
--- # Example
--- ```lua
--- local a = { 1, 2, ..., 10 }
--- local reduced = iter.new(a):reduce(function(acc, e)
--- 	return acc + e
--- end)
--- assert(reduced == 45)
---
--- -- Which is equivalent to doing it with `fold`:
--- local folded = iter.new(a):fold(0, function(acc, e)
--- 	return acc + e
--- end)
--- assert(reduced == folded)
--- ```
function Iter.reduce<K, V, T>(self: Iter<K, V>, f: (T, K, V) -> T): Maybe<T>
	local _, first: any = self:next()

	if first == nil then
		return controlFlow.None
	end

	return self:fold(first, f)
end

local function createTake<K, V>(iter: Iter<K, V>, new, n: number): Iter<K, V>
	local newIter = new(iter._value, iter)

	function newIter:next(): ...any
		if n > 0 then
			n -= 1
			return iter:next()
		end
		return controlFlow.None
	end

	function newIter:fold(init, fold)
		return self:tryFold(init, fold)
	end

	function newIter:tryFold(init, fold): any
		local res: any = iter:tryFold(init, function(...)
			if n == 0 then
				return init
			else
				n -= 1
				if n == 0 then
					return controlFlow.Break(fold(...))
				else
					return fold(...)
				end
			end
		end)

		if controlFlow.isBreak(res) then
			return res.value
		end
		return res
	end

	return newIter
end

--- Creates an iterator that yields the first `n` elements, or fewer if the underlying iterator ends sooner.
---
--- `take(n)` yields elements until `n` elements are yielded or the end of the iterator is reached (whichever
--- happens first). The returned iterator is a prefix of length `n` if the original iterator contains at least
--- `n` elements, otherwise it contains all of the (fewer than `n`) elements of the original iterator.
function Iter.take<K, V>(self: Iter<K, V>, n: number): Iter<K, V>
	return createTake(self, Iter._new, n)
end

--- An iterator method that applies a function as long as it returns successfully, producing a single,
--- 	final value.
---
--- `tryFold()` takes two arguments: an initial value, and a closure with two arguments: an 'accumulator',
--- and an element. The closure either returns successfully, with the value that the accumulator should
--- have for the next iteration, or it returns `nil` that is propagated back to the caller immediately
--- (short-circuiting).
---
--- The initial value is the value the accumulator will have on the first call. If applying the closure
--- succeeded against every element of the iterator, `tryFold()` returns the final accumulator as success.
---
--- Folding is useful whenever you have a collection of something, and want to produce a single value from it.
function Iter.tryFold<K, V, T>(
	self: Iter<K, V>,
	init: T,
	f: (T, K, V) -> Break<any> | T?
): Maybe<T>
	local accum = init
	local next: { any } = { self:next() }
	while next[1] ~= controlFlow.None do
		local newValue = (f :: any)(accum, self:_getInputTuple(nil, next[2]))

		if newValue == nil then
			return controlFlow.None
		end

		if controlFlow.isBreak(newValue) then
			return newValue
		end

		accum = newValue
		next = { self:next() }
	end

	return accum
end

local function createChain<K, V>(
	iter: Iter<K, V>,
	other: Iter<K, V>,
	new: (...any) -> ...any
)
	local newIter = new(Chain.new(iter._value, other._value), iter)

	function newIter:_next(last)
		local key, value = self._value:next(last)

		if key == nil then
			self._lastKey = nil
			return nil
		end

		self._iterationCount = 1 + self._iterationCount
		self._lastKey = key
		return key, value
	end

	function newIter:_getInputTuple(key, value)
		key = key or self._lastKey

		-- This can happen if the iterator is already consumed
		if key == nil then
			return controlFlow.None, nil
		end

		value = value or self._value:get({ (key[1] or 0) + 1, key[2] })

		if value == nil then
			warn(
				`'iter' did not find value for key '\{{key[1]}, {key[2]}\}' in table. Did the input table mutate?`
			)
		end

		if value == controlFlow.Nil :: any then
			value = nil
		end

		return key[2], value
	end

	return newIter
end

--- Takes two iterators and creates a new iterator over both in sequence. `chain()` will return a new iterator
--- which will first iterate over values from the first iterator and then over values from the second iterator.
---
--- In other words, it links two iterators together, in a chain.
function Iter.chain<K, V>(self: Iter<K, V>, other: Iter<K, V>): Iter<K, V>
	return createChain(self, other, Iter._new)
end

function Iter._getInputTuple<K, V>(
	self: Iter<K, V>,
	key: K?,
	value: V?
): (Maybe<K>, V?)
	key = key or self._lastKey

	-- This can happen if the iterator is already consumed
	if key == nil then
		return controlFlow.None, nil
	end

	value = value or self._value[key]

	if value == nil then
		warn(
			`'iter' did not find value for key '{key}' in table. Did the input table mutate?`
		)
	end

	if value == controlFlow.Nil :: any then
		value = nil
	end

	return key, value
end

return {
	new = Iter.new,
	Break = controlFlow.Break,
	None = controlFlow.None,
}
