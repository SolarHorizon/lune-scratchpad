local process = require("@lune/process")

local PROG_NAME = process.env.PROGNAME or "rbx-assets"
local LOCKFILE = `{PROG_NAME}.lock`

return {
	LOCKFILE = LOCKFILE,
	PROG_NAME = PROG_NAME,
}
