local Future = require("@lib/Future")
local jsonDecode = require("@lib/request/jsonDecode")
local request = require("@lib/request/sync")

local types = require("./types")

local function getAssetVersion(apiKey: string, assetId: number, version: number)
	return Future.new(function()
		return request({
			url = `https://apis.roblox.com/v1/assets/{assetId}/versions/{version}`,
			method = "GET",
			headers = {
				["x-api-key"] = apiKey,
			},
		}):andThen(function(body)
			return jsonDecode(body, types.AssetVersion)
		end)
	end)
end

return getAssetVersion
