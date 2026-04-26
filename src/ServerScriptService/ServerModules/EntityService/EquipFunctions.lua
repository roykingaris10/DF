return function(Server)

	local EquipFunctions = {}

	local Utilities = Server.Utilities
	local Network = Server.Network
	local Animations = Server.Animations
	local CharacterCustomizationInfo = Server.CharacterCustomizationInfo

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Debris = game:GetService("Debris")
	local HttpService = game:GetService("HttpService")

	local Kits = ReplicatedStorage.Kits
	local RaceAccs = Kits.CustomizationAssets:WaitForChild("RaceAccessories")

	EquipFunctions["LooksSetup"] = function(self, state)
		local Profile = self:RequestSlotProfile(self.player)
		local character = self.player.Character
		local Humanoid = character:WaitForChild('Humanoid')
		
		local rbxPlayerInfo = game:GetService('Players'):GetCharacterAppearanceInfoAsync(self.player.UserId)
		local accessoryTable = {}
		for i = 1, #rbxPlayerInfo.assets do
			if rbxPlayerInfo.assets[i].assetType.name == 'HairAccessory' then 
				table.insert(accessoryTable, game:GetService("InsertService"):LoadAsset(rbxPlayerInfo.assets[i].id))
			end
		end
		for _, v in pairs(accessoryTable) do Humanoid:AddAccessory(v:FindFirstChildOfClass('Accessory')) end
		for _, v in pairs(character:GetChildren()) do
			if v:IsA('Part') then
				v.Color = Color3.new(Profile.playerAppearance.ToneColor.R, Profile.playerAppearance.ToneColor.G, Profile.playerAppearance.ToneColor.B)
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
				v.Handle.Color = Color3.new(Profile.playerAppearance.HairColor.R, Profile.playerAppearance.HairColor.G, Profile.playerAppearance.HairColor.B)
				continue	
			end
		end
	end

	EquipFunctions["RaceSetup"] = function(self, state)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.NPC or self.player.Character
		local RaceAccHolder = user.RaceAccHolder

		local RaceData = CharacterCustomizationInfo.Races["Race"..Profile.UserData.Race]
		
		if Profile.playerAppearance.RaceAcc > 0 then
			if RaceAccs:FindFirstChild(RaceData.RaceName) then
				local RaceFolder = RaceAccs[RaceData.RaceName]
				local Accessory = RaceFolder:FindFirstChild(Profile.playerAppearance.RaceAcc)
				if Accessory then
					local AccessoryClone = Accessory:Clone()
					AccessoryClone.Parent = RaceAccHolder
					for i,parts in pairs(AccessoryClone:GetChildren()) do
						if RaceData.RaceAccessories["Acc"..Profile.playerAppearance.RaceAcc][parts.Name] then
							local Weld = Instance.new("Weld")
							Weld.Parent = user:WaitForChild(parts:GetAttribute("Location"))
							Weld.Part0 = user:WaitForChild(parts:GetAttribute("Location"))
							Weld.Part1 = parts
							Weld.C0 = RaceData.RaceAccessories["Acc"..Profile.playerAppearance.RaceAcc][parts.Name]
						end
						if RaceData.RaceAccessories["Acc"..Profile.playerAppearance.RaceAcc].Tone == true then
							parts.Color = Color3.new(Profile.playerAppearance.ToneColor.R, Profile.playerAppearance.ToneColor.G, Profile.playerAppearance.ToneColor.B)
						end
					end
				end
			end
		end
		
		local EyeBackground = user.FakeHead:WaitForChild("EyeBackground")
		EyeBackground.Texture = RaceData.RaceEyes['Eyes'..Profile.playerAppearance.Eyes].EyeBackground

		local EyePupils = user.FakeHead:WaitForChild("EyePupils")
		EyePupils.Texture = RaceData.RaceEyes['Eyes'..Profile.playerAppearance.Eyes].EyePupils
		EyePupils.Color3 = Color3.new(Profile.playerAppearance.EyeColor.R, Profile.playerAppearance.EyeColor.G, Profile.playerAppearance.EyeColor.B)

		local Mouth = user.FakeHead:WaitForChild("Mouth")
		Mouth.Texture = RaceData.RaceMouth[Profile.playerAppearance.Mouth]
	end
	
	EquipFunctions["AbilityPack"] = function(self, state)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.NPC or self.player.Character
		
		local AbilityTable = {"Ground Slam", "Blitz Kick", "Pierce Dive","Broly Boost"}

		for i,ability in pairs(AbilityTable) do
			if not Profile.SkillInventory[ability] then
				Profile.SkillInventory[ability] = {
					["Name"] = ability,
					["Mastery"] = 0,
					["ToolbarSlot"] = 0,
				}
			end
		end
		
	end
	
	EquipFunctions["StarterPack"] = function(self, state)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.NPC or self.player.Character
		
		if not table.find(Profile.packs,"StarterPack") then
			Profile.equipped.Weapon["2"] = {
				["Name"] = "Melee",
				["Type"] = "Weapon",
				["Grade"] = "Novice",
				["Prestige"] = 0,
				["Enchant"] = "None",
				["Damage"] = 10,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Cutlass",
				["Type"] = "Weapon",
				["Grade"] = "Novice",
				["Prestige"] = 0,
				["Enchant"] = "None",
				["Damage"] = 10,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Flintlock",
				["Type"] = "Weapon",
				["Grade"] = "Novice",
				["Prestige"] = 0,
				["Enchant"] = "None",
				["Damage"] = 10,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Watermelon",
				["Type"] = "Food",
				["Amount"] = 5,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Sniper King's Cape",
				["Type"] = "Equipment",
				["Grade"] = "Adept",
				["Prestige"] = 1,
				["Enchant"] = "None",
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Garp's Dog Hat",
				["Type"] = "Equipment",
				["Grade"] = "Supreme",
				["Prestige"] = 2,
				["Enchant"] = "None",
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Shovel",
				["Type"] = "Utility",
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Franky's Bolt",
				["Type"] = "Quest Item",
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Ruby",
				["Type"] = "Material",
				["Amount"] = 2,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Sapphire",
				["Type"] = "Material",
				["Amount"] = 10,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Emerald",
				["Type"] = "Material",
				["Amount"] = 4,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Gold Bar",
				["Type"] = "Material",
				["Amount"] = 6,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Stick",
				["Type"] = "Material",
				["Amount"] = 63,
				["ToolbarSlot"] = 0,
			}
			Profile.Inventory[HttpService:GenerateGUID(false)] = {
				["Name"] = "Apple",
				["Type"] = "Food",
				["Amount"] = 8,
				["ToolbarSlot"] = 0,
			}
			table.insert(Profile.packs,"StarterPack")
		end
	end


	return EquipFunctions end
