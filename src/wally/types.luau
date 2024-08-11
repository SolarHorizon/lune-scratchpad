export type SemVer = string

export type Package = {
	authors: { string },
	description: string,
	exclude: { string },
	include: { string },
	license: string,
	name: string,
	realm: "server" | "shared" | "dev",
	registry: string,
	version: SemVer,
}

export type Manifest = {
	package: Package,
	place: { sharedPackages: string? },
	dependencies: { [string]: Dependency },
	serverDependencies: { [string]: Dependency },
}

export type Dependency = {
	scope: string,
	name: string,
	version: SemVer,
}

export type LockPackage = {
	name: string,
	version: SemVer,
	dependencies: { { LockPackage } },
}

export type Lockfile = {
	registry: string,
	package: { LockPackage },
}

return nil
