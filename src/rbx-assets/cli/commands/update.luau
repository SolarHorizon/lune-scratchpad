local process = require("@lune/process")

local cmd = require("@lib/cmd")

local install = require("./install")
local lib = require("../../lib")

type ArgMatches = cmd.ArgMatches

local function update(matches, spinner)
	local places = matches:getMany("places")
	local projectPath = matches:getOne("project-path"):unwrapOr(process.cwd)
	local apiKey = matches:getOne("api-key"):expect("missing api key")

	spinner.text = "Fetching place information"

	if not spinner.spinning then
		spinner:start()
	end

	return lib.generateLockfile(apiKey, projectPath, places)
		:await()
		:andThen(function()
			return install(matches, spinner)
		end)
end

return update
