local env = require("@lib/dotenv")()

local batchGetAssets = require("@lib/rbx-api/assets/batchGetAssets")
local response = batchGetAssets(env.ROBLOSECURITY, {
	{
		assetId = 18727386004,
	},
	{
		assetId = 13593487680,
	},
}):await()

--local getAsset = require("@lib/rbx-api/assets/getAsset")
--local response = getAsset(13593487680, 100):await()

response:match({
	Ok = function(result)
		print(result)
	end,
	Err = function(err)
		print(tostring(err))
	end,
})
