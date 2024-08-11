local net = require("@lune/net")

local Result = require("@lib/Result")
local gt = require("@pkg/greentea")
local jsonDecode = require("@lib/request/jsonDecode")
local request = require("@lib/request/sync")
local withCookie = require("@lib/rbx-api/withCookie")

local Error = require("../Error")
local types = require("./types")

local Ok, Err = Result.Ok, Result.Err

type Error = Error.Error
type Result<T> = Result.Result<T, Error>

export type BatchAsset = types.BatchAsset
export type AssetRequestItem = types.AssetRequestItem

local function formatRequests(assets: { AssetRequestItem })
	local ok, err = gt.build(gt.array(types.AssetRequestItem)):matches(assets)

	if not ok then
		return Err(Error.InvalidRequest:append("\n" .. err:formatErr()))
	end

	assets = table.clone(assets)

	for _, asset in assets do
		asset.requestId = "string"
	end

	return Ok(assets)
end

local function createRequest(assets, cookie)
	return request({
		url = "https://assetdelivery.roblox.com/v1/assets/batch",
		method = "POST",
		headers = {
			["Content-Type"] = "application/json",
			["Roblox-Browser-Asset-Request"] = "-1",
			["Roblox-Place-Id"] = "-1",
			Accept = " ",
			accept = "application/json",
			Cookie = cookie,
		},
		body = net.jsonEncode(assets),
	})
end

--[=[
	@within rbx-api

	Batch download assets from the Roblox website
]=]
local batchGetAssets = withCookie(
	function(cookie, assets: { AssetRequestItem }): Result<{ BatchAsset }>
		return formatRequests(assets)
			:andThen(function(assetRequests)
				return createRequest(assetRequests, cookie)
			end)
			:andThen(function(body)
				return jsonDecode(body, gt.array(types.BatchAsset))
			end)
	end
)

return batchGetAssets
