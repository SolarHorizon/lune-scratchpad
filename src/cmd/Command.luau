--TODO: get_bin_name, bin_name, long_about, long_version, override_usage
--override_help, help_template, *setting*, term_width, max_term_width
--help_heading, stop_custom_headings, args, visible_alias*, replace, group*
--display_order, mut_arg, write_help*,
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local Option = require("@lib/Option")
local Result = require("@lib/Result")
local term = require("@lib/term")

local Arg = require("./Arg")
local ArgAction = require("./ArgAction")
local ArgMatches = require("./ArgMatches")
local Buffer = require("./Buffer")
local Error = require("./Error")

type Arg = Arg.Arg
type ArgAction = ArgAction.ArgAction
type ArgMatches = ArgMatches.ArgMatches
type Error = Error.Error
type Result<T> = Result.Result<T, Error>

local Ok, Err = Result.Ok, Result.Err
local Some = Option.Some
local color = term.color

-- tabs are not always 4 spaces on every terminal
local TAB_WIDTH = 4
local TAB = string.rep(" ", TAB_WIDTH)
local DEFAULT_TERM_WIDTH = 80

--- @class Command
local Command = {}
Command.__index = Command

--- @interface CommandConfig
--- .name string
--- .about string?
--- .author string?
--- .afterHelp string?
--- .beforeHelp string?
--- .version string?
--- .termWidth number?
--- .subcommands { [string]: CommandConfig }
--- .subcommandRequired boolean?
--- .argRequiredElseHelp boolean
--- .args { [string]: ArgConfig }

type CommandConfig<Name, TermWidth, Args, Subcommands> = {
	name: Name,
	about: string?,
	author: string?,
	afterHelp: string?,
	beforeHelp: string?,
	version: string?,
	termWidth: TermWidth,
	args: Args,
	subcommands: Subcommands,
	subcommandRequired: boolean?,
	argRequiredElseHelp: boolean,
}

export type SubcommandConfig = CommandConfig<
	string?,
	number?,
	{ Arg.Config }?,
	SubcommandConfig
>

export type Config = CommandConfig<
	string,
	number?,
	{ Arg.Config }?,
	{ SubcommandConfig }?
>

export type Command = typeof(setmetatable(
	{} :: {
		_error: Error?,
		_shorts: { [string]: Arg },
		_aliases: { string },
		_globals: { [string]: Arg },
		_required: { [string]: Arg },
		_options: { Arg },
		_positional: { Arg },
		_longs: { [string]: Arg },
		_parent: Command?,
		_positionalArgRequired: boolean?,
		_config: CommandConfig<
			string,
			number,
			{ [string]: Arg },
			{ [string]: Command }
		>,
	},
	Command
))

--- Constructs a new Command.
---
--- This name is displayed to the user when they request to print help and information.
function Command.new(name: string): Command
	return setmetatable({
		_config = {
			name = name,
			args = {},
			subcommands = {},
			termWidth = DEFAULT_TERM_WIDTH,
			argRequiredElseHelp = true,
		},
		_aliases = {},
		_globals = {},
		_longs = {},
		_options = {},
		_positional = {},
		_required = {},
		_shorts = {},
	}, Command)
end

local deserialize = {
	args = function(args: { [string]: Arg.Config })
		local new = {}

		for name, value in args do
			if value.name == nil then
				value.name = name
			end

			local ok = pcall(Arg.from, value)
			if not ok then
				print(value)
			end

			new[name] = Arg.from(value)
		end

		return new
	end,
	subcommands = function(subcommands: { [string]: Config }, from)
		local new = {}

		for name, value in subcommands do
			if value.name == nil then
				value.name = name
			end

			new[name] = from(value)
		end

		return new
	end,
}

--- Constructs a new Command from a `Config`.
--- @param config CommandConfig
function Command.from(config: Config): Command
	local command = Command.new(config.name)

	for name, value in config do
		if name == "name" then
			continue
		end

		if deserialize[name] then
			value = deserialize[name](value, Command.from)
		end

		if not command[name] then
			if Arg[name] then
				error(
					`Command does not have a '{name}' property.\n\tIs '{config.name}' supposed to be an argument?`
				)
			end

			error(`Command does not have a '{name}' property.`)
		end

		command[name](command, value)
	end

	return command
end

--- Sets the version for `--version` and help messages
function Command.version(self: Command, version: string): Command
	self._config.version = version
	return self
end

