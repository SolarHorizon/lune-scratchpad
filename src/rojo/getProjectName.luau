local efs = require("@lib/efs")

--[=[
	@within rojo

	Strips the file extension from a rojo project name.

	```lua
	local name = getProjectName("default.project.json")

	print(name) -- "default"
	```
]=]
local function getProjectName(file: string): string?
	local name = efs.getFileName(file)

	local segments = string.split(name, ".")

	if
		not segments
		or #segments ~= 3
		or segments[2] ~= "project"
		or segments[3] ~= "json"
	then
		return
	end

	return segments[1]
end

return getProjectName
