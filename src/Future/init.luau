local task = require("@lune/task")

local Result = require("@lib/Result")

local spawn = require("./spawn")

type Result<T, E> = Result.Result<T, E>

export type Future<T...> = {
	valueList: { any }?,
	afterList: { (T...) -> () },
	yieldList: { thread },

	isComplete: (self: Future<T...>) -> boolean,
	isPending: (self: Future<T...>) -> boolean,

	expect: (self: Future<T...>, Message: string) -> T...,
	unwrap: (self: Future<T...>) -> T...,
	unwrapOr: (self: Future<T...>, T...) -> T...,
	unwrapOrElse: (self: Future<T...>, Else: () -> T...) -> T...,

	after: (self: Future<T...>, Callback: (T...) -> ()) -> (),
	await: (self: Future<T...>) -> T...,
}

local function isComplete<T...>(self: Future<T...>): boolean
	return self.valueList ~= nil
end

local function isPending<T...>(self: Future<T...>): boolean
	return self.valueList == nil
end

local function expect<T...>(self: Future<T...>, Message: string): T...
	assert(self.valueList, Message)

	return table.unpack(self.valueList)
end

local function unwrap<T...>(self: Future<T...>): T...
	return self:expect("Attempt to unwrap pending future!")
end

local function unwrapOr<T...>(self: Future<T...>, ...): T...
	if self.valueList then
		return table.unpack(self.valueList)
	else
		return ...
	end
end

local function unwrapOrElse<T...>(self: Future<T...>, Else: () -> T...): T...
	if self.valueList then
		return table.unpack(self.valueList)
	else
		return Else()
	end
end

local function after<T...>(self: Future<T...>, cb: (T...) -> ()): T...
	if self.valueList then
		spawn(cb, table.unpack(self.valueList))
	else
		table.insert(self.afterList, cb)
	end
end

local function await<T...>(self: Future<T...>): T...
	if self.valueList then
		return table.unpack(self.valueList)
	else
		table.insert(self.yieldList, coroutine.running())

		return coroutine.yield()
	end
end

local function Future<T..., A...>(cb: (A...) -> T..., ...: A...): Future<T...>
	local self: Future<T...> = {
		valueList = nil,
		afterList = {},
		yieldList = {},

		isComplete = isComplete,
		isPending = isPending,

		expect = expect,
		unwrap = unwrap,
		unwrapOr = unwrapOr,
		unwrapOrElse = unwrapOrElse,

		after = after,
		await = await,
	} :: any

	spawn(function(self: Future<T...>, cb: (A...) -> T..., ...: A...)
		local valueList = { cb(...) }
		self.valueList = valueList

		for _, Thread in self.yieldList do
			task.spawn(Thread, table.unpack(valueList))
		end

		for _, cb in self.afterList do
			spawn(cb, table.unpack(valueList))
		end
	end, self, cb, ...)

	return self
end

local function try<T, A...>(cb: (A...) -> T, ...: A...): Future<Result<T, string>>
	return Future(Result.from, cb, ...)
end

local function awaitAll<T, U>(futures: { [U]: Future<T> }): { [U]: T }
	local result = {}

	for key, future in futures do
		result[key] = future:await()
	end

	return result
end

return {
	awaitAll = awaitAll,
	new = Future,
	try = try,
}
