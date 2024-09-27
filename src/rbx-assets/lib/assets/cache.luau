local fs = require("@lune/fs")
local serde = require("@lune/serde")

local dirs = require("@lib/dirs")
local efs = require("@lib/efs")

local constants = require("../constants")

local function getCacheDir()
	local root = dirs.getCacheDir() or "./.cache"
	return efs.makeDirAll(efs.normalizePath(`{root}/{constants.PROG_NAME}`))
end

local function getAssetFile(placeId: number, version: number)
	return efs.makeDirAll(`{getCacheDir()}/{tostring(placeId)}/`)
		.. tostring(version)
end

local function put(placeId: number, version: number, content: string | buffer)
	local asset = getAssetFile(placeId, version)

	if fs.isFile(asset) then
		return
	end

	fs.writeFile(asset, serde.compress("brotli", content))
end

local function get(placeId: number, version: number): string?
	local asset = getAssetFile(placeId, version)

	if fs.isFile(asset) then
		return serde.decompress("brotli", fs.readFile(asset))
	end

	return nil
end

local function remove(placeId: number, version: number)
	local asset = getAssetFile(placeId, version)

	if fs.isFile(asset) then
		fs.removeFile(asset)
	end
end

return {
	put = put,
	get = get,
	remove = remove,
}
