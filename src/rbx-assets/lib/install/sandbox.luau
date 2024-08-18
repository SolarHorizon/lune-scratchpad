local datetime = require("@lune/datetime")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local net = require("@lune/net")
local regex = require("@lune/regex")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local greentea = require("./std/greentea")
local installer = require("./std/installer")
local instance = require("./std/instance")
local text = require("./std/text")

local Error = require("../Error")
local Result = require("@lib/Result")
local constants = require("../constants")
local types = require("./types")

type Error = Error.Error
type Result<T> = Result.Result<T, Error>
type InstanceTree = types.InstanceTree
type Installer = types.Installer

local WRITE = stdio.write
local EWRITE = stdio.ewrite

local PROG_NAME = constants.PROG_NAME

local function readScript(target: string): string
	local content: string

	if fs.isFile(target) then
		content = fs.readFile(target)
		return content
	end

	if fs.isDir(target) then
		if fs.isFile(target .. "/init.luau") then
			content = fs.readFile(target .. "/init.luau")
		end

		if fs.isFile(target .. "/init.lua") then
			content = fs.readFile(target .. "init.lua")
		end
	end

	if content == nil then
		for _, ext in { ".luau", ".lua" } do
			local targetExt = target .. ext
			if fs.isFile(targetExt) then
				content = fs.readFile(targetExt)
			end
		end

		if content == nil then
			error(`No such file or directory \`{target}\``)
		end
	end

	return content
end

local function sandbox(filePath: string): Result<Installer>
	local environment = {}

	local tag = `[installer "{filePath}"]`

	local function write(s: string)
		WRITE(`{tag} {s}`)
	end

	local function ewrite(s: string)
		EWRITE(`{tag} {s}`)
	end

	environment.print = function(...)
		WRITE(`\n{tag}`)

		for i = 1, select("#", ...) do
			WRITE(` {stdio.format(select(i, ...))}`)
		end
	end

	function environment.warn(...)
		EWRITE(`\n{tag}`)
		EWRITE(stdio.color("yellow"))

		for i = 1, select("#", ...) do
			EWRITE(` {stdio.format(select(i, ...))}`)
		end

		EWRITE(stdio.color("reset"))
	end

	local ENABLED_LIBRARIES = {
		["@lune/net"] = {
			urlEncode = net.urlEncode,
			urlDecode = net.urlDecode,
			jsonEncode = net.jsonEncode,
			jsonDecode = net.jsonDecode,
		},
		["@lune/roblox"] = {
			Instance = roblox.Instance,
			getReflectionDatabase = roblox.getReflectionDatabase,
		},
		["@lune/stdio"] = {
			color = stdio.color,
			format = stdio.format,
			prompt = stdio.prompt,
			style = stdio.style,
			write = write,
			ewrite = ewrite,
		},
		["@lune/datetime"] = datetime,
		["@lune/serde"] = serde,
		["@lune/regex"] = regex,
		["@lune/task"] = task,

		-- luau type system doesn't like PROG_NAME, so i have to cast to any
		[`@{PROG_NAME}/greentea`] = greentea :: any,
		[`@{PROG_NAME}/installer`] = installer,
		[`@{PROG_NAME}/instance`] = instance,
		[`@{PROG_NAME}/text`] = text,
	}

	function environment.getfenv()
		error("getfenv is disabled for install scripts")
	end

	function environment.setfenv()
		error("setfenv is disabled for install scripts")
	end

	function environment.require(target: string)
		local module = ENABLED_LIBRARIES[target]

		if module then
			return module
		else
			local contents = readScript(target)

			local evalChunk = luau.load(contents, {
				debugName = target,
				environment = environment,
			})
			return evalChunk()
		end
	end

	return Result.from(readScript, filePath)
		:mapErr(function()
			return Error.InvalidInstallerPath(filePath)
		end)
		:andThen(function(content)
			return Result.from(
				luau.load,
				content,
				table.freeze({
					debugName = filePath,
					environment = table.freeze(environment),
				})
			)
				:andThen(function(install)
					return Result.from(install)
				end)
				:mapErr(function(err)
					return Error.InstallerError(tostring(err))
				end)
		end)
end

return sandbox
