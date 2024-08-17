local gt = require("@pkg/greentea")

local Creator = gt.oneOf({
	userId = gt.string(),
}, {
	groupId = gt.string(),
})

export type Creator = typeof(Creator)

local CreationContext = {
	creator = Creator,
	expectedPrice = gt.opt(gt.string()),
}

export type CreationContext = typeof(CreationContext)

local ModerationResult = {
	moderationState = gt.string(),
}

export type ModerationResult = typeof(ModerationResult)

local Preview = {
	asset = gt.string(),
	altText = gt.string(),
}

export type Preview = typeof(Preview)

local Asset = {
	assetType = gt.string(),
	assetId = gt.string(),
	creationContext = CreationContext,
	description = gt.string(),
	displayName = gt.string(),
	path = gt.string(),
	revisionId = gt.string(),
	revisionCreateTime = gt.string(),
	moderationResult = ModerationResult,
	icon = gt.opt(gt.string()),
	preview = gt.opt(gt.array(Preview)),
}

export type Asset = typeof(Asset)

local AssetVersion = {
	creationContext = CreationContext,
	moderationResult = ModerationResult,
	path = gt.string(),
}

export type AssetVersion = typeof(AssetVersion)

return {
	Asset = Asset,
	AssetVersion = AssetVersion,
	CreationContext = CreationContext,
	Creator = Creator,
	ModerationResult = ModerationResult,
	Preview = Preview,
}
