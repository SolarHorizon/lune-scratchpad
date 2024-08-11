local datetime = require("@lune/datetime")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local net = require("@lune/net")
local process = require("@lune/process")
local regex = require("@lune/regex")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local function sandbox(filePath: string)
	local DEFAULT_PRINT = print
	local SANDBOXED_ENV = {
		debugName = filePath,
		environment = {
			require = (nil) :: any,
			getfenv = (nil) :: any,
			setfenv = (nil) :: any,
			print = (nil) :: any,
			warn = (nil) :: any,
		},
	}

	local PROMPT_MSG_TMPL = `allow {SANDBOXED_ENV.debugName} to access %s?`
	local DENIED_ERR_TMPL =
		`{SANDBOXED_ENV.debugName} tried to access disallowed library %s!`

	local function discoverAndReadScript(target: string): string
		local scriptContents: string

		if fs.isFile(target) then
			scriptContents = fs.readFile(target)
			return scriptContents
		end

		if fs.isDir(target) then
			if fs.isFile(target .. "/init.luau") then
				scriptContents = fs.readFile(target .. "/init.luau")
			end

			if fs.isFile(target .. "/init.lua") then
				scriptContents = fs.readFile(target .. "init.lua")
			end
		end

		if scriptContents == nil then
			for _, ext in { ".luau", ".lua" } do
				local targetExt = target .. ext
				if fs.isFile(targetExt) then
					scriptContents = fs.readFile(targetExt)
				end
			end

			if scriptContents == nil then
				error(`No such file or directory \`{target}\``)
			end
		end

		return scriptContents
	end

	local function sandboxGetfenv(): {}
		if table.isfrozen(SANDBOXED_ENV) then
			return SANDBOXED_ENV.environment
		end

		return {}
	end

	local function sandboxSetfenv(env: {}): never
		error("cannot call setfenv from sandbox")
	end

	local function sandboxPrint(...: any)
		local header = `---- Output from {SANDBOXED_ENV.debugName} ----`
		DEFAULT_PRINT(header)
		DEFAULT_PRINT(tostring(...))
		DEFAULT_PRINT(string.rep("-", #header))
	end

	local function constructProtectedMt<T>(library: T)
		return {
			__index = library,
			__metatable = "Locked",
			__tostring = function()
				return stdio.format(library)
			end,
		}
	end

	local SANDBOXED_LUNE_STD_LIB = {
		["@lune/fs"] = setmetatable({}, constructProtectedMt(fs)),
		["@lune/luau"] = setmetatable({}, constructProtectedMt(luau)),
		["@lune/process"] = setmetatable({}, constructProtectedMt(process)),
		["@lune/stdio"] = setmetatable({
			write = sandboxPrint,
			ewrite = sandboxPrint,
		}, constructProtectedMt(stdio)),
		["@lune/net"] = setmetatable({}, constructProtectedMt(net)),
		["@lune/roblox"] = setmetatable({
			getAuthCookie = function(...)
				local allowAuthCookie: boolean = stdio.prompt(
					"confirm",
					`allow {SANDBOXED_ENV.debugName} to access your .ROBLOSECURITY token?`
				)

				if allowAuthCookie then
					local getAuthCookie = require("@lune/roblox").getAuthCookie
					return getAuthCookie(...)
				end

				error(
					`{SANDBOXED_ENV.debugName} attempted to access .ROBLOSECURITY token even when denied`
				)
			end,
		}, constructProtectedMt(roblox)),
		["@lune/serde"] = serde,
		["@lune/task"] = task,
		["@lune/regex"] = regex,
		["@lune/datetime"] = datetime,
	}

	local function sandboxedRequire(path: string)
		local module = SANDBOXED_LUNE_STD_LIB[path]

		if module then
			local allowed: boolean =
				stdio.prompt("confirm", string.format(PROMPT_MSG_TMPL, path))

			if allowed then
				return module
			end

			error(string.format(DENIED_ERR_TMPL, path))
		else
			local contents = discoverAndReadScript(path)

			local evalChunk = luau.load(contents, SANDBOXED_ENV)
			return evalChunk()
		end
	end

	SANDBOXED_ENV.environment.require = sandboxedRequire
	SANDBOXED_ENV.environment.getfenv = sandboxGetfenv
	SANDBOXED_ENV.environment.setfenv = sandboxSetfenv
	SANDBOXED_ENV.environment.print = sandboxPrint
	SANDBOXED_ENV.environment.warn = sandboxPrint

	return luau.load(
		discoverAndReadScript(filePath),
		table.freeze(SANDBOXED_ENV)
	)
end

return sandbox
