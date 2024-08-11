local normalizePath = require("./normalizePath")

--[=[
	@within efs
]=]
local function getParentDir(path: string)
	local segments = string.split(normalizePath(path), "/")
	table.remove(segments, #segments)
	return table.concat(segments, "/")
end

return getParentDir
