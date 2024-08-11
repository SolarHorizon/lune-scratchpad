local Chain = {}
Chain.__index = Chain

type Chain<K, V> = typeof(setmetatable(
	{} :: {
		_value: { { [K]: V } },
	},
	Chain
))

local function flatten(values)
	local result = {}

	for _, value in values do
		if Chain.is(value) then
			local nested = flatten(value._value)

			for key, nestedValue in nested do
				table.insert(result, nestedValue)
			end
		else
			table.insert(result, value)
		end
	end

	return result
end

function Chain.new<K, V>(...): Chain<K, V>
	return setmetatable({
		_value = flatten({ ... }),
	}, Chain)
end

function Chain.next<K, V>(self: Chain<K, V>, last: { any }?): ({ any }?, V?)
	local keys: { any } = last or {}

	local targetIndex, target = next(self._value, keys[1])

	if targetIndex == nil then
		return nil
	end

	local key, value = next(target, keys[2])

	if key == nil then
		return self:next({ targetIndex })
	else
		targetIndex = keys[1]
	end

	return { targetIndex, key } :: { any }, value
end

function Chain.get<K, V>(self: Chain<K, V>, keys: { any }?): V?
	if keys == nil or keys[1] == nil or keys[2] == nil then
		return nil
	end

	local target = self._value[keys[1]]

	if target == nil then
		return nil
	end

	return target[keys[2]]
end

function Chain.is(value: any): boolean
	return typeof(value) == "table" and getmetatable(value) == Chain
end

function Chain:__iter()
	return Chain.next, self
end

function Chain:__len()
	local len = 0

	for _, t in self._value do
		len += #t
	end

	return len
end

return Chain
