local Option = require("@lib/Option")
local Result = require("@lib/Result")

type Option<T> = Option.Option<T>
type Result<T, E> = Result.Result<T, E>

local Some, None = Option.Some, Option.None
local Ok = Result.Ok
local r = Result.from

local fs = require("@lune/fs")
local serde = require("@lune/serde")

export type Luaurc = {
	languageMode: string?,
	aliases: { [string]: string }?,
	paths: { string }?,
}

local function loadLuaurc(path: string): Result<Option<Luaurc>, string>
	return r(fs.isFile, path):andThen(function(exists)
		if not exists then
			return Ok(None())
		end

		return r(fs.readFile, path):andThen(function(content)
			return r(serde.decode, "json" :: any, content):map(function(json)
				return Some(json)
			end)
		end)
	end)
end

return loadLuaurc