--- Sets the author(s) for the help message
---
--- :::note This does not appear in the default help message, and there is no way to create a custom help message yet.:::
function Command.author(self: Command, name: string): Command
	self._config.author = name
	return self
end

--- Sets the program's description for the help message.
function Command.about(self: Command, about: string): Command
	self._config.about = about
	return self
end

--- Free form text that is printed after help information
---
--- This is sometimes used to describe how to use the arguments, caveats to be noted, or license and contact information.
function Command.afterHelp(self: Command, help: string): Command
	self._config.afterHelp = help
	return self
end

--- Free form text that is printed before help information
---
--- This is sometimes used for header, copyright, or license information.
function Command.beforeHelp(self: Command, help: string): Command
	self._config.beforeHelp = help
	return self
end

--- Adds an argument to the command.
---
--- ```luau
--- Command.new("program")
--- 	:arg(
---			Arg.new("foo")
---				:short()
---				:help("Prints 'foo' to stdout")
--- 	)
--- 	:arg(
---			Arg.new("bar")
---				:long()
---				:short()
---				:help("Prints 'bar' to stderr")
--- 	)
--- ```
function Command.arg(self: Command, argument: Arg): Command
	if not (argument._config.long or argument._config.short) then
		if argument._config.required then
			self._positionalArgRequired = true
		end

		if argument._config.index then
			table.insert(self._positional, argument._config.index, argument)
		else
			table.insert(self._positional, argument)
		end
	else
		table.insert(self._options, argument)

		if argument._config.long then
			self._longs[argument._config.long] = argument
		end

		if argument._config.short then
			self._shorts[argument._config.short] = argument
		end
	end

	if argument._config.global then
		self._globals[argument._config.name] = argument
	end

	if argument._config.required then
		self._required[argument._config.name] = argument
	end

	self._config.args[argument._config.name] = argument

	return self
end

--- Adds multiple arguments to the command.
---
--- ```luau
--- Command.new("program")
--- 	:args({
---			Arg.new("foo"):short():help("Prints 'foo' to stdout"),
---			Arg.new("bar"):long():short():help("Prints 'bar' to stderr")
---		})
--- ```
function Command.args(self: Command, arguments: { Arg }): Command
	for _, arg in arguments do
		self:arg(arg)
	end

	return self
end

--- Adds a subcommand to the command.
---
--- ```luau
--- Command.new("program")
--- 	:subcommand(
--- 		Command.new("foo")
---				:args({
---					Arg.new("hello"):short()
---					Arg.new("world")
---				})
--- 		)
--- 	:subcommand(
--- 		Command.new("bar")
---				:args({
---					Arg.new("foobar"):short(),
---					Arg.new("barfoo")
---				})
--- 		)
--- ```
function Command.subcommand(self: Command, command: Command): Command
	self._config.subcommands[command._config.name] = command
	command._parent = self

	for id, arg in self._globals do
		if not command._config.args[id] then
			command:arg(arg)
		end
	end

	return self
end

--- Adds multiple subcommands to the command.
---
--- ```luau
--- Command.new("program")
--- 	:subcommands({
--- 		Command.new("foo")
---				:arg(
---					Arg.new("foo"):short():help("Prints 'foo' to stdout"),
---				)
---				:arg(
---					Arg.new("bar"):long():short():help("Prints 'bar' to stderr")
---				)
--- 		Command.new("bar")
---				:args({
---					Arg.new("foobar"):short(),
---					Arg.new("barfoo")
---				})
--- 		})
--- ```
function Command.subcommands(self: Command, commands: { Command }): Command
	for _, command in commands do
		self:subcommand(command)
	end

	return self
end

--- If no subcommand is present at runtime, error and exit gracefully.
--- @param self Command
--- @param required boolean -- defaults to `true`
function Command.subcommandRequired(self: Command, required: boolean?)
	self._config.subcommandRequired = required ~= false
	return self
end

--- Sets an alias for this subcommand.
---
--- This allows the command to be accessed by either the original name, or the given alias.
function Command.alias(self: Command, name: string): Command
	table.insert(self._aliases, name)
	return self
end

--- Sets multiple aliases for this subcommand.
---
--- This allows the command to be accessed by either the original name, or one of the given aliases.
function Command.aliases(self: Command, names: { string }): Command
	for _, name in names do
		self:alias(name)
	end

	return self
end

