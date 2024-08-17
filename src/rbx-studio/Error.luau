local Error = require("@lib/Error")

export type Error = Error.Error

return {
	DocumentsDirectoryNotFound = Error(
		"DocumentsDirectoryNotFound",
		"Couldn't find Documents directory"
	),
	MalformedRegistry = Error(
		"MalformedRegistry",
		"The values of the registry keys used to find Roblox are malformed, maybe your Roblox installation is corrupt?"
	),
	PlatformNotSupported = Error(
		"PlatformNotSupported",
		"Your platform is not currently supported"
	),
	PluginsDirectoryNotFound = Error(
		"PluginsDirectoryNotFound",
		"Couldn't find Plugins directory"
	),
	RegistryError = Error(
		"RegistryError",
		"Couldn't find registry keys, Roblox might not be installed."
	),
	EnvironmentVariableError = Error(
		"EnvironmentVariableError",
		"Environment variable misconfigured: $1"
	),
	NotInstalled = Error("NotInstalled", "Couldn't find Roblox Studio"),
}
