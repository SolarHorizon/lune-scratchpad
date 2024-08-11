local Error = require("@lib/Error")

export type Error = Error.Error

return {
	MissingAuthCookie = Error(
		"InvalidAuthCookie",
		"Cannot authenticate user without an auth cookie"
	),
	InvalidRequest = Error("InvalidRequest", "Invalid format for request"),
}
