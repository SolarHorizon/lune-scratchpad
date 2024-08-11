local Result = require("@lib/Result")

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local types = require("./types")

local Ok, Err = Result.Ok, Result.Err
local r = Result.from

type Result<T, E> = Result.Result<T, E>
type Lockfile = types.Lockfile
type Dependency = types.Dependency

-- { [1]: alias, [2]: scope/name@version }
type LockDependency = { string }

type RawLockPackage = {
	name: string,
	version: string,
	dependencies: { LockDependency },
}

type RawLockfile = {
	registry: string,
	package: { RawLockPackage },
}

local function loadLockfile(path: string): Result<Lockfile, string>
	return r(fs.readFile, path):andThen(function(raw)
		return r(serde.decode, "toml" :: any, raw)
	end):andThen(function(content: RawLockfile)
		local lockfile: Lockfile = {
			registry = content.registry,
			package = {},
		}

		local dependencies: { [string]: Dependency } = {}

		for i, package in content.package do
			local scope, name = string.match(package.name, "(.+)/(.+)")

			if not scope or not name then
				return Err(
					`Could not match scope or name from "{package.name}"`
				)
			end

			local dependency = {
				scope = scope,
				name = name,
				version = package.version,
				dependencies = {},
			}

			dependencies[package.name .. package.version] = dependency
			lockfile.package[i] = dependency
		end

		return Ok(lockfile)
	end)
end

return loadLockfile
