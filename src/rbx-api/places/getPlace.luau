local jsonDecode = require("@lib/request/jsonDecode")
local request = require("@lib/request/sync")

local types = require("./types")
local withCookie = require("../withCookie")

export type Place = types.Place

local getPlace = withCookie(function(cookie: string, placeId: number)
	return request({
		url = `https://develop.roblox.com/v2/places/{placeId}`,
		method = "GET",
		headers = {
			accept = "application/json",
			Cookie = cookie,
		},
	}):andThen(function(body)
		return jsonDecode(body, types.Place)
	end)
end)

return getPlace
