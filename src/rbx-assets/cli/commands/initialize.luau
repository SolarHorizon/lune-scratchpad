local process = require("@lune/process")

local cmd = require("@lib/cmd")
local lib = require("../../lib")
local open = require("@lib/util/open")

type Error = lib.Error
type ArgMatches = cmd.ArgMatches

local function initialize(matches: ArgMatches, _spinner)
	local projectPath = matches:getOne("project-path"):unwrapOr(process.cwd)
	local edit = matches:getOne("edit"):isSome()

	local existing = lib.readConfig(projectPath)

	if
		existing:isErrAnd(function(err: Error)
			return err:isAny(lib.Error.NoConfig)
		end)
	then
		return lib.generateConfig(projectPath)
			:inspect(function()
				print("rbx-assets initialized")

				if edit then
					open(`{projectPath}/rbx-assets.yaml`)
				end
			end)
			:map(function()
				return 0
			end)
	else
		return existing:map(function()
			print("rbx-assets config already exists")
			return 0
		end)
	end
end

return initialize
