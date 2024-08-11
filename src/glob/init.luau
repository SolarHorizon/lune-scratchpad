--!strict
local reg = require("@lune/regex")
local Regex = reg.new

local SEP = `\\/`
local SEP_ESC = `/`
local GLOBSTAR = `((?:[^/]*(?:/|$))*)`
local WILDCARD = `([^/]*)`
local GLOBSTAR_SEGMENT = `((?:[^{SEP_ESC}]*(?:{SEP_ESC}|$))*)`
local WILDCARD_SEGMENT = `([^{SEP_ESC}]*)`

export type resultType = {
	path: {
		globstar: reg.Regex,
		regex: string | reg.Regex,
		segments: { reg.Regex },
	}?,
	regex: reg.Regex,
}

--- Convert any glob pattern to a Regex object
--- @param glob glob Glob pattern to convert
--- @param Option opts Configuration object
--- @param {Boolean} [opts.extended=true] Support advanced ext globbing
--- @param {Boolean} [opts.globstar=true] Support globstar
--- @param {Boolean} [opts.strict=true] be laissez faire about mutiple slashes
--- @param {Boolean} [opts.filepath=''] Parse as filepath for extra path related features
--- @param {String} [opts.flags=''] Regex globs
--- @returns {Object} converted object with string, segments and Regex object
function globrex(
	glob: string,
	option: {
		extended: boolean?,
		globstar: boolean?,
		strict: boolean?,
		filepath: boolean?,
		flags: string?,
	}?
)
	option = if option then option else {}
	local extended = if (option :: any).extended
		then (option :: any).extended
		else true
	local globstar = if (option :: any).globstar
		then (option :: any).globstar
		else true
	local strict = if (option :: any).strict
		then (option :: any).strict
		else true
	local filepath = if (option :: any).filepath
		then (option :: any).filepath
		else false
	local flags = if (option :: any).flags then (option :: any).flags else ""

	local regex = ""
	local segment = ""
	local path = { regex = "" :: string | typeof(Regex("")), segments = {} }

	local inGroup = false
	local inRange = false

	local ext = {}

	local function add(
		str: string,
		split: boolean?,
		last: boolean?,
		only: string?
	)
		if only ~= "path" then
			regex = `{regex}{str}`
		end
		if filepath and only ~= "regex" then
			path.regex = `{path.regex}{if str == "\\/" then SEP else str}`
			if split then
				if last then
					segment = `{segment}{str}`
				end
				if segment ~= "" then
					if not (flags :: string):find("g") then
						segment = `^{segment}$`
					end
					table.insert(path.segments, Regex(`{segment}{flags}`))
				end
				segment = ""
			else
				segment = `{segment}{str}`
			end
		end
	end

	local c, n
	local i = 0
	while i <= string.len(glob) do
		i += 1
		c = glob:sub(i, i)
		n = glob:sub(i + 1, i + 1)

		if table.find({ "\\", "$", "^", ".", "=" }, c) then
			add(`\\{c}`)
			continue
		end

		if c == "/" then
			add(`\\{c}`, true)
			if (n == "/") and not strict then
				regex = `{regex}?`
			end
			continue
		end

		if c == "(" then
			if #ext ~= 0 then
				add(c)
				local type = table.remove(ext) :: string
				if type == "@" then
					add("{1}")
				elseif type == "!" then
					add("([^/]*)")
				else
					add(type)
				end
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "|" then
			if #ext ~= 0 then
				add(c)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "+" then
			if n == "(" and extended then
				table.insert(ext, c)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "@" and extended then
			if n == "(" then
				table.insert(ext, c)
				continue
			end
		end

		if c == "!" then
			if extended then
				if inRange then
					add("^")
					continue
				end
				if n == "(" then
					table.insert(ext, c)
					add("(?!")
					i += 1
					continue
				end
				add(`\\{c}`)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "?" then
			if extended then
				if n == "(" then
					table.insert(ext, c)
				else
					add(".")
				end
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "[" then
			if inRange and n == ":" then
				i += 1
				local value = ""
				while glob:sub(i + 1, i + 1) ~= ":" do
					value = `{value}{glob:sub(i, i)}`
					i += 1
				end
				if value == "alnum" then
					add("(\\w|\\d)")
				elseif value == "space" then
					add("\\s")
				elseif value == "digit" then
					add("\\d")
				end
				i += 1
				continue
			end
			if extended then
				inRange = true
				add(c)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "]" then
			if extended then
				inRange = false
				add(c)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "{" then
			if extended then
				inGroup = true
				add("(")
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "}" then
			if extended then
				inGroup = false
				add(")")
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "," then
			if inGroup then
				add("|")
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "*" then
			if n == "(" and extended then
				table.insert(ext, c)
				continue
			end

			local prevChar = glob:sub(i - 1, i - 1)
			local starCount = 1
			while glob:sub(i + 1, i + 1) == "*" do
				starCount += 1
				i += 1
			end
			local nextChar = glob:sub(i + 1, i + 1)
			if not globstar then
				add(".*")
			else
				local isGlobstar = if (
						starCount > 1
						and (prevChar == "/" or prevChar == string.sub("w", 0, 0))
						and (
							nextChar == "/"
							or nextChar == string.sub("w", 0, 0)
						)
					)
					then true
					else false
				if isGlobstar then
					add(GLOBSTAR, nil, nil, "regex")
					add(GLOBSTAR_SEGMENT, true, true, "path")
					i += 1
				else
					add(WILDCARD, nil, nil, "regex")
					add(WILDCARD_SEGMENT, nil, nil, "path")
				end
			end
			continue
		end

		add(c)
	end

	if not (flags :: string):find("g") then
		regex = `^{regex}$`
		segment = `^{segment}$`
		if filepath then
			path.regex = `^{path.regex}$`
		end
	end

	local result = { regex = Regex(`{regex}{flags}`) }

	if filepath then
		table.insert(path.segments, Regex(`{segment}{flags}`))
		path.regex = Regex(`{path.regex}{flags}`)
		path.globstar = Regex(
			if not (flags :: string):find("g")
				then `^{GLOBSTAR_SEGMENT}$`
				else `{GLOBSTAR_SEGMENT}{flags}`
		)
		result.path = path
	end

	return result :: resultType
end

return globrex
