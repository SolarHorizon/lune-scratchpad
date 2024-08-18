local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local Future = require("@lib/Future")
local Iter = require("@lib/Iter")
local Result = require("@lib/Result")
local batchGetAssets = require("@lib/rbx-api/assets/batchGetAssets")
local immutable = require("@lib/immutable")
local withCookie = require("@lib/rbx-api/withCookie")

local Error = require("../Error")
local cache = require("../cache")
local download = require("../download")
local installers = require("./installers")
local sandbox = require("./sandbox")
local types = require("./types")

local Ok, Err = Result.Ok, Result.Err

type AssetRequestItem = batchGetAssets.AssetRequestItem
type BatchAsset = batchGetAssets.BatchAsset
type Lockfile = types.Lockfile
type DataModel = roblox.DataModel
type Instance = roblox.Instance
type Error = Error.Error
type Future<T> = Future.Future<T>
type Result<T> = Result.Result<T, Error>
type InstanceTree = types.InstanceTree
type Installer = types.Installer

type LoadedPlace = {
	name: string,
	dataModel: DataModel,
	installer: types.InstallerConfig,
	output: string,
}

local function prepareDataModels(
	results: { [string]: Result<DataModel> },
	lockfile: Lockfile
)
	return Iter.new(results)
		:map(function(name, result: Result<DataModel>)
			return result:map(function(dataModel)
				return {
					name = name,
					dataModel = dataModel,
					installer = lockfile.places[name].installer,
					output = lockfile.places[name].output,
				}
			end)
		end)
		:intoResult()
end

local function downloadBatchResults(cookie, batch: { BatchAsset }, idMap)
	local new = {}

	for i, asset in batch do
		local place = idMap[i]

		if asset.location then
			new[place.name] = download(cookie, place, asset.location)
			continue
		end

		new[place.name] = Future.new(function()
			if not asset.errors then
				return Err(Error.UnknownDownloadPlaceError(place.name))
			end

			local message = ""

			for _, err in asset.errors do
				message ..= `{err.message} ({err.code})\n`
			end

			return Err(Error.DownloadPlaceError(place.name, message))
		end)
	end

	return new
end

local function batchGetUncached(cookie, assets, idMap)
	if next(assets) == nil then
		return Ok({})
	end

	return batchGetAssets(cookie, assets)
		:await()
		:mapErr(function(err)
			return Error.BatchGetAssetError(tostring(err))
		end)
		:map(function(batch: { BatchAsset })
			return Future.awaitAll(downloadBatchResults(cookie, batch, idMap))
		end)
end

local function getAssetsFromLockfile(
	cookie,
	lockfile: Lockfile
): Result<{ [string]: LoadedPlace }>
	local assets: { AssetRequestItem } = {}
	local idMap = {}
	local cached = {}

	for name, place in lockfile.places do
		local cachedAsset = cache.get(place.placeId, place.version)

		if cachedAsset then
			cached[name] = Ok(roblox.deserializePlace(cachedAsset))
			continue
		end

		table.insert(assets, {
			assetId = place.placeId,
			version = place.version,
		})

		-- we can't reuse `assets` because it's being sent directly to the api and
		-- shouldn't contain any additional information
		table.insert(idMap, {
			name = name,
			placeId = place.placeId,
			version = place.version,
		})
	end

	return batchGetUncached(cookie, assets, idMap)
		:map(function(results)
			return immutable.merge(cached, results)
		end)
		:andThen(function(results)
			return prepareDataModels(results, lockfile)
		end)
end

local function buildTree(root: string, tree: InstanceTree)
	if not fs.isDir(root) then
		fs.removeDir(root)
	end

	fs.writeDir(root)

	if typeof(tree) ~= "table" then
		fs.writeFile(`{root}.rbxm`, roblox.serializeModel({ tree }))
		return `{root}.rbxm`
	end

	for name, child in tree :: { [string]: InstanceTree } do
		if typeof(child) == "table" then
			buildTree(`{root}/{name}`, child)
		else
			fs.writeFile(`{root}/{name}.rbxm`, roblox.serializeModel({ child }))
		end
	end

	return root
end

local function getInstaller(installer: string): Result<Installer>
	local builtin = string.match(installer, "^@(.+)")

	if builtin and installers[builtin] then
		return Ok(installers[builtin])
	end

	return sandbox(installer)
end

local function installPlaces(places: { [string]: LoadedPlace }): Result<{}>
	return Iter.new(places)
		:map(function(_, place: LoadedPlace)
			return getInstaller(place.installer.script)
				:andThen(function(run: Installer)
					return Result.from(
						run,
						place.dataModel,
						place.installer.options or {}
					)
				end)
				:andThen(function(tree: InstanceTree)
					return Result.from(buildTree, place.output, tree)
				end)
		end)
		:intoResult()
end

local install = withCookie(
	function(cookie: string?, lockfile: Lockfile): Result<{}>
		return getAssetsFromLockfile(cookie, lockfile):andThen(installPlaces)
	end
)

return install
