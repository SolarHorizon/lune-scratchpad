local efs = require("@lib/efs")
local fs = require("@lune/fs")
local immutable = require("@lib/immutable")
local serde = require("@lune/serde")

export type RbxConfig = {
	build: { default: { string } },
	run: { default: string },
}

local default = {
	build = {
		default = {
			"default",
		},
	},
	run = {
		default = "default",
	},
	-- test = {
	-- 	port = 25428,
	-- 	roots = {
	-- 		"ReplicatedStorage",
	-- 		"ServerStorage",
	-- 	},
	-- },
}

--[=[
	@within rbx

	Gets the rbx config from the `rbx.yml` file found in the current directory.
	If one does not exist, it will return a default config.
]=]
local function getConfig(): RbxConfig
	local config = table.clone(default)

	local files = efs.findFiles({ "./rbx.yml", "./rbx.yaml" })

	if #files > 0 then
		local content = fs.readFile(files[1])
		config = immutable.mergeDeep(default, serde.decode("yaml", content))
	end

	return config
end

return getConfig
