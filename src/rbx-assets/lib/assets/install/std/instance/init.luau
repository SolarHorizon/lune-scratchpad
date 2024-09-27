local createFilter = require("./createFilter")
local createMatcher = require("./createMatcher")
local find = require("./find")
local safeDestroy = require("./safeDestroy")

export type FilterOptions = createFilter.Options
export type MatcherOptions = createMatcher.Options

return {
	createFilter = createFilter,
	createMatcher = createMatcher,
	find = find,
	safeDestroy = safeDestroy,
}
