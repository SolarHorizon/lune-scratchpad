-- local process = require("@lune/process")

-- local locate = require("../locate")
--
-- locate()
-- 	:inspect(function(studio)
-- 		print(studio)
-- 		local args =
-- 			`roblox-studio:1+task:EditPlace+universeId:{5798411917}+placeId:{16877409153}`
-- 		process.spawn(studio.application, { args })
-- 	end)
-- 	:inspectErr(function(err)
-- 		print(tostring(err))
-- 	end)

local Opener = require("../Opener")

Opener.new():openFile("./test.rbxl"):unwrap():run():inspectErr(function(e)
	--Opener.new():openPlace(5338844978, 15472100873):run():inspectErr(function(e)
	print(e.stderr)
end)
