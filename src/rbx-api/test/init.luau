local env = require("@lib/dotenv")()

-- local batchGetAssets = require("@lib/rbx-api/assets/batchGetAssets")
-- local response = batchGetAssets(env.ROBLOSECURITY, {
-- 	{
-- 		assetId = 13593487680,
-- 	},
-- 	{
-- 		assetId = 15472100873,
-- 	},
-- }):await()

--local getAsset = require("@lib/rbx-api/assets/getAsset")
--local response = getAsset(13593487680, 100):await()

local getPlace = require("@lib/rbx-api/places/getPlace")
local response = getPlace(env.ROBLOSECURITY, 16877409153):await()

response:match({
	Ok = function(result)
		print(result)
	end,
	Err = function(err)
		print(tostring(err))
	end,
})
