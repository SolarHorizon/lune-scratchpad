local frktest = {}

local assert = require("./assert")
local test = require("./test")

-- make sure to initalize a reporter before running, otherwise you will get no output
-- see `src/reporters` for builtin reporters available
-- returns false if any test failed, true otherwise
frktest.run = function(): boolean
	test.load_suites()
	return test.run_tests()
end

frktest.test = test
frktest.assert = assert

return frktest
