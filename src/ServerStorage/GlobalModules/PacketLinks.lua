local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes
local Packet = require(Nodes.Utility.Packets)

local NewSlotCreated = {
	FirstName = Packet.String;
	Gender = Packet.String;
	DreamTrait = Packet.String;
};

local CrewMember = {
	UserId = Packet.NumberU32;
	Rank = Packet.String;
	JoinedAt = Packet.NumberU32;
};

local CrewSummary = {
	CrewId = Packet.String;
	Name = Packet.String;
	Rank = Packet.String;
	Members = { CrewMember}; -- array form; TableToFunctions handles this
};

local EffectData = {
	EffectModule = Packet.Instance;
	Func = Packet.String;
	Caster = Packet.Instance;
	ServerCall = Packet.Boolean8
};

local ClientEffectData = {
	EffectModule = Packet.Instance;
	Func = Packet.String;
}

local HitIdentity = {
	CurrentWeapon = Packet.String;
	AttackType = Packet.String;
	CurrentAttack = Packet.NumberU8;
	CurrentId = Packet.String;
	InAir = Packet.Boolean8;
};

local CriticalHitIdentity = {
	CurrentWeapon = Packet.String;
	AttackType = Packet.String;
	CurrentId = Packet.String;
	InAir = Packet.Boolean8;
	Timestamp = Packet.NumberU32;
};

local AerialIdentity = {
	CurrentWeapon = Packet.String;
	AttackType = Packet.String;
	CurrentId = Packet.String;
	InAir = Packet.Boolean8;
	Timestamp = Packet.NumberU32;
};

local ClashHitIdentity = {
	CurrentWeapon = Packet.String;
	AttackType = Packet.String;
	CurrentId = Packet.String;
	InAir = Packet.Boolean8;
	Timestamp = Packet.NumberU32;
};

-- for invoke add the :Response() func at the end
local Links = {
	--//Server >> Client
	EquippedWeaponInfo = Packet("EquippedWeaponInfo",Packet.String);
	InventoryUpdate = Packet("InventoryUpdate",Packet.String);
	DisplayCooldown = Packet("DisplayCooldown",Packet.String,Packet.NumberU8);
	CooldownSet = Packet("CooldownSet",Packet.String,Packet.NumberU8);
	CooldownRemove = Packet("CooldownRemove",Packet.String);
	--//Client >> Server
	
	LightAttack = Packet("LightAttack",HitIdentity);
	RegisterHit = Packet("RegisterHit",{HitChars = {Packet.Any},HitIdentity = HitIdentity});
	Critical = Packet("Critical",CriticalHitIdentity);
	CriticalHit = Packet("CriticalHit",{HitChars = {Packet.Any},HitIdentity = CriticalHitIdentity});
	RegisterHeavyClash = Packet("RegisterHeavyClash",{HitIdentity = ClashHitIdentity});
	Aerial = Packet("Aerial",AerialIdentity);
	ChangeItemSlot = Packet("ChangeItemSlot",Packet.String,Packet.NumberU8);
	ActionItem = Packet("ActionItem",{Name = Packet.String,Id = Packet.String});
	Dash = Packet("Dash",{Held = Packet.Boolean8,MoveDirection = Packet.String});
	--//Invokes
	FilterName = Packet("FilterName",Packet.String):Response(Packet.String);
	RequestSlots = Packet("RequestSlots"):Response(Packet.NumberU16);
	NewSlotCreated = Packet("NewSlotCreated",Packet.NumberU16,NewSlotCreated):Response(Packet.Boolean8,Packet.String);
	CurrentRace = Packet("CurrentRace",Packet.NumberU16):Response(Packet.String);
	TestUp = Packet("TestUp",Packet.String);
	RacePurchased = Packet("RacePurchased",Packet.String);
	PendingSlotCreation = Packet("PendingSlotCreation",Packet.NumberU16);
	RemoveSlotCreation = Packet("RemoveSlotCreation");
--	RegisterHit = Packet("RegisterHit",RegisterHit);

	--//Crew Packet Links
	CreateCrew  = Packet("CrewCreate", Packet.String)
		:Response(Packet.Boolean8, Packet.String, Packet.String);

	DisbandCrew = Packet("CrewDisband", Packet.String)
		:Response(Packet.Boolean8, Packet.String);
	
	LeaveCrew = Packet("CrewLeave", Packet.String)
		:Response(Packet.Boolean8, Packet.String);

	CrewDisbanded = Packet("CrewDisbanded");
	CrewLeft = Packet("CrewLeft");
	
	CheckPlayerInCrew = Packet("CheckPlayerInCrew", Packet.String)
		:Response(Packet.Boolean8);

	CrewCreated = Packet("CrewCreated", Packet.String, Packet.String, Packet.Static1);
	CrewCreateFailed = Packet("CrewCreateFailed", Packet.String);

	JoinCrew = Packet("CrewJoin", Packet.String, Packet.String)
		:Response(Packet.Boolean8, Packet.String, Packet.String);

	GetCrewState = Packet("CrewStateRequest")
		:Response(Packet.Boolean8, Packet.String, Packet.String);
	
	GetFactionState = Packet("FactionStateRequest")
		:Response(Packet.Boolean8, Packet.String, Packet.String, Packet.NumberU32, Packet.String, Packet.NumberU16, Packet.String);

	JoinFaction = Packet("FactionJoin", Packet.String)
		:Response(Packet.Boolean8, Packet.String, Packet.String);

	LeaveFaction = Packet("FactionLeave")
		:Response(Packet.Boolean8, Packet.String);

	LevelRankUp = Packet("LevelRankUp", Packet.String, Packet.NumberU16);
	
	
	
	--//Cooldowns
--	SetCooldown = Packet("SetCooldown",Packet.String,{Packet.Any});

	--//VFX
	VFXAll = Packet("VFXAll",EffectData,{Packet.Any});
	VFXClient = Packet("VFXClient",EffectData,{Packet.Any});
	ClientEffectsAll = Packet("ClientEffectsAll",ClientEffectData,{Packet.Any});
	Unreliables = {
		
	}
	
}

Links.CreateCrew.ResponseTimeout = 15
Links.DisbandCrew.ResponseTimeout = 15
Links.LeaveCrew.ResponseTimeout = 15
Links.JoinCrew.ResponseTimeout = 15
Links.GetCrewState.ResponseTimeout = 15

Links.GetFactionState.ResponseTimeout = 15
Links.JoinFaction.ResponseTimeout = 15
Links.LeaveFaction.ResponseTimeout = 15

return Links
