local None = require("./None")
local copyDeep = require("./copyDeep")

--[=[
	@within util
]=]
local function mergeDeep<T>(...: any): T
	local result = {}

	for dictionaryIndex = 1, select("#", ...) do
		local dictionary = select(dictionaryIndex, ...)

		if type(dictionary) ~= "table" then
			continue
		end

		for key, value in pairs(dictionary) do
			if value == None then
				result[key] = nil
			elseif type(value) == "table" then
				if result[key] == nil or type(result[key]) ~= "table" then
					result[key] = copyDeep(value)
				else
					result[key] = mergeDeep(result[key], value)
				end
			else
				result[key] = value
			end
		end
	end

	return result :: any
end

return mergeDeep
