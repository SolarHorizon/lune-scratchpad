local process = require("@lune/process")

local getHomeDir = require("./getHomeDir")

local function getDocumentsDir(): string?
	if process.os == "linux" then
		local path = process.env.XDG_DOCUMENTS_DIR

		if path then
			return path
		end
	end

	local home = getHomeDir()

	if home then
		return home .. "/Documents"
	end

	return nil
end

return getDocumentsDir
