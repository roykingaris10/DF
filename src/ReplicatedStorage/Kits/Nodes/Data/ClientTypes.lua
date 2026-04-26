export type Client = {
	-- GlobalModules
	Debris: any, -- Replace 'any' with actual module type
	Utilities: any,
	EffectFunctions: any,

	-- GameInfo
	AnimationData: any,
	CharacterCustomizationInfo: any,
	FactionInfo: any,
	LibraryInfo: any,
	OutfitInfo: any,
	RaceChances: any,
	ShopInfo: any,
	WeaponData: any,
	WeldInfo: any,

	-- ClientNetwork
	ClientNetwork: any,

	-- CharSetup
	CharacterHandler: any,
	Inputter: any,
	ClientAnimator: any,
	CooldownClient: any,
	EntityClient: any,
	HSMachine: any,
	MovementClient: any,

	-- ClientModules
	UISetup: any,
	CrewClient: any,
	EffectsClient: any,
	FootstepsClient: any,
	PlayerList: any,
	DialogueHandler: any,
	FactionClient: any,
	Entity: any, 
	InventoryClient: any,
	ShopHandler: any,
	RegionController: any,
	TimeWeatherController: any,
	MenuClient: any,
	TopbarController: any,
	SettingsController: any,
	PartyClient: any,
	CompassController: any,
	NotificationHolder: any,

	-- Add all other modules here
}

return nil