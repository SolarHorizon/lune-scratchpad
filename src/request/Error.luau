local Error = require("@lib/Error")

export type Error = Error.Error

return {
	HttpError = Error("HttpError", "HTTP Error: $1 $2"),
	ParseError = Error(
		"ParseError",
		"An error occurred while parsing response\n$1"
	),
	MalformedResponse = Error(
		"MalformedResponse",
		"The structure of the response body did not match what was expected\n$1"
	),
}
