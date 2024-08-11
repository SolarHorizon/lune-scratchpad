local function map<T, U, V, W>(
	t: { [T]: U },
	fn: (
		value: U,
		key: T,
		table: { [T]: U }
	) -> (W?, V?)
)
	local mapped = {}

	for k, v in t do
		local value, key = fn(v, k, t)
		mapped[key or k] = value
	end

	return mapped
end

return map
