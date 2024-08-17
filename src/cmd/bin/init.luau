local cmd = require("@lib/cmd")

type ArgMatches = cmd.ArgMatches

local Command, Arg, Action = cmd.Command, cmd.Arg, cmd.ArgAction

local cli = Command.new("test")
	:version("v0.1.0")
	:about("A Test Program")
	:author("SolarHorizon")
	:beforeHelp("This text should appear before help information")
	:afterHelp("This text should appear after help information")
	:subcommandRequired()
	:arg(Arg.new("environment"):long():help("Sets the environment"))
	:arg(
		Arg.new("verbose")
			:short()
			:long()
			:global()
			:action(Action.Count)
			:help("Sets the verbosity level")
	)
	:arg(Arg.new("place"):required():help("The place you want to publish"))
	:subcommand(
		Command.new("import")
			:about("This is a subcommand")
			:arg(
				Arg.new("flag")
					:long()
					:short()
					:action(Action.SetTrue)
					:help("Some flag that does something")
			)
			:arg(
				Arg.new("option")
					:valueName("value")
					:long()
					:short()
					:required()
					:help("Some option that does something")
			)
	)

-- local cli = Command.from({
-- 	name = "test",
-- 	about = "A Test Program",
-- 	beforeHelp = "This text should appear before help information",
-- 	afterHelp = "This text should appear after help information",
-- 	subcommandRequired = true,
-- 	args = {
-- 		verbose = {
-- 			short = true,
-- 			long = true,
-- 			global = true,
-- 			action = "Count",
-- 			help = "Sets the verbosity level",
-- 		},
-- 		place = {
-- 			required = true,
-- 			help = "The place you want to publish",
-- 		},
-- 	},
-- 	subcommands = {
-- 		import = {
-- 			about = "This is a subcommand",
-- 			args = {
-- 				flag = {
-- 					long = true,
-- 					short = true,
-- 					action = "SetTrue",
-- 					help = "Some flag that does something",
-- 				},
-- 				option = {
-- 					valueName = "value",
-- 					long = true,
-- 					short = true,
-- 					required = true,
-- 					help = "Some option that does something",
-- 				},
-- 			},
-- 		},
-- 	},
-- })

local function printMatches(self)
	print("GLOBALS", "\n\n", self._globals)
	print("\nARGS", "\n\n", self._args)

	if self._subcommand then
		print("\nSUBCOMMAND")
		printMatches(self._subcommand)
	end
end

cli:tryGetMatches():match({
	Ok = function(matches)
		printMatches(matches)
	end,
	Err = function(err)
		print(tostring(err.id))
		cli:exit()
	end,
})
