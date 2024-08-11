local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local efs = require("@lib/efs")
local open = require("@lib/util/open")
local term = require("@lib/term")

local getProjectName = require("./getProjectName")
local loadManifest = require("./loadManifest")

local BUILD_DIR = "./build"

--[=[
	@within rojo
	@prop Project Project
]=]

--[=[
	@within Project
	@type ProjectType "place" | "model"
]=]
type ProjectType = "place" | "model"

--[=[
	@within Project
	@type BuildFormat "binary" | "xml"
]=]
type BuildFormat = "binary" | "xml"

type ProjectImpl = {
	__index: ProjectImpl,
	fromFile: (filePath: string) -> Project,
	fromName: (filePath: string) -> Project,
	build: (self: Project, format: BuildFormat?) -> string,
	deploy: (self: Project) -> net.FetchResponse,
	load: (self: Project) -> roblox.Instance | roblox.DataModel,
	open: (self: Project) -> (),
}

export type Project = typeof(setmetatable(
	{} :: {
		path: string,
		name: string,
		type: ProjectType,
		gameId: number?,
		placeId: number?,
	},
	{} :: ProjectImpl
))

--[=[
	@within Project
	@prop path string
]=]

--[=[
	@within Project
	@prop name string
]=]

--[=[
	@within Project
	@prop type ProjectType
]=]

--[=[
	@within Project
	@prop gameId number?
]=]

--[=[
	@within Project
	@prop placeId number?
]=]

--[=[
	@class Project

	```lua
	local Project = require("lib/rojo/Project")
	```
]=]
local Project = {} :: ProjectImpl
Project.__index = Project

--[=[
	@within Project
]=]
function Project.fromFile(file: string): Project
	file = efs.normalizePath(file)

	local manifest = loadManifest(file)
	local className = manifest.tree["$className"]

	local self = {
		name = getProjectName(file) :: string,
		gameId = manifest.gameId,
		placeId = manifest.placeId,
		path = file,
		type = (
				if className == "DataModel" then "place" else "model"
			) :: ProjectType,
	}

	if self.type == "place" then
		self.placeId = manifest.placeId
		self.gameId = manifest.gameId
	end

	return setmetatable(self, Project)
end

--[=[
	@within Project
]=]
function Project.fromName(name: string): Project
	return Project.fromFile(
		efs.normalizePath(`{process.cwd}{name}.project.json`)
	)
end

--[=[
	@within Project
]=]
function Project:build(format: BuildFormat?): string
	efs.makeDirAll(BUILD_DIR)

	local extension = if self.type == "model" then "rbxm" else "rbxl"

	if format == "xml" then
		extension = extension .. "x"
	end

	local output = `{BUILD_DIR}/{self.name}.{extension}`

	local result = process.spawn("rojo", {
		"build",
		self.path,
		"--output",
		output,
	})

	assert(
		result.ok,
		`An error occured while building the project.\n{result.stderr}`
	)

	return output
end

--[=[
	@within Project
]=]
function Project:open()
	assert(
		self.type == "place",
		`Could not open "{self.name}" because it is a model.`
	)
	open(self:build())
end

--[=[
	@within Project
]=]
function Project:load(): roblox.Instance | roblox.DataModel
	local file = fs.readFile(self:build())

	if self.type == "place" then
		return roblox.deserializePlace(file)
	end

	local instance = roblox.deserializeModel(file)

	assert(
		#instance < 2,
		`Model file for project {self.name} has more than one root instance.`
	)
	assert(
		#instance > 0,
		`Model file for project {self.name} has more than one root instance.`
	)

	return instance[1]
end

--[=[
	@within Project
	@yields
]=]
function Project:deploy(): net.FetchResponse
	assert(
		self.type == "place",
		`Could not deploy "{self.name}" because it is a model.`
	)
	assert(
		self.gameId ~= nil,
		`Could not deploy "{self.name}" because it does not have a gameId.`
	)
	assert(
		self.placeId ~= nil,
		`Could not deploy "{self.name}" because it does not have a placeId.`
	)

	local file = self:build()

	local response = net.request({
		url = `https://api.roblox.com/universes/v1/{self.gameId}/places/{self.placeId}/versions`,
		headers = {
			["x-api-key"] = process.env.DEPLOY_KEY,
			["Content-Type"] = "application/octet-stream",
		},
		query = {
			versionType = "Published",
		},
		body = file,
	})

	if not response.ok then
		term.errPrint(
			`An error occured while deploying {self.name}`,
			response.body
		)
	end

	return response
end

return Project
