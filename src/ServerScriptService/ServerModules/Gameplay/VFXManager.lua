local Server = require(script.Parent)

local Network = Server.Network
local Utilities = Server.Utilities
local CharacterCustomizationInfo = Server.CharacterCustomizationInfo
local LibraryInfo = Server.LibraryInfo
local Settings = Server.Settings
--//Variable
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');

local Kits = ReplicatedStorage.Kits

--//Module
local VFXManager = {};
VFXManager.__index = VFXManager;

VFXManager.new = function(Entity: {any})
	local self = setmetatable({
		
		Parent = Entity;
		
	}, VFXManager);
	
	return self;
end;

--Makeshift entity object for client-side
function VFXManager:GetClientEntity()
	return {
		Player = self.Parent.player;
		Character = {
			Humanoid = self.Parent.Character.Humanoid;
			Root = self.Parent.Character.Root;
			Rig = self.Parent.Character.Rig;	
		};
	};
end;
--[[
function PlayerData:VFXSender(SortTable,OriginTable,...)
	local character = self.NPC or self.player.Character
	local RootPart = character:WaitForChild("HumanoidRootPart")
	Network:postAll(
		"EffectsClient",
		{Sort = SortTable.Sort,Module = SortTable.Module},
		{Origin = OriginTable.Position,Range = OriginTable.Range},
		SortTable.Function,character,...
	)
end
]]
--function VFXManager:Fire(ModulePath: string, EffectName: string, Data: {any}, MaxDistance: number, Receiving: {any} | Player | nil)
function VFXManager:Fire(ModuleData: {any}, EffectName: string, EffectData: {any})
	local MainEntity = self:GetClientEntity();
	if EffectData then
		for i,v: {any}? in EffectData do
			if typeof(v) ~= 'table' then continue end;
			if v._Class ~= 'Entity' then continue end;
			EffectData[i] = v.VFX:GetClientEntity();
		end;
	end;
	assert(ModuleData.Module, debug.traceback('Need to Module!'));
	assert(ModuleData.SubModule, debug.traceback('Need to pass Submodule!'));
	Network:postAll("VFX",{
		Caster = MainEntity,
		LoadDistance = EffectData.MaxDistance or 500,
		Module = ModuleData.Module,
		SubModule = ModuleData.SubModule,
		Effect = EffectName,
		Data = EffectData,	
	})
end;

function VFXManager:FireClient(Data: {any}, EffectInfo: {any}, player: Player)
	local MainEntity = self:GetClientEntity();
	Data.Caster = MainEntity;
	local MaxDistance = Data.MaxDistance or 500
	Data.MaxDistance = nil
	Data.ServerCall = true;
	assert(Data.EffectModule, debug.traceback('Need to Module!'));
	assert(Data.Func, debug.traceback('Function Name Needed'));
	if not player then warn("MISSING PLAYER FOR VFXCLIENT") return end
	Server.PacketLinks["VFXClient"]:FireClient(player, Data, EffectInfo or {})
end;

function VFXManager:FireAll(Data: {any}, EffectInfo: {any})
	local MainEntity = self:GetClientEntity();
	Data.Caster = MainEntity;
	local MaxDistance = Data.MaxDistance or 500
	Data.MaxDistance = nil
	Data.ServerCall = true;
	assert(Data.EffectModule, debug.traceback('Need to Module!'));
	assert(Data.Func, debug.traceback('Function Name Needed'));
	
	for i, player in pairs(Server.CurrentPlayers) do
		if not player.Character then continue end;
		if not player.Character:FindFirstChild('HumanoidRootPart') then continue end;
		if (player.Character.HumanoidRootPart.Position - Data.Caster.Character.Root.Position).Magnitude > MaxDistance then continue end;

		Server.PacketLinks["VFXAll"]:FireClient(player, Data, EffectInfo or {})
	end
end;

function VFXManager:Destroy()
	
end;

return VFXManager;