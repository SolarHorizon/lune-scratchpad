local process = require("@lune/process")

local Error = require("@lib/Error")
local Option = require("@lib/Option")
local Result = require("@lib/Result")
local cmd = require("@lib/cmd")
local progress = require("@lib/progress")

local commands = require("./commands")
local lib = require("../lib")

local Some = Option.Some
local Action = cmd.ArgAction
local Arg = cmd.Arg
local Command = cmd.Command

local PROG_NAME = lib.constants.PROG_NAME

type Error = Error.Error
type Result<T> = Result.Result<T, Error>

local authArgs = {
	key = Arg.new("api-key")
		:help(
			"Your Open Cloud API key. Can also be set with the RBX_ASSETS_KEY environment variable."
		)
		:long()
		:required()
		:hideEnvValues()
		:env("RBX_ASSETS_KEY"),
	cookie = Arg.new("cookie")
		:help(
			`Your ROBLOSECURITY token. Can also be set with the ROBLOSECURITY environment variable. If left unspecified, {PROG_NAME} will try to use the auth cookie from your last logged in Roblox Studio session.`
		)
		:long()
		:short()
		:hideEnvValues()
		:env("ROBLOSECURITY"),
}

local rbxAssets = Command.new(PROG_NAME)
	:about("Download & install assets from Roblox")
	:author("SolarHorizon <matt@solarhorizon.dev>")
	:version("1.0.0")
	:subcommandRequired(true)
	:arg(
		Arg.new("project-path")
			:help(
				"The path to the project you want to install assets for. (defaults to '.')"
			)
			:long()
			:short()
			:global()
	)
	:subcommand(
		Command.new("install")
			:about("Install assets from the given place")
			:arg(
				Arg.new("places")
					:help(
						"The place to install. When not specified, installs all places."
					)
					:action(Action.Append)
			)
			:args(authArgs)
	)
	:subcommand(
		Command.new("update")
			:about("Update assets to the latest version")
			:arg(
				Arg.new("places")
					:help(
						"The place to update. When not specified, updates all places."
					)
					:action(Action.Append)
			)
			:args(authArgs)
	)
	:subcommand(
		Command.new("init")
			:about("Create a new {PROG_NAME}.yml file for your project")
			:arg(
				Arg.new("edit")
					:help(
						`Open {PROG_NAME}.yml in your default text editor after it has been generated.`
					)
					:action(Action.SetTrue)
					:short()
					:long()
			)
	)
	:subcommand(
		Command.new("edit")
			:about("Opens the specified place in Roblox Studio")
			:arg(Arg.new("place"):help("The place to edit."))
			:arg(
				Arg.new("list")
					:help("Display a list of editable places.")
					:action(Action.SetTrue)
					:long()
			)
			:arg(authArgs.cookie)
	)

type Subcommand = {
	matches: cmd.ArgMatches,
	name: string,
}

local function runWith(args: { string }): Result<number>
	local spinner = progress.Spinner.new()

	return rbxAssets
		:getMatchesFrom(args)
		:getSubcommand()
		:andThen(function(subcommand: Subcommand)
			return Some(commands[subcommand.name]):map(function(run)
				return run(subcommand.matches, spinner)
			end)
		end)
		:match({
			Some = function(result: Result<number>)
				spinner:stop()
				return result
			end,
			None = function()
				spinner:stop()
				error("entered unreachable branch")
			end,
		})
end

local function run()
	return runWith(process.args)
end

return {
	command = rbxAssets,
	runWith = runWith,
	run = run,
}
