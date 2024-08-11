local fs = require("@lune/fs")
local serde = require("@lune/serde")

local dotenv = require("@lib/dotenv")

local env = dotenv()

local generateLock = require("../lib/config/generateLock")

generateLock(env.RBX_ASSETS_KEY :: string):after(function(lockfile)
	lockfile:match({
		Ok = function(content)
			fs.writeFile("./rbx-assets.lock", serde.encode("json", content))
			print("Created rbx-assets.lock")
		end,
		Err = function(err)
			print(tostring(err))
		end,
	})
end)
