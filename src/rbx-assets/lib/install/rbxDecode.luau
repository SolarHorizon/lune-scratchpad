local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Result = require("@lib/Result")
local decode = require("@lib/request/decode")

local Error = require("../Error")

local Ok = Result.Ok

type Error = Error.Error

local deserialize = {
	place = roblox.deserializePlace,
	model = roblox.deserializeModel,
}

-- sometimes roblox will return gzip even if we don't want it
local function decompress(body: string)
	if string.match(body, "^<roblox!") then
		return Ok(body)
	end

	return Result.from(serde.decompress, "gzip" :: any, body)
end

local function rbxDecode<T>(body: string, format: "place" | "model", type: T?)
	return decompress(body):andThen(function(content)
		return decode(content, deserialize[format], type)
	end)
end

return rbxDecode
