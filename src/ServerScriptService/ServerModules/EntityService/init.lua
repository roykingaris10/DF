local Server = require(script.Parent)

local Network = Server.Network
local Utilities = Server.Utilities
local CharacterCustomizationInfo = Server.CharacterCustomizationInfo
local LibraryInfo = Server.LibraryInfo
local ItemInfo = Server.ItemInfo

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")


local ProfileHandler = Server.DataProfileService;

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes
local MobTemplates = ServerStorage.Assets.Mobs
local TroveFactory = require(Nodes.Utility.Trove);
local Signal = require(Nodes.Utility.Signal);

local VFXManager = Server.VFXManager;
local CharacterManager = Server.CharacterManager;
local AnimatorManager = Server.AnimatorManager;
local InventoryManager = Server.InventoryManager;
local ActionManager = Server.ActionManager;
local CombatManager = Server.CombatManager;
local StatManager = Server.StatManager;
local EquipmentManager = Server.EquipmentManager
local CooldownManager = Server.CooldownManager;
local RunTimeManager = Server.RunTimeManager;


local Hitbox = Server.Hitbox

local Entities = {};
Entities.__index = Entities;
Entities.__tostring = function(self: {any})
	return self.Name;
end;

local LEADERSTATS_INSTANCES = {
	[1] = 'Level';
};

Entities.Stored = {};
Entities.new = function(PresetInfo: {any}?, PlayerObject: Player?)
	local self = setmetatable({
		_Trove = TroveFactory.new();
		_Connections = {};
		
		_Class = 'Entity';
		Name = 'N/A',
		
		Valid = true;
		Ready = false;		
		InGame = false,
		gameLoaded = false,
		EquippedWeapon = "Fists";
		
		Mode = false,
		InCombatTick = 0,
		StaminaTick = 0,
		LastHitTime = 0,
		LastPostureHit = 0,
		
		SpinCD = false,
		
		CrewData = {
			CrewId = "",
			CrewName = "",
			CreatedAt = 0,
			CaptainUserId = 0,
			Members = {},
			History = {},
		},
		
		player = PlayerObject;

		Server = {
			Status = {};
			Held = {};
	--		DefaultSpeed = Information:Get('Default').WalkSpeed;
	--		DefaultJump = Information:Get('Default').Jump;

			LandedHits = {};
			CancelledHits = {};
		};
	}, Entities);
	--[[]]
	if self.player then
		self.ProfileHolder = ProfileHandler.new(PlayerObject);
	end
	
	self.Data = (self.ProfileHolder and self.ProfileHolder.Data);
	--[[
	if not self.Data then
		self.Data = {};
		PresetInfo = PresetInfo or {};
		for i,v in ProfileHandler.ProfileTemplate do
			self.Data[i] = PresetInfo[i] or v;
		end;
	end;]]
	
	if self.player then
		self.SlotProfile = self.Data.Slots[self.Data.ServerData.ChosenSlot]
		if not self.SlotProfile then self.player:Kick("SLOT CREATION ISNT FINALIZED") self:Destroy() return end
	else
		self.SlotProfile = PresetInfo
	end
	
	self.Character = self._Trove:Add(CharacterManager.new(self));
	self.StatManager = self._Trove:Add(StatManager.new(self));
--	self.Hotbar = self._Trove:Add(Hotbar.new(self));
	self.ActionManager = self._Trove:Add(ActionManager.new(self));
	self.EquipmentManager = self._Trove:Add(EquipmentManager.new(self));
	self.Animator = self._Trove:Add(AnimatorManager.new(self));
--	self.Animator = self._Trove:Add(AnimatorManager.new(self));
	self.Cooldowns = self._Trove:Add(CooldownManager.new(self));
	self.Combat = self._Trove:Add(CombatManager.new(self));
	self.InventoryManager = self._Trove:Add(InventoryManager.new(self));
	self.VFX = self._Trove:Add(VFXManager.new(self));
	self.RunTime = self._Trove:Add(RunTimeManager.new(self));

	if self.player then
		self.Name = self.player.DisplayName or self.player.Name;
		self.StatManager:PlayerSetup()
		self.InventoryManager:StarterPack()
		--[[
		self.Leaderstats = Instance.new('Folder');
		self.Leaderstats.Parent = self.player;
		
		self.Leaderstats.Name = 'leaderstats';

		for i = 1,#LEADERSTATS_INSTANCES do
			local InstName = LEADERSTATS_INSTANCES[i];
			Instance.new('NumberValue', self.Leaderstats).Name = InstName;
		end;

		self:UpdateLeaderstats();
		
		self.Name = self.player.DisplayName or self.player.Name;
		]]
	end;
	self.CharacterChanged = self._Trove:Add(Signal.new());
	
	self.Ready = true;
	self.Stored[self] = true;

	return self;
end

Entities.Spawn = function(TemplateName: Model, PresetInfo: {any})
	local Template = MobTemplates:FindFirstChild(TemplateName);
	assert(TemplateName, 'Template was not found!');

	local NewEntity = Entities.new(PresetInfo);
	NewEntity.Character.Template = Template;

	return NewEntity;
end;

function Entities:CreateHitbox()
	return Hitbox.new(self);
end;

function Entities:FilterName(nameToFilter)
	local filteredInstance
	local filteredString
	local success, err = pcall(function()
		filteredInstance = TextService:FilterStringAsync(nameToFilter, self.player.UserId)
		filteredString = filteredInstance:GetNonChatStringForUserAsync(self.player.UserId)
	end)
	if success then
		return filteredString
	else
		warn("Error filtering crew name:", err)
		return nil
	end
end

function Entities:Destroy()
	for _,v: RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;

	self.ProfileHolder:Clean();
	self._Trove:Destroy();

	self.Valid = false;
	self.Stored[self] = nil;
end;


function Entities.Find(Inst: (Player | Model))
	local CheckingMethods = {
		Player = function(v)
			return v.player == Inst;
		end;
		Character = function(v)
			if not v.Character.Rig then return end;
			return v.Character.Rig == Inst;
		end;
	};

	local Method = (Inst:IsA('Player') and 'Player') or (Inst:IsA('Model') and 'Character');
	local MethodFunc = CheckingMethods[Method];

	assert(MethodFunc, 'Search method not found! Did you pass an instance?');
	for v in Entities.Stored do
		local Result = MethodFunc(v);
		if Result then return v end;
	end;
end;


return Entities;

