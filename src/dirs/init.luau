local getCacheDir = require("./getCacheDir")
local getDocumentsDir = require("./getDocumentsDir")
local getHomeDir = require("./getHomeDir")
local getWindowsHomeDir = require("./getWindowsHomeDir")

return {
	getCacheDir = getCacheDir,
	getDocumentsDir = getDocumentsDir,
	getHomeDir = getHomeDir,
	getWindowsHomeDir = getWindowsHomeDir,
}
