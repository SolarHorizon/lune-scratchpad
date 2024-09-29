local glob = require("@lib/glob")

local ws = glob("game/Workspace/**/Assets")
print(ws.regex:find("game/Workspace/Model/Model/Model/Model/Model/Assets"))

local feat = (glob("src/*/{shared,client}/init.lu{a,au}"))
print(feat.regex:find("src/feature/shared/init.luau"))
