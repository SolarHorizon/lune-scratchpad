-- trim leading whitespace
local function trim(str): string
	return (string.gsub(str, "^%s", ""))
end

local function wrap(str: string, width: number, offset: number?): string
	offset = offset or 0

	if #str + (offset :: number) < width then
		return str
	end

	local lines = {}
	local position = 0

	for finish in string.gmatch(str, "%s+%S+()") do
		if finish - position + offset :: number > width then
			table.insert(lines, trim(string.sub(str, position, finish)))
			position = finish
		end
	end

	local final = trim(string.sub(str, position, #str))
	if final ~= "" then
		table.insert(lines, final)
	end

	return table.concat(lines, "\n" .. string.rep(" ", offset :: number))
end

return wrap
