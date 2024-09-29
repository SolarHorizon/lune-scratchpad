local dotenv = require("@lib/dotenv")

local env = dotenv()

-- local listAssetVersions = require("../assets/listAssetVersions")
--
-- listAssetVersions(env.BLOX_ASSETS_KEY :: string, 13593487680)
-- 	:await()
-- 	:inspectErr(function(err)
-- 		print(tostring(err))
-- 	end)
-- 	:inspect(function(response)
-- 		print(response)
-- 	end)

local getAsset = require("../assets/getAsset")

print(getAsset(env.BLOX_ASSETS_KEY :: string, 13593487680):await():unwrap())

-- print(net.request({
-- 	url = "https://apis.roblox.com/v1/assets/13593487680",
-- 	headers = {
-- 		["x-api-key"] = env.BLOX_ASSETS_KEY :: string,
-- 	},
-- }).body)
