--!strict
local Error = require("./Error")
local generateConfig = require("./config/generateConfig")
local generateLockfile = require("./config/generateLockfile")
local install = require("./install")
local readConfig = require("./config/readConfig")
local readLockfile = require("./config/readLockfile")
local types = require("./types")

export type Error = Error.Error
export type Lockfile = types.Lockfile
export type PlaceLock = types.PlaceLock
export type Config = types.Config
export type PlaceConfig = types.PlaceConfig
export type RawConfig = types.RawConfig

return {
	Error = Error,
	generateConfig = generateConfig,
	generateLockfile = generateLockfile,
	install = install,
	readConfig = readConfig,
	readLockfile = readLockfile,
	types = types,
}
