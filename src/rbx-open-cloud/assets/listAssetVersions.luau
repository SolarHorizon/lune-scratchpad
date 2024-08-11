local gt = require("@pkg/greentea")

local Error = require("@lib/request/Error")
local Future = require("@lib/Future")
local Result = require("@lib/Result")
local jsonDecode = require("@lib/request/jsonDecode")
local request = require("@lib/request/sync")

local types = require("./types")

type Future<T> = Future.Future<T>
type Result<T> = Result.Result<T, Error>
type Error = Error.Error
type AssetVersion = types.AssetVersion

local function maybeStr(value: any?): string
	return (if value then tostring(value) else nil) :: string
end

local AssetVersions = {
	assetVersions = gt.array(types.AssetVersion),
	nextPageToken = gt.string(),
}

export type AssetVersions = typeof(AssetVersions)

local function listAssetVersions(
	apiKey: string,
	assetId: number,
	maxPageSize: number?,
	pageToken: string?
): Future<Result<typeof(AssetVersions)>>
	return Future.new(function()
		return request({
			url = `https://apis.roblox.com/assets/v1/assets/{assetId}/versions`,
			method = "GET",
			headers = {
				["x-api-key"] = apiKey,
			},
			query = {
				maxPageSize = maybeStr(maxPageSize),
				pageToken = maybeStr(pageToken),
			},
		}):andThen(function(body)
			return jsonDecode(body, AssetVersions)
		end)
	end)
end

return listAssetVersions
