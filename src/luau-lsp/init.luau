local loadLuaurc = require("./loadLuaurc")
local syncSources = require("./syncSources")

export type Luaurc = loadLuaurc.Luaurc

return {
	loadLuaurc = loadLuaurc,
	syncSources = syncSources,
}
