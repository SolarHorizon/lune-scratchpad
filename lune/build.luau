--!nonstrict

local Result = require("@lib/Result")
local efs = require("@lib/efs")
local progress = require("@lib/progress")
local term = require("@lib/term")

local fs = require("@lune/fs")
local process = require("@lune/process")

local project = process.args[1]

local systems = {
	"linux",
	"macos",
	"windows",
}

local arches = {
	"x86_64",
	"aarch64",
}

local targets = table.clone(process.args)
table.remove(targets, 1)

if #targets <= 0 then
	for _, system in systems do
		for _, arch in arches do
			if system == "windows" and arch == "aarch64" then
				continue
			end

			table.insert(targets, `{system}-{arch}`)
		end
	end
end

local function spawn(program, params)
	return Result.fromSpawnResult(process.spawn(program, params))
end

local buildPath = `./build/{project}`
local text = `Building {project}...`

local darkluaConfig = `src/{project}/bin/darklua.json5`

if not fs.isFile(darkluaConfig) then
	darkluaConfig = "./darklua.json5"
end

local spinner = progress.Spinner.new({ text = text })
spinner:start()

efs.makeDirAll(buildPath)

spawn("darklua", {
		"process",
		"--config",
		darkluaConfig,
		`src/{project}/bin/init.luau`,
		`{buildPath}/unminified.luau`,
	})
	:andThen(function()
		local result = spawn("darklua", {
			"minify",
			`{buildPath}/unminified.luau`,
			`{buildPath}/{project}.luau`,
		})

		fs.removeFile(`{buildPath}/unminified.luau`)

		return result
	end)
	:match({
		Ok = function()
			local version = ""

			if
				fs.isFile(`src/{project}/cli`)
				or fs.isFile(`src/{project}/cli/init.luau`)
			then
				local cli = require(`../src/{project}/cli`)

				if typeof(cli) == "table" then
					if
						cli.command
						and cli.command._config
						and cli.command._config.version
					then
						version = `-{cli.command._config.version}`
					end
				end
			end

			for _, target in targets do
				spinner.text = `{text} ({target})`

				spinner:stop()

				efs.makeDirAll(`{buildPath}/{project}{version}-{target}`)

				local result = spawn("lune", {
					"build",
					"--target",
					target,
					"--output",
					`{buildPath}/{project}{version}-{target}/{project}`,
					`{buildPath}/{project}.luau`,
				}):inspect(function(result: process.SpawnResult)
					print(result)
					spinner:start()
				end)

				if result:isErr() then
					return term.errPrint(
						`Failed to build for target {target}`,
						result:unwrapErr().stderr
					)
				end
			end

			return spinner:stop()
		end,
		Err = function(err: process.SpawnResult)
			spinner:stop()
			term.errPrint(err.stderr)
		end,
	})
