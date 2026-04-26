local Server = require(script.Parent)

local Network = Server.Network
local Utilities = Server.Utilities
local CharacterCustomizationInfo = Server.CharacterCustomizationInfo
local LibraryInfo = Server.LibraryInfo
local Settings = Server.Settings
local QuestInfo = Server.QuestInfo

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local ProfileService = require(game.ServerScriptService.ProfileService)
local ProfileTemplate = require(script.ProfileTemplate)
local GameSettings = require(Nodes.Data.GameSettings)

local Entities = workspace.Entities

local DataProfile = {}
DataProfile.__index = DataProfile;

local ProfileStoreName = "DatastoreDF200"

DataProfile.ProfileTemplate = ProfileTemplate
DataProfile.SessionProfiles = {};
DataProfile.ProfileStore = ProfileService.GetProfileStore(ProfileStoreName, ProfileTemplate);

DataProfile.new = function(Player: Player)	
	local self = setmetatable({}, DataProfile);
	
	
	self.player = Player;

	self.Profile = DataProfile.ProfileStore:LoadProfileAsync(`Player_{tostring(Player.UserId)}`);
	if not self.Profile then 
		self.player:Kick('Could not fetch profile');
		return;
	end;
	
	if self.Profile then
		self.Profile:AddUserId(Player.UserId);
		self.Profile:Reconcile();

		self.Profile:ListenToRelease(function()
			self.SessionProfiles[self.player] = nil;
			self.player:Kick();
		end)
		
		if not self.player:IsDescendantOf(Players) then 
			self.Profile:Release()
		else
			self.SessionProfiles[self.player] = self;
			self.Data = self.Profile.Data;
		end
	end
	
	assert(self.player:IsDescendantOf(Players), 'Player left, profile was not returned');
	return self;
end;

function DataProfile:StarterPack()
	if not self.Data.packs["StarterPack"] then
		self.Data.packs["StarterPack"] = true
		self.Parent.InventoryManager:GiveItem("Watermelon", {Amount = 3})
		self.Parent.InventoryManager:GiveItem("Franky's Bolt", {})
	end
end

function DataProfile:Clean()
	DataProfile.SessionProfiles[self.player] = nil;
	self.Profile:Release();
	self.player:Kick('Profile cleaning');
end;

return DataProfile

