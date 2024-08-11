local Result = require("@lib/Result")

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local resolve = require("./resolve")
local types = require("./types")

local Ok, Err = Result.Ok, Result.Err
local r = Result.from

type Result<T, E> = Result.Result<T, E>
type Dependency = types.Dependency
type Package = types.Package
type Manifest = types.Manifest

type RawManifest = {
	package: Package,
	place: { ["shared-packages"]: string },
	dependencies: { [string]: string },
	serverDependencies: { [string]: string },
}

local function loadManifest(path: string): Result<Manifest, string>
	return r(fs.readFile, `{path}/wally.toml`):andThen(function(raw)
		return r(serde.decode, "toml" :: any, raw)
	end):andThen(function(content: RawManifest)
		local manifest = {
			package = content.package,
			place = {},
			dependencies = {},
			serverDependencies = {},
		}

		if content.place then
			manifest.place = {
				sharedPackages = content.place["shared-packages"],
			}
		end

		if content.dependencies then
			for name, dep in content.dependencies do
				local dependency = resolve.all(dep)

				if dependency:isOk() then
					manifest.dependencies[name] = dependency:unwrap()
				else
					return Err(dependency:unwrapErr())
				end
			end
		end

		if content["server-dependencies"] then
			for name, dep in content["server-dependencies"] do
				local dependency = resolve.all(dep)

				if dependency:isOk() then
					manifest.serverDependencies[name] = dependency:unwrap()
				else
					return Err(dependency:unwrapErr())
				end
			end
		end

		return Ok(manifest)
	end)
end

return loadManifest