--- Exit gracefully and print help information if no arguments are present.
---
--- :::tip This is behavior is enabled by default.:::
---
--- :::note Subcommands count as arguments.:::
---
--- @param self Command
--- @param enabled boolean? -- defaults to `true`
function Command.argRequiredElseHelp(self: Command, enabled: boolean?)
	self._config.argRequiredElseHelp = enabled ~= false
	return self
end

-- TODO: line wrap
--- Sets the maximum width for help messages.
---
---	:::note
--- This is not fully implemented yet. Currently, when help message width is greater than this value,
--- the help message will be displayed in an expanded format but will not wrap any text.
--- :::
function Command.termWidth(self: Command, width: number): Command
	self._config.termWidth = width
	return self
end

--- Get the name of the command.
function Command.getName(self: Command): string
	return self._config.name
end

--- Returns version information formatted for the version message.
function Command.renderVersion(self: Command): string
	if self._config.version then
		return `{self:getName()} {self._config.version}\n`
	end

	return ""
end

--- Prints version information to stdout.
function Command.printVersion(self: Command)
	stdio.write(self:renderVersion())
end

local function formatArgUsage(arg: Arg)
	local line = ""

	if arg._config.long then
		line = `--{arg._config.long} `
	elseif arg._config.short then
		line = `-{arg._config.short} `
	end

	if arg._config.action.takesValues then
		line ..= `<{string.upper(arg._config.valueName)}>`
	end

	return line
end

--- Returns usage information formatted for a help message.
---
--- When `isRenderHelp` is true, prints more descriptive information.
---
--- :::warning This function is likely to change in the future to avoid using a boolean flag.:::
function Command.renderUsage(self: Command, isRenderHelp: boolean?)
	local out = Buffer.new()

	out:print(color.yellow("USAGE:"))
	out:print(`{TAB}{self:getName()}`)

	for _, arg in self._required do
		if arg._config.short or arg._config.long then
			out:write(" " .. formatArgUsage(arg))
		end
	end

	if isRenderHelp then
		if next(self._options) then
			out:write(" [OPTIONS]")
		end
	end

	for _, arg in self._positional do
		out:write(` <{string.upper(arg._config.valueName)}>`)
	end

	if next(self._config.subcommands) then
		if #self._positional > 0 then
			out:print(`{TAB}{self:getName()}`)
		end

		out:write(" <SUBCOMMAND>")
	end

	if not isRenderHelp then
		out:print()
		out:print(`For more information, try {color.green("--help")}`)
		out:print()
	end

	return tostring(out)
end

--- Prints usage information to stdout.
function Command.printUsage(self: Command)
	stdio.write(self:renderUsage())
end

local function formatOpts(arg: Arg)
	local out = Buffer.new()

	if arg._config.short then
		out:write(`-{arg._config.short}`)
	end

	if arg._config.long and arg._config.short then
		out:write(", ")
	end

	if arg._config.long then
		if not arg._config.short then
			out:write(string.rep(" ", 4))
		end

		out:write(`--{arg._config.long}`)
	end

	if arg._config.action.takesValues then
		out:write(` <{string.upper(arg._config.valueName)}>`)
	end

	return tostring(out)
end

