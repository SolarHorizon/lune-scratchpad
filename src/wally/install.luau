local Result = require("@lib/Result")

local fs = require("@lune/fs")
local process = require("@lune/process")

local immutable = require("../immutable")
local progress = require("../progress")
local term = require("../term")

local exportTypes = require("./exportTypes")
local spawn = require("./spawn")
local updateAliases = require("./updateAliases")

local Ok, Err = Result.Ok, Result.Err
local r = Result.from

type Result<T, E> = Result.Result<T, E>

type Options = {
	path: string?,
	pretty: boolean?,
	projectName: string?,
	spawnOptions: process.SpawnOptions?,
}

local defaultOptions = {
	path = ".",
	pretty = false,
	projectName = "default",
}

local function removeDir(path): Result<boolean, string>
	return r(fs.isDir, path):andThen(function(value)
		if value then
			return r(fs.removeDir, path)
		end

		return Ok(value)
	end)
end

local function install(options: Options?): Result<unknown, string>
	local opts: Options = immutable.mergeDeep(defaultOptions, options or {})

	-- this should never happen because `path` defaults to ".", but luau doesn't know that
	if not opts.path then
		return Err("Project path is required")
	end

	local packageDir = `{opts.path}/Packages`
	local serverPackageDir = `{opts.path}/ServerPackages`

	local spinner

	local result = removeDir(packageDir)
		:aand(removeDir(serverPackageDir))
		:andThen(function()
			if opts.pretty then
				spinner = progress.Spinner.new({
					text = "Installing packages",
				})

				spinner:start()
			end

			return spawn("wally", {
				"install",
				"--project-path",
				opts.path,
			}, opts.spawnOptions)
		end)
		:andThen(function()
			if opts.pretty then
				spinner.text = "Generating sourcemap"
			end

			local rojoProject = `{opts.path}/{opts.projectName}.project.json`

			return spawn("rojo", {
				"sourcemap",
				rojoProject,
				"--output",
				`{opts.path}/sourcemap.json`,
			}, opts.spawnOptions)
		end)
		:andThen(function()
			if opts.pretty then
				spinner.text = "Exporting package types"
			end

			return exportTypes(
				{ packageDir, serverPackageDir },
				opts.path,
				opts.spawnOptions
			)
		end)
		:andThen(function()
			return updateAliases({
				luaurc = `{opts.path}/.luaurc`,
				packageDirs = {
					packageDir,
					serverPackageDir,
				},
				updateEffect = function()
					if opts.pretty then
						spinner.text = "Updating aliases"
					end
				end,
			})
		end)

	if opts.pretty then
		result:match({
			Ok = function()
				if spinner then
					spinner:complete("Successfully installed Wally packages")
				end
			end,
			Err = function(err)
				if spinner then
					spinner:fail("Failed to install Wally packages")
				end
				term.errPrint(tostring(err))
			end,
		})
	end

	return result
end

return install
