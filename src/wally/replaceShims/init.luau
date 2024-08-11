local Result = require("@lib/Result")

local fs = require("@lune/fs")

local loadManifest = require("../loadManifest")
local shims = require("./shims")
local types = require("../types")

local Ok, Err = Result.Ok, Result.Err
local r = Result.from

type Result<T, E> = Result.Result<T, E>
type Dependency = types.Dependency
type Manifest = types.Manifest

type Options = {
	packagesPath: string,
	projectPath: string,
}

local function replaceShims(options: Options): Result<unknown, string>
	return r(fs.isDir, options.packagesPath):andThen(function()
		return loadManifest(options.projectPath)
	end):andThen(function(manifest: Manifest)
		local server = string.match(options.packagesPath, "^.+/ServerPackages")

		local dependencies: { [string]: Dependency } = if server
			then manifest.serverDependencies
			else manifest.dependencies

		for alias, package in dependencies do
			local path = `{options.packagesPath}/{alias}.luau`
			local lua = string.sub(path, 1, #path - 1)

			local result = r(fs.readFile, lua):mapErr(function()
				return `Could not replace shim for {alias} because it is not installed. `
					.. "Make sure all dependencies are properly installed before replacing shims."
			end):andThen(function(content)
				fs.move(lua, path)

				local shim: string? = shims[string.lower(package.name)]
				local module = string.match(content, "require%(([^%)]+)%)")

				if not shim then
					return Ok(true)
				end

				if not module then
					return Err(`Could not match require target in {path}`)
				end

				return r(
					fs.writeFile,
					`{options.packagesPath}/{alias}.luau`,
					string.format(shim, module)
				)
			end)

			if result:isErr() then
				return result
			end
		end

		return Ok(true)
	end)
end

return replaceShims
