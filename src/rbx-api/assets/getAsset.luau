local jsonDecode = require("@lib/request/jsonDecode")
local request = require("@lib/request/sync")
local withCookie = require("@lib/rbx-api/withCookie")

local types = require("./types")

--[=[
	@within rbx-api

	Download an asset from the Roblox website
]=]
local getAsset = withCookie(function(cookie, assetId: number, version: number)
	return request({
		url = `https://assetdelivery.roblox.com/v2/asset`,
		method = "GET",
		headers = {
			Accept = "application/json",
			Cookie = cookie,
		},
		query = {
			id = tostring(assetId),
			version = tostring(version),
		},
	}):andThen(function(body)
		return jsonDecode(body, types.Asset)
	end)
end)

return getAsset
