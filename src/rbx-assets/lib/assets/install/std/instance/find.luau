local roblox = require("@lune/roblox")

local function find(root: roblox.Instance, path: string)
	for _, child in string.split(path, "/") do
		local found = root:FindFirstChild(child)

		if not found then
			error(`{child} is not a valid child of {root:GetFullName()}`)
		end

		root = found
	end

	return root
end

return find
