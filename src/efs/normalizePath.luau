--[=[
	@within efs

	Replaces all slashes in a path with forward slashes. If `char` is specified,
	replaces all slashes with the given character instead. This is useful when
	ensuring compatibility with Windows-like paths that use backslashes, or for
	displaying Roblox-like paths that use dots.
]=]
local function normalizePath(path: string, char: string?): string
	char = char or "/"
	path = string.gsub(path, "\\+", char :: string)
	path = string.gsub(path, "/+", char :: string)
	return path
end

return normalizePath
