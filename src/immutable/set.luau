local function set<T, K, V>(t: T, k: K, v: V): T
	local new: any = table.clone(t :: any)
	new[k] = v
	return new
end

return set
