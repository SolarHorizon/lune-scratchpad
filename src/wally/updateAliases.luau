local Option = require("@lib/Option")
local Result = require("@lib/Result")

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local lsp = require("@lib/luau-lsp")

type Option<T> = Option.Option<T>
type Result<T, E> = Result.Result<T, E>
type Luaurc = lsp.Luaurc

type Options = {
	luaurc: string,
	packageDirs: { string },
	updateEffect: (() -> ())?,
}

local Ok = Result.Ok
local r = Result.from

local function updateAliases(options: Options): Result<boolean, string>
	return lsp.loadLuaurc(options.luaurc):andThen(function(opt: Option<Luaurc>)
		if opt:isNone() then
			return Ok(false)
		end

		if options.updateEffect then
			options.updateEffect()
		end

		local luaurc = opt:expect(".luaurc file does not exist!")

		if
			luaurc.paths
			and (
				table.find(luaurc.paths, "Packages")
				or table.find(luaurc.paths, "./Packages")
				or table.find(luaurc.paths, "ServerPackages")
				or table.find(luaurc.paths, "./ServerPackages")
			)
		then
			return Ok(false)
		end

		if not luaurc.aliases then
			luaurc.aliases = {}
		end

		for _, dir in options.packageDirs do
			if
				not r(fs.isDir, dir):isOkAnd(function(value)
					return value
				end)
			then
				continue
			end

			local result = r(fs.readDir, dir):inspect(function(files)
				for _, name in files do
					local alias = string.match(name, "(.+)%.")

					if alias and luaurc.aliases then
						luaurc.aliases[alias] = `{dir}/{name}`
					end
				end
			end)

			if result:isErr() then
				return result:map(function()
					return false
				end)
			end
		end

		return r(serde.encode, "json" :: any, luaurc, true):andThen(
			function(json)
				return r(fs.writeFile, options.luaurc, json)
			end
		)
	end)
end

return updateAliases
