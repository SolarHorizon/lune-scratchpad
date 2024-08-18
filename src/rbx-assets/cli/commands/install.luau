local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Iter = require("@lib/Iter")
local Option = require("@lib/Option")
local Result = require("@lib/Result")
local cmd = require("@lib/cmd")

local lib = require("../../lib")

local Error = lib.Error
local Ok, Err = Result.Ok, Result.Err

type Error = lib.Error
type Iter<K, V> = Iter.Iter<K, V>
type ArgMatches = cmd.ArgMatches
type Option<T> = Option.Option<T>
type Result<T> = Result.Result<T, Error>
type Lockfile = lib.Lockfile
type PlaceLock = lib.PlaceLock

local function getLockfile(apiKey, projectPath, places): Result<Lockfile>
	return lib.readLockfile(projectPath):andThen(function(opt: Option<Lockfile>)
		return opt:match({
			Some = function(lockfile: Lockfile)
				return Ok(lockfile)
			end,
			None = function()
				return lib.generateLockfile(apiKey, projectPath, places):await()
			end,
		})
	end)
end

local function getPlacesFrom(
	places: Iter<number, string>,
	lockfile: Lockfile
): Result<Lockfile>
	return places
		:map(function(_, name)
			if not lockfile.places[name] then
				return Err(Error.InvalidPlaceName(name))
			end

			return Ok({
				name = name,
				lock = lockfile.places[name],
			})
		end)
		:intoResult()
		:map(function(result: { { name: string, lock: PlaceLock } })
			local selected = {}

			for _, place in result do
				selected[place.name] = place.lock
			end

			return {
				defaultInstaller = lockfile.defaultInstaller,
				places = selected,
			}
		end)
end

local function install(matches, spinner)
	local places = matches:getMany("places")
	local projectPath = matches:getOne("project-path"):unwrapOr(process.cwd)
	local apiKey = matches:getOne("api-key"):expect("missing api key")

	local cookie = matches:getOne("cookie"):unwrapOrElse(function()
		return roblox.getAuthCookie() :: string
	end)

	return getLockfile(apiKey, projectPath, places):andThen(
		function(lockfile: Lockfile)
			return places
				:map(function(places)
					if not spinner.spinning then
						spinner:start()
					end

					spinner.text = "Fetching places"

					return getPlacesFrom(places, lockfile)
				end)
				:unwrapOr(Ok(lockfile))
				:andThen(function(selection)
					spinner.text = "Installing assets"
					return lib.install(cookie, selection):await()
				end)
				:inspect(function()
					spinner:complete("Successfully installed assets")
				end)
		end
	)
end

return install
