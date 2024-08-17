local process = require("@lune/process")
local roblox = require("@lune/roblox")
local stdio = require("@lune/stdio")

local Option = require("@lib/Option")
local Result = require("@lib/Result")
local StudioOpener = require("@lib/rbx-studio/Opener")
local cmd = require("@lib/cmd")
local getPlace = require("@lib/rbx-api/places/getPlace")
local term = require("@lib/term")

local lib = require("../../lib")

local color = term.color
local Some = Option.Some
local Ok = Result.Ok
local Err = Result.Err

type ArgMatches = cmd.ArgMatches
type Config = lib.Config
type Error = lib.Error
type Place = getPlace.Place
type PlaceConfig = lib.PlaceConfig
type Result<T> = Result.Result<T, Error>

local PLACE_LIST_SEPERATOR = stdio.color("reset")
	.. " - "
	.. stdio.color("yellow")

local function getNamesFromPlaces(places: { [string]: PlaceConfig })
	local names = {}

	for name in places do
		table.insert(names, name)
	end

	return names
end

local function listPlaces(places)
	return PLACE_LIST_SEPERATOR
		.. table.concat(getNamesFromPlaces(places), "\n" .. PLACE_LIST_SEPERATOR)
		.. stdio.color("reset")
end

local function promptPlaces(places): string?
	local names = getNamesFromPlaces(places)

	local selected = stdio.prompt("select", "Select a place to edit", names)

	if selected then
		return names[selected]
	end

	return nil
end

local function edit(matches: ArgMatches, spinner): Result<number>
	local list = matches:getFlag("list")
	local projectPath = matches:getOne("project-path"):unwrapOr(process.cwd)

	local cookie = matches:getOne("cookie"):unwrapOrElse(function()
		return roblox.getAuthCookie() :: string
	end)

	local config = lib.readConfig(projectPath)

	if config:isOk() and list then
		print("Places:")
		print(listPlaces(config:unwrap().places))
		return Ok(0)
	end

	return config
		:andThen(function(config: Config)
			return matches
				:getOne("place")
				:orElse(function()
					return Some(promptPlaces(config.places))
				end)
				:map(function(place)
					return Ok(config.places[place])
				end)
				:unwrapOrElse(function()
					return Err(
						lib.Error.UnrecognizedPlace(listPlaces(config.places))
					)
				end)
				:andThen(function(place: PlaceConfig)
					return getPlace(cookie, place.placeId):await()
				end)
		end)
		:andThen(function(place: Place)
			spinner.text = `Opening {color.blue(place.name)}`
			spinner:start()

			return StudioOpener.new()
				:openPlace(place.universeId, place.id)
				:run()
				:match({
					Ok = function()
						spinner:complete(
							`Successfully opened {color.blue(place.name)} in Roblox Studio`
						)
						return Ok(0)
					end,
					Err = function(err)
						return Err(lib.Error.RobloxStudioOpenFailure(err))
					end,
				})
		end)
end

return edit
