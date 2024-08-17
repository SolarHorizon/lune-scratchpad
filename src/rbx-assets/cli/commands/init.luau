local edit = require("./edit")
local initialize = require("./initialize")
local install = require("./install")
local update = require("./update")

return {
	edit = edit,
	init = initialize,
	install = install,
	update = update,
}
