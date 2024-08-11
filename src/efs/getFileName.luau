local normalizePath = require("./normalizePath")

--[=[
	@within efs
]=]
local function getFileName(path: string): string?
	local segments = string.split(normalizePath(path), "/")
	return segments[#segments]
end

return getFileName
