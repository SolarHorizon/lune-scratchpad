local Error = require("@lib/Error")

return {
	PathCanonicalize = Error(
		"PathCanonicalize",
		"Failed to canonicalize path: $1"
	),
}
