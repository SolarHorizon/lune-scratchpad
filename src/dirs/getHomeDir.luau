local process = require("@lune/process")

local function getHomeDir(): string?
	return if process.os == "windows"
		then process.env.USERPROFILE
		else process.env.HOME
end

return getHomeDir
