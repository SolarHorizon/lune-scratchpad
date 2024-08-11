local Buffer = {}
Buffer.__index = Buffer

export type Buffer = typeof(setmetatable(
	{} :: {
		_value: string,
	},
	Buffer
))

-- this is silly, but i'm having trouble reading the code for rendering usage
-- and help information without it and this pattern made it easier for me
function Buffer.new(): Buffer
	return setmetatable({
		_value = "",
	}, Buffer)
end

function Buffer.write(self: Buffer, value: string?)
	self._value ..= tostring(value or "")
end

function Buffer.print(self: Buffer, value: string?)
	self._value ..= "\n" .. tostring(value or "")
end

function Buffer.__tostring(self: Buffer)
	return self._value
end

return Buffer
