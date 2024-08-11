local process = require("@lune/process")

local getHomeDir = require("./getHomeDir")

local function getCacheDir(): string?
	if process.os == "linux" then
		local path = process.env.XDG_CACHE_HOME

		if path then
			return path
		end
	end

	local home = getHomeDir()

	if home then
		if process.os == "macos" then
			return home .. "/Library/Caches"
		else
			return home .. "/.cache"
		end
	end

	return nil
end

return getCacheDir
