local fs = require("@lune/fs")

local efs = require("@lib/efs")
local getHomeDir = require("./getHomeDir")

type GetConfigDirOptions = {
	createIfNotFound: boolean,
}

local function getConfigDir(options: GetConfigDirOptions): string?
	local home = getHomeDir()

	if not home then
		return nil
	end

	local config = home .. "/.config"

	if not fs.isDir(config) then
		if options.createIfNotFound then
			efs.makeDirAll(config)
		else
			return nil
		end
	end

	return home .. "/.config"
end

return getConfigDir
