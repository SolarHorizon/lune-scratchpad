local lsp = require("@lib/luau-lsp")
local process = require("@lune/process")

local config = process.args[1]

lsp.syncSources(config)
