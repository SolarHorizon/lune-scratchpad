local roblox = require("@lune/roblox")

local global = require("../../types")

export type Lockfile = global.Lockfile
export type InstallerConfig = global.InstallerConfig

export type InstanceTree = roblox.Instance | {
	[string]: InstanceTree,
}

export type Installer = (
	game: roblox.DataModel,
	options: { [string]: any }
) -> InstanceTree

return nil
