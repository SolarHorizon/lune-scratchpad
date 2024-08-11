local fs = require("@lune/fs")
local normalizePath = require("./normalizePath")

--[=[
	@within efs
]=]
local function findFiles(files: { string }): { string }
	local found = {}

	for _, file in files do
		local location = normalizePath(file)

		if fs.isFile(location) then
			table.insert(found, location)
		end
	end

	return found
end

return findFiles
