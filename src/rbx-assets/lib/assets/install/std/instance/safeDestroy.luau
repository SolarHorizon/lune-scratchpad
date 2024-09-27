local roblox = require("@lune/roblox")

local function safeDestroy(instance: roblox.Instance)
	pcall(function()
		instance.Parent = nil
		instance:Destroy()
	end)
end

return safeDestroy
