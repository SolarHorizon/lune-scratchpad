--!strict
local readConfig = require("./config/readConfig")
local readLockfile = require("./config/readLockfile")

return {
	readConfig = readConfig,
	readLockfile = readLockfile,
}
