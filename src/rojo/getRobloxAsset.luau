local net = require("@lune/net")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local term = require("@lib/term")

local dotenv = require("@lib/dotenv")

--[=[
	@within rojo
	@yields

	Download an asset from the Roblox website
]=]
local function getRobloxAsset(assetId: number, version: number?)
	local env = dotenv()

	local cookie = roblox.getAuthCookie()
		or `.ROBLOSECURITY={env.ROBLOSECURITY}; Domain=.roblox.com`

	if cookie == nil then
		term.errPrint("Could not authenticate user.")
		process.exit(1)
		error("unreachable")
	end

	local response = net.request({
		url = "https://assetdelivery.roblox.com/v1/asset/",
		headers = {
			["Cookie"] = cookie,
		},
		query = {
			id = tostring(assetId),
			version = (if version then tostring(version) else nil) :: string,
		},
	})

	return response
end

return getRobloxAsset
