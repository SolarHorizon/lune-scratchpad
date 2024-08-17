local gt = require("@pkg/greentea")

local Place = {
	allowCopying = gt.boolean(),
	allowedGearTypes = gt.array(gt.any()),
	currentSavedVersion = gt.number(),
	customSocialSlotsCount = gt.number(),
	description = gt.string(),
	id = gt.number(),
	isAllGenresAllowed = gt.boolean(),
	isRootPlace = gt.boolean(),
	maxPlayerCount = gt.number(),
	maxPlayersAllowed = gt.number(),
	name = gt.string(),
	socialSlotType = gt.string(),
	universeId = gt.number(),
}

export type Place = typeof(Place)

return {
	Place = Place,
}
