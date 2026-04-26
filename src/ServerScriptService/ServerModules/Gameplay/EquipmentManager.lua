--//Variable
local Server = require(script.Parent)
local CharacterCustomizationInfo = Server.CharacterCustomizationInfo;
local OutfitInfo = Server.OutfitInfo
local ServerStorage = game:GetService('ServerStorage');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');
local HttpService = game:GetService("HttpService")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local RaceAccs = Kits.CustomizeAssets.RaceAccessories

local EquipmentManager = {};
EquipmentManager.__index = EquipmentManager;

EquipmentManager.new = function(Entity: {any})
	local self = setmetatable({
		
		Parent = Entity;
		SlotProfile = Entity.SlotProfile;
		Enabled = true;
		
		_Connections = {};
		_Cached = {};
		
	}, EquipmentManager);
	
	return self;
end;


function EquipmentManager:Execute()
	--[[
	setmetatable(self.Parent.Data.Inventory, {
		__newindex = function(_, index, value)
			print(tostring(index) .. " has been added and set to " .. tostring(value))
		end
	})
]]
end;

function EquipmentManager:SetupLooks()
	local character = self.Parent.Character.Rig
	local Humanoid = character:WaitForChild('Humanoid')
	
	local rbxPlayerInfo = Players:GetCharacterAppearanceInfoAsync(self.Parent.player.UserId)
	local accessoryTable = {}
	for i = 1, #rbxPlayerInfo.assets do
		if rbxPlayerInfo.assets[i].assetType.name == 'HairAccessory' then 
			table.insert(accessoryTable, game:GetService("InsertService"):LoadAsset(rbxPlayerInfo.assets[i].id))
		end
	end
	local ToneColor = Color3.new(self.SlotProfile.playerAppearance.ToneColor.R,self.SlotProfile.playerAppearance.ToneColor.G,self.SlotProfile.playerAppearance.ToneColor.B)
	local HairColor = Color3.new(self.SlotProfile.playerAppearance.HairColor.R,self.SlotProfile.playerAppearance.ToneColor.G,self.SlotProfile.playerAppearance.HairColor.B)
	for _, v in pairs(accessoryTable) do Humanoid:AddAccessory(v:FindFirstChildOfClass('Accessory')) end
	for _, v in pairs(character:GetChildren()) do
		if v:IsA('Part') then
			v.Color = ToneColor
			continue
		end
		if v:IsA('Accessory') then 
			if v.Handle:FindFirstChild('Mesh') then
				v.Handle.Mesh.TextureId = ''
				v.Handle.Massless = true
			elseif v.Handle:FindFirstChild('SpecialMesh') then
				v.Handle.SpecialMesh.TextureId = ''
				v.Handle.Massless = true
			end
			v.Handle.Color = HairColor
			continue	
		end
	end
	
	local Shirt = character.Shirt
	local Pants = character.Pants
	
	Shirt.ShirtTemplate = 'http://www.roblox.com/asset/?id=4646368924'
	Pants.PantsTemplate = OutfitInfo[self.SlotProfile.playerAppearance.Outfit].PantsID
	
	local RaceAccHolder = character.RaceAccHolder
	
	local RaceData = CharacterCustomizationInfo.Races[self.SlotProfile.UserData.Race]
	
	if self.SlotProfile.playerAppearance.RaceAcc > 0 then
		local RaceFolder = RaceAccs:FindFirstChild(RaceData.RaceName)
		if RaceFolder then
			local Accessory = RaceFolder:FindFirstChild(self.SlotProfile.playerAppearance.RaceAcc)
			if Accessory then
				local AccessoryClone = Accessory:Clone()
				AccessoryClone.Parent = RaceAccHolder
				for i,parts in pairs(AccessoryClone:GetChildren()) do
					if RaceData.RaceAccessories[self.SlotProfile.playerAppearance.RaceAcc][parts.Name] then
						local Weld = Instance.new("Weld")
						Weld.Parent = character:WaitForChild(parts:GetAttribute("Location"))
						Weld.Part0 = character:WaitForChild(parts:GetAttribute("Location"))
						Weld.Part1 = parts
						Weld.C0 = RaceData.RaceAccessories[self.SlotProfile.playerAppearance.RaceAcc][parts.Name]
					end
					if RaceData.RaceAccessories[self.SlotProfile.playerAppearance.RaceAcc].Tone == true then
						parts.Color = ToneColor
					end
				end
			end
		end
	end
	
	--Eye stuff to be changed later
	local EyeBackground = character.FakeHead:WaitForChild("EyeBackground")
	EyeBackground.Texture = 'http://www.roblox.com/asset/?id=9173927829'

	local EyePupils = character.FakeHead:WaitForChild("EyePupils")
	EyePupils.Texture = 'http://www.roblox.com/asset/?id=9173951430'
	EyePupils.Color3 = Color3.new(self.SlotProfile.playerAppearance.EyeColor.R, self.SlotProfile.playerAppearance.EyeColor.G, self.SlotProfile.playerAppearance.EyeColor.B)

	local Mouth = character.FakeHead:WaitForChild("Mouth")
	Mouth.Texture = 'http://www.roblox.com/asset/?id=9174371684'
	
--	self.Parent.SlotProfile.playerAppearance
end

function EquipmentManager:Destroy()
	for _,v:RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;
end;

return EquipmentManager;