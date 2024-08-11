-- local process = require("@lune/process")
local datetime = require("@lune/datetime")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local net = require("@lune/net")
local regex = require("@lune/regex")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local Error = require("../Error")
local Result = require("@lib/Result")
local types = require("./types")

type Error = Error.Error
type Result<T> = Result.Result<T, Error>
type InstanceTree = types.InstanceTree
type Installer = types.Installer

local function lock<T>(table: T)
	return setmetatable(table :: any, {
		__index = table,
		__metatable = "locked",
		__tostring = function()
			return stdio.format(table)
		end,
	})
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
		write = stdio.write,
		ewrite = stdio.ewrite,
	},
	["@lune/datetime"] = lock(datetime),
	["@lune/serde"] = lock(serde),
	["@lune/regex"] = lock(regex),
	["@lune/task"] = lock(task),
}

local sandboxEnv = {}

function sandboxEnv.getfenv()
	error("getfenv is disabled for install scripts")
end

function sandboxEnv.setfenv()
	error("setfenv is disabled for install scripts")
end

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

function sandboxEnv.require(target: string)
	local module = ENABLED_LIBRARIES[target]

	if module then
		return module
	else
		local contents = readScript(target)

		local evalChunk = luau.load(contents, sandboxEnv)
		return evalChunk()
	end
end

local function sandbox(filePath: string): Result<Installer>
	local environment = table.clone(sandboxEnv)

	function environment.print(...)
		local header = `---- Output from {filePath} ----`
		print(header)
		print(tostring(...))
		print(string.rep("-", #header))
	end

	function environment.warn(...)
		environment.print(stdio.color("yellow"), ..., stdio.color("reset"))
	end

	return Result.from(readScript, filePath)
		:mapErr(function()
			return (Error.InvalidInstallerPath(filePath))
		end)
		:andThen(function(content)
			return Result.from(
				luau.load,
				content,
				table.freeze({
					debugName = filePath,
					environment = sandboxEnv,
				})
			):mapErr(function(err)
				return Error.InstallerError(tostring(err))
			end)
		end)
end

return sandbox
