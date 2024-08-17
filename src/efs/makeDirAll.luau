local fs = require("@lune/fs")
local normalizePath = require("./normalizePath")

--[=[
	@within efs

	Creates a directory at the given path. If any parent directories do not 
	exist, it will create them too.
]=]
local function makeDirAll(path: string)
	local segments = string.split(normalizePath(path), "/")
	local dir: string?

	for _, segment in segments do
		local nextDir: string

		if dir then
			nextDir = `{dir}/{segment}`
		else
			nextDir = segment
		end

		if not fs.isDir(nextDir) then
			fs.writeDir(nextDir)
		end

		dir = nextDir
	end

	return path
end

return makeDirAll
