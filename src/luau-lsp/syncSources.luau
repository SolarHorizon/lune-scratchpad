local fs = require("@lune/fs")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local function normalize(str)
	local path = string.gsub(str, "\\+", "/")
	path = string.gsub(path, "//+", "/")
	return path
end

local function trim(str, pattern)
	return string.match(str, `^(.+){pattern}$`) or str
end

local function syncSources(darkluaConfigPath: string?)
	local darkluaConfig = darkluaConfigPath or ".darklua.json"

	local darklua = serde.decode("json", fs.readFile(darkluaConfig))
	local luaurc = serde.decode("json", fs.readFile(".luaurc"))

	local sources = {}

	if luaurc.aliases then
		for name, path in luaurc.aliases do
			sources["@" .. name] = trim(normalize(path), "/")
		end
	end

	if luaurc.paths then
		for _, path in luaurc.paths do
			if not fs.isDir(path) then
				stdio.ewrite(
					stdio.color("yellow")
						.. `[luaurc.paths] Not a directory: {path}`
						.. stdio.color("reset")
				)
				continue
			end

			for _, name in fs.readDir(path) do
				if string.match(name, "^_") then
					continue
				end

				sources[trim(name, "%.luau?") or name] =
					normalize(`{path}/{name}`)
			end
		end
	end

	for _, rule in darklua.rules do
		if rule.rule == "convert_require" then
			rule.current.sources = sources
		end

		fs.writeFile(darkluaConfig, serde.encode("json", darklua, true))
	end

	if fs.isDir(".vscode/") and fs.isFile(".vscode/settings.json") then
		local vscode =
			serde.decode("json", fs.readFile(".vscode/settings.json"))
		local fileAliases = {}
		local directoryAliases = {}

		for alias, path in sources do
			if fs.isDir(path) then
				local init = `{path}/init.luau`

				if not fs.isFile(init) then
					directoryAliases[alias] = path
					continue
				else
					path = init
				end
			end

			fileAliases[alias] = path
		end

		if next(fileAliases) then
			vscode["luau-lsp.require.fileAliases"] = fileAliases
		end

		if next(directoryAliases) then
			vscode["luau-lsp.require.directoryAliases"] = directoryAliases
		end

		fs.writeFile(
			".vscode/settings.json",
			serde.encode("json", vscode, true)
		)
	end
end

return syncSources
