local controlFlow = {}

controlFlow.None = setmetatable({}, {
	__tostring = function()
		return "Iter<None>"
	end,
})

export type None = typeof(controlFlow.None)

controlFlow.Nil = setmetatable({}, {
	__tostring = function()
		return "Iter<Nil>"
	end,
})

export type Nil = typeof(controlFlow.Nil)

local Break = {
	__tostring = function(self)
		return `Iter<Break<{tostring(self.value)}>>`
	end,
	__eq = function(self, other)
		return getmetatable(self) == getmetatable(other)
			and self.value == other.value
	end,
}

function controlFlow.Break(value: any)
	return setmetatable({
		value = value,
	}, Break)
end

export type Break<T = any> = typeof(controlFlow.Break(({} :: any) :: T?))

function controlFlow.isBreak(value: any)
	return getmetatable(value) == Break
end

return controlFlow
