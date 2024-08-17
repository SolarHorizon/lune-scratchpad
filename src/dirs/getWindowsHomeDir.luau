local process = require("@lune/process")

--[=[
	@within dirs

	Returns the Windows home directory. This is useful for anything that is
	meant to be compatible with WSL, like getting the Roblox Studio plugins
	folder.

	If you are writing code that will be natively running on Windows, use 
	`getHomeDir` instead.
]=]
local function getWindowsHomeDir(): string?
	local result = process.spawn("powershell.exe", { "-c", "$env:USERPROFILE" })

	if not result.ok then
		return nil
	end

	return string.match(result.stdout, "(.-)[\r\n]")
end

return getWindowsHomeDir
