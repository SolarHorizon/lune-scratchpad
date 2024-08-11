local roblox = require("@lune/roblox")

local getRobloxAsset = require("./getRobloxAsset")

--[=[
	@within rojo

	Reads a place file from the Roblox website
]=]
local function readPlaceAsset(
	placeId: number,
	version: number?
): roblox.DataModel
	local ok = false
	local dataModel: roblox.DataModel

	-- The endpoint used to download assets will sometimes give us compressed
	-- data, even if we explicitly say we don't support compression.
	repeat
		local response = getRobloxAsset(placeId, version)

		if response.ok then
			ok, dataModel = pcall(roblox.deserializePlace, response.body)
		end
	until ok

	return dataModel
end

return readPlaceAsset
