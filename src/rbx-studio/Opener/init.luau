local fs = require("@lune/fs")

local Result = require("@lib/Result")
local efs = require("@lib/efs")
local open = require("@lib/util/open")

local Error = require("../Error")
local Task = require("./Task")
local locate = require("../locate")

type Error = Error.Error
type Result<T> = Result.Result<T, Error>
type RobloxStudio = locate.RobloxStudio

local SERVER_ADDR = "127.0.0.1"
local SERVER_PORT = 50608

local Opener = {}
Opener.__index = Opener

type Args = { { string } }

export type RobloxStudioOpener = typeof(setmetatable(
	{} :: {
		_args: Args,
		_openFileLinux: string?,
	},
	Opener
))

function Opener.new(): RobloxStudioOpener
	return setmetatable({
		_args = { { "roblox-studio", "1" } },
	}, Opener)
end

function Opener.withArg<K, V>(
	self: RobloxStudioOpener,
	key: K,
	value: V
): RobloxStudioOpener
	table.insert(self._args, {
		tostring(key),
		tostring(value),
	})

	return self
end

function Opener._withZeros(self: RobloxStudioOpener): RobloxStudioOpener
	-- necessary for some commands even though they're unused
	return self:withArg("creatorType", 0)
		:withArg("creatorId", 0)
		:withArg("universeId", 0)
		:withArg("placeId", 0)
end

function Opener.openPlace(
	self: RobloxStudioOpener,
	universeId: number,
	placeId: number
): RobloxStudioOpener
	return self:withArg("task", Task.EditPlace)
		:withArg("universeId", universeId)
		:withArg("placeId", placeId)
end

function Opener.openFile(
	self: RobloxStudioOpener,
	file: string
): Result<RobloxStudioOpener>
	return efs.canonicalize(file):map(function(path)
		return self:withArg("task", Task.EditFile)
			:withArg("localPlaceFile", path)
	end)
end

function Opener.startServer(
	self: RobloxStudioOpener,
	file: string
): Result<RobloxStudioOpener>
	return locate()
		:andThen(function(studio: RobloxStudio)
			return efs.canonicalize(studio.root .. "/../..")
				:inspect(function(path: string)
					fs.copy(file, path .. "/server.rbxl", {
						overwrite = true,
					})
				end)
		end)
		:map(function()
			return self:withArg("task", Task.StartServer)
				:withArg("-server", SERVER_ADDR)
				:withArg("-port", SERVER_PORT)
				:_withZeros()
		end)
end

function Opener.startClient(self: RobloxStudioOpener): RobloxStudioOpener
	return self:withArg("task", Task.StartClient)
		:withArg("-server", SERVER_ADDR)
		:withArg("-port", SERVER_PORT)
		:_withZeros()
end

function Opener.startServerWithClients(
	self: RobloxStudioOpener,
	file: string,
	clients: number
): Result<RobloxStudioOpener>
	return self:startServer(file):inspect(function(opener: RobloxStudioOpener)
		return opener:withArg("numtestserverplayersuponstartup", clients)
	end)
end

local function buildArgsStr(args: Args)
	local build = {}

	for _, arg in args do
		table.insert(build, `{arg[1]}:{arg[2]}`)
	end

	return table.concat(build, "+")
end

function Opener.run(self: RobloxStudioOpener)
	return locate()
		:map(function(studio: RobloxStudio)
			return Result.fromSpawnResult(open(buildArgsStr(self._args)))
		end)
		:flatten()
end

return Opener
