return [[
local promise = require(%s)

export type PromiseStatus = "Started" | "Resolved" | "Rejected" | "Cancelled"

export type AnyPromise = {
	andThen: (
		self: AnyPromise,
		successHandler: (...any) -> any,
		failureHandler: ((any) -> any)?
	) -> AnyPromise,
	andThenCall: <T...>(
		self: AnyPromise,
		successHandler: (T...) -> any,
		T...
	) -> AnyPromise,
	andThenReturn: (self: AnyPromise, value: any) -> AnyPromise,
	await: (self: AnyPromise) -> (boolean, ...any),
	awaitStatus: (self: AnyPromise) -> (PromiseStatus, ...any),
	cancel: (self: AnyPromise) -> (),
	catch: (self: AnyPromise, failureHandler: (...any) -> any) -> AnyPromise,
	expect: (self: AnyPromise) -> ...any,
	finally: (
		self: AnyPromise,
		callback: (status: PromiseStatus) -> any
	) -> AnyPromise,
	finallyCall: <T...>(
		self: AnyPromise,
		callback: (T...) -> any,
		T...
	) -> AnyPromise,
	finallyReturn: (self: AnyPromise, value: any) -> AnyPromise,
	getStatus: (self: AnyPromise) -> PromiseStatus,
	now: (self: AnyPromise, rejectionValue: unknown) -> AnyPromise,
	tap: (self: AnyPromise, successHandler: (...any) -> ()) -> AnyPromise,
	timeout: (
		self: AnyPromise,
		seconds: number,
		rejectionValue: unknown
	) -> AnyPromise,
}

export type Promise<T = any> = {
	andThen: (
		self: Promise<T>,
		successHandler: (T) -> any,
		failureHandler: ((...any) -> any)?
	) -> AnyPromise,
	andThenCall: <U...>(
		self: Promise<T>,
		successHandler: (U...) -> any,
		U...
	) -> Promise<T>,
	andThenReturn: (self: Promise<T>, value: any) -> AnyPromise,
	await: (self: Promise<T>) -> (boolean, T | unknown),
	awaitStatus: (self: Promise<T>) -> (PromiseStatus, T),
	cancel: (self: Promise<T>) -> (),
	catch: (self: Promise<T>, failureHandler: (any) -> any) -> Promise<T>,
	expect: (self: Promise<T>) -> T,
	finally: (
		self: Promise<T>,
		callback: (status: PromiseStatus) -> any
	) -> AnyPromise,
	finallyCall: <U...>(
		self: Promise<T>,
		callback: (U...) -> any,
		U...
	) -> AnyPromise,
	finallyReturn: (self: Promise<T>, value: any) -> AnyPromise,
	getStatus: (self: Promise<T>) -> PromiseStatus,
	now: (self: Promise<T>, rejectionValue: unknown) -> Promise<T>,
	tap: (self: Promise<T>, successHandler: (T) -> ()) -> Promise<T>,
	timeout: (
		self: Promise<T>,
		seconds: number,
		rejectionValue: unknown
	) -> Promise<T>,
}

export type PromiseStatic = {
	Status: {
		Started: "Started",
		Resolved: "Resolved",
		Rejected: "Rejected",
		Cancelled: "Cancelled",
	},
	all: <T>(promises: { Promise<T> }) -> Promise<{ T }>,
	allSettled: (promises: { Promise<any> }) -> Promise<{ PromiseStatus }>,
	any: <T>(promises: { Promise<T> }) -> Promise<T>,
	defer: <T>(
		resolver: (resolve: (T | Promise<T>) -> (), reject: (any) -> ()) -> ()
	) -> Promise<T>,
	delay: (seconds: number) -> Promise<number>,
	each: <T, U>(
		list: { T | Promise<T> },
		predicate: (T, number) -> (U | Promise<U>)
	) -> Promise<{ U }>,
	fold: <T, U>(
		promises: { T | Promise<T> },
		reducer: (U, T, number) -> (U | Promise<U>),
		initialValue: U
	) -> Promise<U>,
	fromEvent: <A...>(
		event: RBXScriptSignal<A...>,
		predicate: (A...) -> boolean
	) -> Promise,
	is: (value: any) -> boolean,
	new: <T>(
		resolver: (resolve: (T | Promise<T>) -> (), reject: (any) -> ()) -> ()
	) -> Promise<T>,
	onUnhandledRejection: (
		<T, A...>(callback: (promise: Promise<T>, A...) -> ()) -> ()
	) -> (() -> ()),
	promisify: <R, A...>(fn: (A...) -> R) -> (A...) -> Promise<R>,
	race: <T>(promises: { Promise<T> }) -> Promise<T>,
	reject: (value: any) -> Promise<never>,
	resolve: <T>(value: T | Promise<T>) -> Promise<T>,
	retry: <T, A...>(
		callback: ((A...) -> T),
		times: number,
		A...
	) -> Promise<T>,
	retryWithDelay: <T, A...>(
		callback: ((A...) -> T),
		times: number,
		seconds: number,
		A...
	) -> Promise<T>,
	some: <T>(promises: { Promise<T> }, count: number) -> Promise<{ T }>,
	try: <T, A...>(callback: ((A...) -> T), A...) -> Promise<T>,
}

return (promise :: any) :: PromiseStatic
]]
