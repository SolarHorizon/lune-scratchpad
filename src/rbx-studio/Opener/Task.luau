local Option = require("@lib/Option")

type Option<T> = Option.Option<T>

local Task = {}
Task.__index = Task

type Task = typeof(setmetatable(
	{} :: {
		_id: string,
	},
	Task
))

function Task.__tostring(self: Task)
	return self._id
end

local function new(id: string): Task
	return setmetatable({
		_id = id,
	}, Task)
end

local tasks = {
	EditFile = new("EditFile"),
	EditPlace = new("EditPlace"),
	StartClient = new("StartClient"),
	StartServer = new("StartServer"),
}

local strMap = {
	editplace = tasks.EditPlace,
	edit_place = tasks.EditPlace,
	["edit-place"] = tasks.EditPlace,

	editfile = tasks.EditFile,
	edit_file = tasks.EditFile,
	["edit-file"] = tasks.EditFile,

	startclient = tasks.StartClient,
	start_client = tasks.StartClient,
	["start-client"] = tasks.StartClient,

	startserver = tasks.StartServer,
	start_server = tasks.StartServer,
	["start-server"] = tasks.StartServer,
}

function tasks.parse(str: string): Option<Task>
	return Option.Some(strMap[string.lower(str)])
end

return tasks
