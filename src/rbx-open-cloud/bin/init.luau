local dotenv = require("@lib/dotenv")

local env = dotenv()

local listAssetVersions = require("../assets/listAssetVersions")

listAssetVersions(env.RBX_ASSETS_KEY :: string, 13593487680)
	:await()
	:inspectErr(function(err)
		print(tostring(err))
	end)
	:inspect(function(response)
		print(response)
	end)
