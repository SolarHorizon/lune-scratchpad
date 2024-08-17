local gt = require("@pkg/greentea")

local Asset = {
	IsCopyrightProtected = gt.boolean(),
	IsHashDynamic = gt.boolean(),
	isArchived = gt.boolean(),
	requestId = gt.string(),
	locations = gt.array({
		assetFormat = gt.string(),
		location = gt.string(),
	}),
}

export type Asset = typeof(Asset)

local BatchAssetError = {
	code = gt.number(),
	message = gt.string(),
}

local BatchAsset = {
	IsCopyrightProtected = gt.boolean(),
	IsHashDynamic = gt.boolean(),
	isArchived = gt.boolean(),
	requestId = gt.string(),
	location = gt.opt(gt.string()),
	errors = gt.opt(gt.array(BatchAssetError)),
}

export type BatchAsset = typeof(BatchAsset)

local AssetRequestItem = {
	["roblox-assetFormat"] = gt.opt(gt.string()),
	accept = gt.opt(gt.string()),
	assetFormat = gt.opt(gt.string()),
	assetId = gt.opt(gt.number()),
	assetName = gt.opt(gt.string()),
	assetType = gt.opt(gt.string()),
	assetVersionId = gt.opt(gt.number()),
	clientInsert = gt.opt(gt.boolean()),
	contentRepresentationPriorityList = gt.opt(gt.string()),
	doNotFallbackToBaselineRepresentation = gt.opt(gt.boolean()),
	encoding = gt.opt(gt.string()),
	hash = gt.opt(gt.string()),
	modulePlaceId = gt.opt(gt.number()),
	placeId = gt.opt(gt.number()),
	requestId = gt.opt(gt.string()),
	scriptInsert = gt.opt(gt.boolean()),
	serverPlaceId = gt.opt(gt.number()),
	universeId = gt.opt(gt.number()),
	userAssetId = gt.opt(gt.number()),
	version = gt.opt(gt.number()),
}

export type AssetRequestItem = typeof(AssetRequestItem)

return {
	Asset = Asset,
	BatchAsset = BatchAsset,
	AssetRequestItem = AssetRequestItem,
}
