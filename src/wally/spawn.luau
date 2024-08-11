local process = require("@lune/process")

local Result = require("@lib/Result")

local Ok, Err = Result.Ok, Result.Err

local function spawn(program, params, options)
	return Result.fromSpawnResult(process.spawn(program, params, options))
		:match({
			Ok = function(ok: process.SpawnResult)
				return Ok(ok.stdout)
			end,
			Err = function(err: process.SpawnResult)
				return Err(err.stderr)
			end,
		})
end

return spawn
