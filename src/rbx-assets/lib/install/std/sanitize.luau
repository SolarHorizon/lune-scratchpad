local function sanitize(path: string)
	return string.gsub(path, "[^%w_]", "_")
end

return sanitize
