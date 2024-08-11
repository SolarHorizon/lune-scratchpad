local None = require("./None")
local copyDeep = require("./copyDeep")
local map = require("./map")
local merge = require("./merge")
local mergeDeep = require("./mergeDeep")
local set = require("./set")

return {
	None = None,
	copyDeep = copyDeep,
	map = map,
	merge = merge,
	mergeDeep = mergeDeep,
	set = set,
}
