local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local function dotenv()
	local content

	if fs.isFile(`{process.cwd}/.env`) then
		content = fs.readFile(`{process.cwd}/.env`)
	end

	if content then
		for key, value in serde.decode("toml", content) do
			process.env[key] = value
		end
	end

	return process.env
end

return dotenv