-- luau doesn't like generics for functions within the Command class, apparently
-- function Command._justify<T>(self: Command, args: { T }, format: ((T) -> string)?)
function Command._justify(
	self: Command,
	args: { any },
	format: ((any) -> string)?
)
	local out = Buffer.new()

	local lines = {}
	local width = 0

	for _, arg: any in args do
		local line = if format then format(arg) else arg._config.name

		local lineWidth = #line
		if lineWidth > width then
			width = lineWidth
		end

		table.insert(lines, {
			line,
			arg._config.help or arg._config.about or "",
		})
	end

	local expanded: boolean

	for _, line in lines do
		if #line[1] + #line[2] > self._config.termWidth then
			expanded = true
		end
	end

	if expanded then
		for i, line in lines do
			out:print(`{TAB}{color.green(line[1])}`)
			out:print(
				string.rep(TAB, 2)
					.. term.wrap(line[2], self._config.termWidth, TAB_WIDTH * 2)
			)

			if i < #lines then
				out:print()
			end
		end
	else
		for _, line in lines do
			local offset = string.rep(" ", width - #line[1])
			out:print(`{TAB}{color.green(line[1])}{offset}{TAB}{line[2]}`)
		end
	end

	return tostring(out)
end

--- Returns help information formatted for a help message.
function Command.renderHelp(self: Command): string
	local out = Buffer.new()

	local options = table.clone(self._options)
	local args = table.clone(self._positional)

	if self._config.about then
		out:write(self._config.about)
	end

	if self._config.beforeHelp then
		out:print()
		out:print(self._config.beforeHelp)
	end

	out:print(self:renderUsage(true))

	if #args > 0 then
		out:print()
		out:print(color.yellow("ARGS:"))
		out:write(self:_justify(args, function(arg)
			return `<{string.upper(arg._config.valueName)}>`
		end))
	end

	if next(self._config.subcommands) then
		local subcommands = {}

		for _, command in self._config.subcommands do
			table.insert(subcommands, command)
		end

		out:print()
		out:print(color.yellow("SUBCOMMANDS:"))
		out:write(self:_justify(subcommands))
	end

	if #options > 0 then
		out:print()
		out:print(color.yellow("OPTIONS:"))
		out:write(self:_justify(options, formatOpts))
	end

	if self._config.afterHelp then
		out:print()
		out:print(self._config.afterHelp)
	end

	out:print()

	return tostring(out)
end

function Command._createBuiltins(self: Command)
	if next(self._config.subcommands) and not self._config.subcommands.help then
		self:subcommand(
			Command.new("help")
				:arg(Arg.new("subcommand"))
				:argRequiredElseHelp(false)
				:about(
					"Print this information or the help of the given subcommand"
				)
		)
	end

	if not self._config.args.help then
		self:arg(
			Arg.new("help")
				:long()
				:short()
				:global()
				:help("Print help information")
				:action(ArgAction.Help)
		)
	end

	if not self._config.args.version and self._config.version then
		self:arg(
			Arg.new("version")
				:long()
				:short("V")
				:help("Print version information")
				:action(ArgAction.Version)
		)
	end
end

--- Prints help information to stdout.
function Command.printHelp(self: Command)
	stdio.write(self:renderHelp())
end

function Command._err(self: Command, error: Error, ...): Result<any>
	if
		error:is(Error.DisplayHelp, Error.DisplayOnMissingArgumentOrSubcommand)
	then
		return Err(error:append(self:renderHelp()))
	elseif error:is(Error.DisplayVersion) then
		return Err(error:append(self:renderVersion()))
	end

	return Err(
		error(...)
			:prepend(`{color.red("error")}: `)
			:append("\n" .. self:renderUsage())
	)
end

function Command._buildMatches(
	self: Command,
	input: { string },
	parent: ArgMatches?
): Result<ArgMatches>
	self:_createBuiltins()

	local matches = ArgMatches.new(self)

	if parent then
		matches:_setParent(parent)
	end

	-- populate any arguments with env vars
	local envMatched
	for _, match in self._config.args do
		if match._config.env and process.env[match._config.env] then
			matches:_process(match, process.env[match._config.env])
			envMatched = true
		end
	end

	-- exit early with help info when no arguments were passed
	if
		not envMatched
		and #input <= 0
		and ((#self._positional > 0 and self._positionalArgRequired) or next(
			self._config.subcommands
		))
		and self._config.argRequiredElseHelp
	then
		return self:_err(Error.DisplayOnMissingArgumentOrSubcommand)
	end

	local valueArg: Arg?
	local buffer: { Result<any> }
	local index = 1
	local position = 1
	local positionalOnly = false

	for i, str in input do
		index = i

		-- double dash (--) is commonly used to signify the end of command options
		if str == "--" then
			positionalOnly = true
			continue
		end

		-- the last argument we checked requires a value
		if valueArg then
			local action = valueArg._config.action

			-- append takes multiple values
			if action:is(ArgAction.Append) then
				if not buffer then
					buffer = {}
				end

				if action.defaultValueParser then
					local result = action
						.defaultValueParser(str)
						:inspect(function(parsed)
							table.insert(buffer, parsed)
						end)

					if result:isErr() then
						return result
					end
				else
					table.insert(buffer, Ok(str))
				end

				-- TODO: termination
				if i == #input then
					matches:_process(valueArg)
				end
			end

			if action:is(ArgAction.Set) then
				matches:_process(valueArg, str)
				valueArg = nil
			end

			continue
		end

		-- process options
		if not positionalOnly then
			-- using a table because short options can be chained together into 1 argument (see below)
			local args = {}

			local long = string.match(str, "^%-%-(.+)")
			if long then
				local found = self._longs[long]

				if not found then
					return self:_err(Error.UnknownOption, str)
				end

				table.insert(args, found)
			end

			if not long then
				local short = string.match(str, "^%-(.+)")
				if short then
					-- short options can be chained (like in the case of `tar -xvzf`)
					for _ = 1, #short do
						local found = self._shorts[string.sub(short, 1, 1)]

						if not found then
							return self:_err(Error.UnknownOption, str)
						end

						table.insert(args, found)
					end
				end
			end

			-- process all of the buffered arguments
			for _, arg in args do
				if arg._config.action.takesValues then
					valueArg = arg
				elseif arg._config.action:is(ArgAction.Help) then
					return self:_err(Error.DisplayHelp)
				elseif arg._config.action:is(ArgAction.Version) then
					return self:_err(Error.DisplayVersion)
				else
					matches:_process(arg)
				end
			end

			if next(args) then
				continue
			end

			local subcommand = self._config.subcommands[str]

			if not subcommand then
				for _, command in self._config.subcommands do
					if table.find(command._aliases, str) then
						subcommand = command
					end
				end
			end

			if subcommand then
				-- we need to remove all of the arguments up to and including
				-- this one before passing them on to the subcommand
				local subInput = table.clone(input)

				for _ = 1, index do
					table.remove(subInput, 1)
				end

				return subcommand:_buildMatches(subInput, matches):map(function()
					return matches
				end)
			end

			if next(self._config.subcommands) and #self._positional == 0 then
				return self:_err(Error.InvalidSubcommand, str)
			end
		end

		local arg = self._positional[position]

		if arg then
			position += 1
			matches:_process(arg, str)
		else
			return self:_err(Error.InvalidArgument, str)
		end
	end

	-- we're still looking for a value but there are no more arguments
	if valueArg then
		return self:_err(
			Error.NoValue,
			`\n{TAB}--{valueArg._config.long} <{string.upper(
				valueArg._config.valueName
			)}>`
		)
	end

	-- check for required subcommands
	if next(self._required) == nil and self._config.subcommandRequired then
		return self:_err(Error.NoSubcommand, self._config.name)
	end

	-- check for required arguments
	local missing = {}

	for name, arg in self._required do
		if not matches:containsId(name) then
			table.insert(missing, formatArgUsage(arg))
		end
	end

	if #missing > 0 then
		return self:_err(
			Error.NoValue,
			`\n{TAB}{table.concat(missing, `\n{TAB}`)}`
		)
	end

	return Ok(matches)
end

--- Processes the specified arguments, returning a `Result`.
---
--- This method will not exit when `--help` or `--version` are used. It will return an `Error`,
--- where `id` is either `Error.DisplayHelp` or `Error.DisplayVersion`. You must call `Command:exit`
--- yourself if you would like these commands to work as expected.
function Command.tryGetMatchesFrom(
	self: Command,
	input: { string }
): Result<ArgMatches>
	return self:_buildMatches(input)
		:andThen(function(matches: ArgMatches)
			local result = Ok(matches)

			matches:getSubcommand():inspect(function(subcommand: {
				name: string,
				matches: ArgMatches,
			})
				if subcommand.name ~= "help" then
					return
				end

				subcommand.matches:getOne("subcommand"):inspect(function(name)
					local target = self._config.subcommands[name]

					if target then
						result = target:_err(Error.DisplayHelp)
					else
						result = self:_err(Error.InvalidArgument, name)
					end
				end)

				if result:isOk() then
					result = self:_err(Error.DisplayHelp, self:renderHelp())
				end
			end)

			return result
		end)
		:inspectErr(function(err: Error)
			self._error = err
		end)
end

--- Process the given arguments, exiting on failure.
function Command.getMatchesFrom(self: Command, input: { string }): ArgMatches
	return self:tryGetMatchesFrom(input):match({
		Ok = function(matches: ArgMatches)
			return matches
		end,
		Err = function()
			return self:exit()
		end,
	})
end

--- Calls `tryGetMatchesFrom` on `process.args`
function Command.tryGetMatches(self: Command): Result<ArgMatches>
	return self:tryGetMatchesFrom(process.args)
end

--- Calls `getMatches` on `process.args`
function Command.getMatches(self: Command): ArgMatches
	return self:getMatchesFrom(process.args)
end

--- Prints any error information and calls `process.exit`.
function Command.exit(self: Command, code: number?)
	if self._error then
		if self._error:is(Error.DisplayHelp, Error.DisplayVersion) then
			stdio.write(tostring(self._error))
			return process.exit(0)
		else
			stdio.ewrite(tostring(self._error))
			return process.exit(1)
		end
	end

	return process.exit(code)
end

return Command
