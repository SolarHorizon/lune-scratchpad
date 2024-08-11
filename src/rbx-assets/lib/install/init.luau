local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local gt = require("@pkg/greentea")

local Future = require("@lib/Future")
local Iter = require("@lib/Iter")
local Result = require("@lib/Result")
local batchGetAssets = require("@lib/rbx-api/assets/batchGetAssets")
local request = require("@lib/request/sync")
local withCookie = require("@lib/rbx-api/withCookie")

local Error = require("../Error")
local installers = require("./installers")
local rbxDecode = require("./rbxDecode")
local sandbox = require("./sandbox")
local types = require("./types")

local Ok = Result.Ok

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
}

local download = withCookie(function(cookie, name, url)
	return request({
			url = url,
			method = "GET",
			headers = { Cookie = cookie },
		})
		:mapErr(function(err)
			return Error.DownloadPlaceError(name, tostring(err))
		end)
		:andThen(function(body)
			return rbxDecode(body, "place", gt.isA.DataModel)
		end)
end)

local function prepareDataModels(
	results: { [string]: Result<DataModel> },
	lockfile: Lockfile
)
	return Iter.new(results)
		:map(function(name, game)
			return {
				name = name,
				dataModel = game,
				installer = lockfile.places[name].installer,
			}
		end)
		:intoResult()
end

local function batchGetFromLockfile(
	cookie,
	lockfile: Lockfile
): Result<{ [string]: LoadedPlace }>
	local assets: { AssetRequestItem } = {}
	local idMap = {}

	for name, place in lockfile.places do
		table.insert(idMap, name)
		table.insert(assets, {
			assetId = place.placeId,
			version = place.version,
		})
	end

	return batchGetAssets(cookie, assets)
		:await()
		:mapErr(function(err)
			return Error.BatchGetAssetError(tostring(err))
		end)
		:andThen(function(batch: { BatchAsset })
			local new = {}

			for i, asset in batch do
				local name = idMap[i]
				new[name] = download(cookie, name, asset.location)
			end

			return Ok(Future.awaitAll(new))
		end)
		:andThen(function(results)
			return prepareDataModels(results, lockfile)
		end)
end

local function buildTree(root: string, tree: InstanceTree)
	if not fs.isDir(root) then
		fs.writeDir(root)
	end

	if typeof(tree) ~= "table" then
		fs.writeFile(`{root}.rbxm`, roblox.serializeModel({ tree }))
		return `{root}.rbxm`
	end

	for name, child in tree :: { [string]: InstanceTree } do
		if typeof(child) == "table" then
			buildTree(`{root}/{name}.rbxm`, child)
		else
			fs.writeFile(`{root}/{name}.rbxm`, roblox.serializeModel({ child }))
		end
	end

	return root
end

local function getInstaller(installer: string?): Result<Installer>
	if not installer then
		return Ok(installers.default)
	end

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
					return Result.from(buildTree, place.installer.script, tree)
				end)
		end)
		:intoResult()
end

local install = withCookie(
	function(cookie: string, lockfile: Lockfile): Result<{}>
		return batchGetFromLockfile(cookie, lockfile):andThen(installPlaces)
	end
)

return install
