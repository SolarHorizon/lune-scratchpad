local net = require("@lune/net")

local decode = require("./decode")

local function jsonDecode<T>(body: string, type: T?)
	return decode(body, net.jsonDecode, type)
end

return jsonDecode
