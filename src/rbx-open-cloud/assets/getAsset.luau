local net = require("@lune/net")

local Future = require("@lib/Future")
local jsonDecode = require("@lib/request/jsonDecode")
local request = require("@lib/request/sync")

local types = require("./types")

type Asset = types.Asset

local function getAsset(apiKey: string, assetId: number, readMask: { string })
	return Future.new(function()
		return request({
			url = `https://apis.roblox.com/v1/assets/{assetId}`,
			method = "GET",
			query = {
				readMask = net.urlEncode(table.concat(readMask, ",")),
			},
			headers = {
				["x-api-key"] = apiKey,
			},
		}):andThen(function(body)
			return jsonDecode(body, types.Asset)
		end)
	end)
end

return getAsset
