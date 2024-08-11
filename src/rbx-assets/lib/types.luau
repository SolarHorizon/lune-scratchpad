local gt = require("@pkg/greentea")

local InstallerConfig = {
	options = gt.opt(gt.dictionary(gt.string(), gt.any())),
	script = gt.string(),
}

export type InstallerConfig = typeof(InstallerConfig)

local PlaceLock = {
	placeId = gt.number({ integer = true }),
	installer = InstallerConfig,
	version = gt.number(),
}

export type PlaceLock = typeof(PlaceLock)

local Lockfile = {
	places = gt.dictionary(gt.string(), PlaceLock),
}

export type Lockfile = typeof(Lockfile)

local function gtPlaceConfig<T>(installerType: T)
	return {
		placeId = gt.number({ integer = true }),
		installer = installerType,
		output = gt.string(),
	}
end

local PlaceConfig = gtPlaceConfig(InstallerConfig)

export type PlaceConfig = typeof(PlaceConfig)

local Config = {
	places = gt.dictionary(gt.string(), PlaceConfig),
}

export type Config = typeof(Config)

local RawPlaceConfig = gtPlaceConfig(gt.oneOf(InstallerConfig, gt.string()))

export type RawPlaceConfig = typeof(RawPlaceConfig)

local RawConfig = {
	places = gt.dictionary(gt.string(), RawPlaceConfig),
}

export type RawConfig = typeof(RawConfig)

return {
	Config = Config,
	InstallerConfig = InstallerConfig,
	Lockfile = Lockfile,
	PlaceConfig = PlaceConfig,
	PlaceLock = PlaceLock,
	RawPlaceConfig = RawPlaceConfig,
	RawConfig = RawConfig,
}
