--[=[
	@within util
	@prop None None
]=]
local None = newproxy(true)

getmetatable(None).__tostring = function()
	return "<None>"
end

return None
