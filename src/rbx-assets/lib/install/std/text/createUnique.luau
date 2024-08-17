local function createUnique()
	local storage = {}

	return function(str: string)
		if not storage[str] then
			storage[str] = 0
			return str
		end

		storage[str] += 1

		return `{str}_{storage[str]}`
	end
end

return createUnique
