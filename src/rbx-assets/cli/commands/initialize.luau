local process = require("@lune/process")

local cmd = require("@lib/cmd")
local lib = require("../../lib")
local open = require("@lib/util/open")

local PROG_NAME = lib.constants.PROG_NAME

type Error = lib.Error
type ArgMatches = cmd.ArgMatches

local function initialize(matches: ArgMatches, _spinner)
	local projectPath = matches:getOne("project-path"):unwrapOr(process.cwd)
	local edit = matches:getFlag("edit")

	local existing = lib.readConfig(projectPath)

	if
		existing:isErrAnd(function(err: Error)
			return err:isAny(lib.Error.NoConfig)
		end)
	then
		return lib.generateConfig(projectPath)
			:inspect(function()
				print(`{PROG_NAME} initialized`)

				if edit then
					open(`{projectPath}/{PROG_NAME}.yaml`)
				end
			end)
			:map(function()
				return 0
			end)
	else
		return existing:map(function()
			print(`{PROG_NAME} config already exists`)
			return 0
		end)
	end
end

return initialize
