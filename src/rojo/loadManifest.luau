local fs = require("@lune/fs")
local getProjectName = require("./getProjectName")
local serde = require("@lune/serde")

type Properties = { [string]: any }

type Node = {
	["$className"]: string,
	["$path"]: string,
	["$properties"]: Properties?,
	["$ignoreUnknownInstances"]: boolean,
	[string]: Node,
}

type RojoManifest = {
	name: string,
	tree: Node,
	servePort: number?,
	servePlaceIds: { number }?,
	placeId: number?,
	gameId: number?,
	serveAddress: string?,
	globIgnorePaths: { string }?,
}

--[=[
	@within rojo
]=]
local function loadManifest(file: string): RojoManifest
	local name = getProjectName(file)

	assert(
		name ~= nil,
		`This file does not have a valid project name:\n\t{file}`
	)

	local manifest: RojoManifest = serde.decode("json", fs.readFile(file))

	assert(
		typeof(manifest.name) == "string",
		`{name}.project.json is missing the "name" property.`
	)
	assert(
		typeof(manifest.tree) == "table",
		`{name}.project.json does not have a valid tree.`
	)
	assert(
		typeof(manifest.tree["$className"]) ~= nil,
		`{name}.project.json is missing the "$className" property.`
	)

	return manifest
end

return loadManifest
