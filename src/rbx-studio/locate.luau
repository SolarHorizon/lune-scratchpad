local fs = require("@lune/fs")
local process = require("@lune/process")

local Option = require("@lib/Option")
local Result = require("@lib/Result")
local dirs = require("@lib/dirs")
local efs = require("@lib/efs")

local Error = require("./Error")

local Some = Option.Some
local Ok = Result.Ok
local Err = Result.Err

type Error = Error.Error
type Option<T> = Option.Option<T>
type Result<T> = Result.Result<T, Error>

export type RobloxStudio = {
	content: string,
	application: string,
	builtInPlugins: string,
	plugins: string,
	root: string,
}

local function locatePlugins()
	local pluginDir = dirs.getHomeDir()

	if not pluginDir then
		return Err(Error.PluginsDirectoryNotFound)
	end

	return Ok(`{pluginDir}/AppData/Local/Roblox/Plugins`)
end

local function locateFromWindowsDirectory(root: string): Result<RobloxStudio>
	local contentFolderPath = root .. "/content"

	return locatePlugins():andThen(function(plugins)
		if fs.isDir(contentFolderPath) then
			return Ok({
				content = contentFolderPath,
				application = root .. "/RobloxStudioBeta.exe",
				builtInPlugins = root .. "/BuiltInPlugins",
				plugins = plugins,
				root = root,
			})
		end

		local versions = root .. "/Versions"

		if not fs.isDir(versions) then
			return Err(Error.NotInstalled)
		end

		for _, entry in fs.readDir(versions) do
			local version = `{versions}/{entry}`
			local application = version .. "/RobloxStudioBeta.exe"

			if fs.isFile(application) then
				return Ok({
					content = version .. "/content",
					application = application,
					builtInPlugins = version .. "/BuiltInPlugins",
					plugins = plugins,
					root = version,
				})
			end
		end

		return Err(Error.NotInstalled)
	end)
end

local function locateFromMacDirectory(root: string): Result<RobloxStudio>
	local contents = root .. "/Contents"
	local documents = dirs.getDocumentsDir()

	if not documents then
		return Err(Error.DocumentsDirectoryNotFound)
	end

	return Ok({
		application = contents .. "/MacOS/RobloxStudio",
		builtInPlugins = contents .. "/Resources/BuiltInPlugins",
		content = contents .. "/Resources/content",
		plugins = documents .. "/Roblox/Plugins",
		root = root,
	})
end

local function locateFromDirectory(root)
	if process.os == "macos" then
		return locateFromMacDirectory(root)
	end

	-- we can reuse the windows function for for WSL users
	return locateFromWindowsDirectory(root)
end

local function locateFromEnv(): Option<Result<RobloxStudio>>
	return Some(process.env.ROBLOX_STUDIO_PATH):map(function(value: string)
		if not fs.isDir(value) then
			return Err(
				Error.EnvironmentVariableError(`invalid file path '{value}'`)
			)
		end

		return Ok(value):andThen(locateFromDirectory)
	end)
end

local function locateWindows(): Result<RobloxStudio>
	local query = process.spawn("reg.exe", {
		"query",
		"hkcu\\SOFTWARE\\Roblox\\RobloxStudio",
		"/v",
		"ContentFolder",
	})

	if not query.ok then
		return Err(Error.RegistryError)
	end

	local queryResult = Some(string.match(query.stdout, "REG_SZ%s*(.-)%s*[\r\n]"))
		:map(efs.normalizePath)
		:map(function(path: string)
			return Ok(path)
		end)
		:unwrapOr(Err(Error.MalformedRegistry))

	return queryResult
		:andThen(function(content: string)
			return locatePlugins():map(function(plugins: string)
				return {
					content = content,
					plugins = plugins,
				}
			end)
		end)
		:andThen(function(folders)
			local root = efs.getParentDir(folders.content)

			return Ok({
				content = folders.content,
				application = root .. "/RobloxStudioBeta.exe",
				builtInPlugins = root .. "/BuiltInPlugins",
				plugins = folders.plugins,
				root = root,
			})
		end)
end

local function locateMacos()
	return locateFromDirectory("/Applications/RobloxStudioBeta.app")
end

local function locateTargetSpecific(): Result<RobloxStudio>
	if process.os == "windows" then
		return locateWindows()
	end

	if process.os == "macos" then
		return locateMacos()
	end

	return Err(Error.PlatformNotSupported)
end

local function locate(): Result<RobloxStudio>
	return locateFromEnv():unwrapOrElse(locateTargetSpecific)
end

return locate
