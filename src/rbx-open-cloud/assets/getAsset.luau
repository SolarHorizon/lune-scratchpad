local net = require("@lune/net")

local Future = require("@lib/Future")
local jsonDecode = require("@lib/request/jsonDecode")
local request = require("@lib/request/sync")

local types = require("./types")

type Asset = types.Asset

local function getAsset(apiKey: string, assetId: number, readMask: { string }?)
	if readMask then
		readMask = net.urlEncode(table.concat(readMask, ",")) :: any
	end

	return Future.new(function()
		return request({
			url = `https://apis.roblox.com/assets/v1/assets/{assetId}`,
			method = "GET",
			query = {
				readMask = readMask :: any,
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
