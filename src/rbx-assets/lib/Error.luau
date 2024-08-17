local Error = require("@lib/Error")

export type Error = Error.Error

return {
	ParseError = Error("ParseError", "An error occurred while parsing\n$1"),
	ReadError = Error("ReadError", "An error occurred while reading $1\n$2"),

	InvalidPlaceVersionPath = Error(
		"InvalidPlaceVersion",
		"Invalid path for place version\n$1"
	),
	BatchGetAssetError = Error(
		"BatchGetAssetError",
		"Failed to retrieve assets:\n$1"
	),
	DownloadPlaceError = Error(
		"DownloadPlaceError",
		"Failed to download place '$1':\n$2"
	),
	UnknownDownloadPlaceError = Error(
		"UnknownDownloadPlaceError",
		"An unknown error occured while downloading place '$1'"
	),
	GetPlaceVersionError = Error(
		"GetPlaceInfoError",
		"Failed to get place version information for '$1':\n$2"
	),
	InvalidPlaceName = Error(
		"InvalidPlaceName",
		"'$1' is not a valid place name."
	),
	InvalidInstallerPath = Error(
		"InvalidInstallerPath",
		"Invalid path for installer: $1"
	),
	InstallerError = Error(
		"InstallerError",
		"An error occured while running an installer:\nInstaller '$1':\n:$2"
	),

	NoLockfile = Error("NoLockfile", "Failed to find a lockfile"),
	InvalidLockfile = Error("InvalidLockfile", "Invalid lockfile\n$1"),

	ConfigWriteError = Error("ConfigWriteError", "Failed to write to $1:\n$2"),
	NoConfig = Error(
		"NoConfig",
		"rbx-assets requires a config, but no $1 file was found"
	),
	InvalidConfig = Error("InvalidConfig", "Invalid config\n$1"),

	UnrecognizedPlace = Error(
		"InvalidPlace",
		"Unrecognized place name. Expected one of: $@"
	),
	RobloxStudioOpenFailure = Error(
		"RobloxStudioOpenFailure",
		"Failed to open Roblox Studio: $1"
	),
}
