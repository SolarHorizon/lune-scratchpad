--local cmd = require("@lib/cmd")

-- local install = require("./install")
-- local update = require("./update")

--local Command, Arg, Action = cmd.Command, cmd.Arg, cmd.ArgAction

--local matches = Command.new("rbx-assets")
--	:about("Download & install assets from Roblox")
--	:author("SolarHorizon <matt@solarhorizon.dev>")
--	:version("0.1.0")
--	:subcommandRequired(true)
--	:arg(Arg.new("api-key"):long():global())
--	:arg(Arg.new("project"):long():short():global())
--	:subcommand(
--		Command.new("install")
--			:about("Install assets from the given place")
--			:arg(Arg.new("places"):action(Action.Append))
--			:arg(Arg.new("all"):long():short():action(Action.SetTrue))
--	)
--	:subcommand(
--		Command.new("update")
--			:about("Update assets for the given place to the latest version")
--			:arg(Arg.new("places"):action(Action.Append))
--			:arg(Arg.new("all"):long():short():action(Action.SetTrue))
--	)
--	:getMatches()

-- local match = {
-- 	install = install,
-- 	update = update,
-- }
--
-- matches:getSubcommand():inspect(function(subcommand)
-- 	match[subcommand.name](subcommand.matches)
-- end)
