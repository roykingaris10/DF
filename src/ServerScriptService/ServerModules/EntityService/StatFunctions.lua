return function(Server)

	local StatFunctions = {}

	local Utilities = Server.Utilities
	local Network = Server.Network
	local Animations = Server.Animations
	local CharacterCustomizationInfo = Server.CharacterCustomizationInfo
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Debris = game:GetService("Debris")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	local RankToLevel = require(Nodes.InfoLibrary.RankToLevel)

	local RaceAccs = Kits.CustomizationAssets:WaitForChild("RaceAccessories")

	local EffectsFolder = workspace.EffectsFolder	

	StatFunctions["AttributeSetup"] = function(self)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character	
		
		self.player:SetAttribute("firstName",Profile.UserData.firstName)
		self.player:SetAttribute("middleName",Profile.UserData.middleName)
		self.player:SetAttribute("lastName",Profile.UserData.lastName)
		self.player:SetAttribute("Beli", Profile.UserData.Beli)
		self.player:SetAttribute("Level", Profile.UserData.Level)
		self.player:SetAttribute("Race", Profile.UserData.Race)
		self.player:SetAttribute("Faction", Profile.UserData.Faction)
		self.player:SetAttribute("Crew",Profile.UserData.Crew)
		self.player:SetAttribute("FactionRank",Profile.UserData.FactionRank)
		self.player:SetAttribute("Health", 1)
		self.player:SetAttribute("Stamina", Profile.statInfo.StaminaInfo.Stamina/Profile.statInfo.StaminaInfo.MaxStamina)
		self.player:SetAttribute("Energy", Profile.statInfo.EnergyInfo.Energy/Profile.statInfo.EnergyInfo.MaxEnergy)
		self.player:SetAttribute("Will", Profile.statInfo.WillInfo.Will/Profile.statInfo.WillInfo.MaxWill)
	--	self.player:SetAttribute("WillColor", willColor)
	--	self.player:SetAttribute("Hunger",self.playerInfo.Hunger/100)
		self.player:SetAttribute("Bounty",Profile.UserData.Bounty)
		self.player:SetAttribute("Str",Profile.statInfo.Strength)
		self.player:SetAttribute("Vit",Profile.statInfo.Vitality)
		self.player:SetAttribute("Dex",Profile.statInfo.Dexterity)
		self.player:SetAttribute("Cgn",Profile.statInfo.Cognition)
		self.player:SetAttribute("Wil",Profile.statInfo.Will)
		self.player:SetAttribute("Hak",Profile.statInfo.Haki)
		self.player:SetAttribute("StatPoints",Profile.statInfo.StatPoints)
		
		if Profile.UserData.middleName == nil then
			self.player:SetAttribute("CharacterName", Profile.UserData.firstName .. ' ' .. Profile.UserData.lastName)
		else
			self.player:SetAttribute("CharacterName", Profile.UserData.firstName .. ' ' .. Profile.UserData.middleName .. ' ' ..Profile.UserData.lastName)
		end
		

	end
	--Options Set,Add,Return
	StatFunctions["Stamina"] = function(self,optionTable)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character
		
		local bruh2 = optionTable.Option
		local bruh3 = optionTable.Value
		
		if optionTable.Option == "Set" then
			Profile.statInfo.StaminaInfo.Stamina = math.max(optionTable.Value, 0)
			self.player:SetAttribute('Stamina', Profile.statInfo.StaminaInfo.Stamina/Profile.statInfo.StaminaInfo.MaxStamina)
		elseif optionTable.Option == "Add" then
			local addValue = math.max(Profile.statInfo.StaminaInfo.Stamina+optionTable.Value,0)
			addValue = math.clamp(addValue,0,Profile.statInfo.StaminaInfo.MaxStamina)
			Profile.statInfo.StaminaInfo.Stamina = addValue
			self.player:SetAttribute('Stamina', Profile.statInfo.StaminaInfo.Stamina/Profile.statInfo.StaminaInfo.MaxStamina)
		elseif optionTable.Option == "Return" then
			return Profile.statInfo.StaminaInfo.Stamina
		end
	end
	
	StatFunctions["Health"] = function(self,optionTable)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character

		local bruh2 = optionTable.Option
		local bruh3 = optionTable.Value

		if optionTable.Option == "Set" then
			Profile.statInfo.HealthInfo.Health = math.max(optionTable.Value, 0)
			self.player.Character.Humanoid.Health = Profile.statInfo.HealthInfo.Health
			self.player:SetAttribute('Health', Profile.statInfo.HealthInfo.Health/Profile.statInfo.HealthInfo.MaxHealth)
		elseif optionTable.Option == "Add" then
			local addValue = math.max(Profile.statInfo.HealthInfo.Health+optionTable.Value,0)
			addValue = math.clamp(addValue,0,Profile.statInfo.HealthInfo.MaxHealth)
			Profile.statInfo.HealthInfo.Health = addValue
			self.player.Character.Humanoid.Health = Profile.statInfo.HealthInfo.Health
			self.player:SetAttribute('Health', Profile.statInfo.HealthInfo.Health/Profile.statInfo.HealthInfo.MaxHealth)
		elseif optionTable.Option == "Return" then
			return Profile.statInfo.HealthInfo.Health
		end
	end
	
	StatFunctions["Will"] = function(self,optionTable)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character

		local bruh2 = optionTable.Option
		local bruh3 = optionTable.Value

		if optionTable.Option == "Set" then
			Profile.statInfo.WillInfo.Will = math.max(optionTable.Value, 0)
			Profile.statInfo.WillInfo.Will = math.clamp(Profile.statInfo.WillInfo.Will,0,Profile.statInfo.WillInfo.MaxWill)
			self.player:SetAttribute('Will', Profile.statInfo.WillInfo.Will/Profile.statInfo.WillInfo.MaxWill)
			self.player:SetAttribute('WillValue', Profile.statInfo.WillInfo.Will)
		elseif optionTable.Option == "Add" then
			local addValue = math.max(Profile.statInfo.WillInfo.Will+optionTable.Value,0)
			Profile.statInfo.WillInfo.Will = addValue
			Profile.statInfo.WillInfo.Will = math.clamp(addValue,0,Profile.statInfo.WillInfo.MaxWill)
			self.player:SetAttribute('Will', Profile.statInfo.WillInfo.Will/Profile.statInfo.WillInfo.MaxWill)
			self.player:SetAttribute('WillValue', Profile.statInfo.WillInfo.Will)
		elseif optionTable.Option == "Return" then
			return Profile.statInfo.WillInfo.Will
		end
	end
	
	StatFunctions["Hunger"] = function(self,optionTable)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character

		local bruh2 = optionTable.Option
		local bruh3 = optionTable.Value

		if optionTable.Option == "Set" then
			Profile.UserData.Hunger = math.max(optionTable.Value, 0)
			Profile.UserData.Hunger = math.clamp(Profile.UserData.Hunger,0,100)
			self.player:SetAttribute('Hunger',  Profile.UserData.Hunger/100)
		elseif optionTable.Option == "Add" then
			local addValue = math.max(Profile.UserData.Hunger+optionTable.Value,0)
			Profile.UserData.Hunger = math.clamp(addValue,0,100)
			self.player:SetAttribute('Hunger', Profile.UserData.Hunger/100)
		elseif optionTable.Option == "Return" then
			return Profile.UserData.Hunger
		end
	end
	
	StatFunctions["Level"] = function(self,optionTable)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character

		local bruh2 = optionTable.Option
		local bruh3 = optionTable.Value

		if optionTable.Option == "Set" then
			Profile.UserData.Level = math.max(optionTable.Value, 0)
			Profile.UserData.Level = math.clamp(Profile.UserData.Level,0,100)
			self.player:SetAttribute('Level', Profile.UserData.Level)
		elseif optionTable.Option == "Add" then
			local addValue = math.max(Profile.UserData.Level+optionTable.Value,0)
			Profile.UserData.Level = addValue
			self.player:SetAttribute('Level', Profile.UserData.Level)
		elseif optionTable.Option == "Return" then
			return Profile.UserData.Level
		end
	end
	
	StatFunctions["Beli"] = function(self,optionTable)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character

		local bruh2 = optionTable.Option
		local bruh3 = optionTable.Value

		if optionTable.Option == "Set" then
			Profile.UserData.Beli = math.max(optionTable.Value, 0)
			Profile.UserData.Beli = math.clamp(Profile.UserData.Beli, 0)
			self.player:SetAttribute('Beli', Profile.UserData.Beli)
		elseif optionTable.Option == "Add" then
			local addValue = math.max(Profile.UserData.Beli+optionTable.Value,0)
			Profile.UserData.Beli = addValue
			self.player:SetAttribute('Beli', Profile.UserData.Beli)
		elseif optionTable.Option == "Return" then
			return Profile.UserData.Beli
		end
	end
	
	StatFunctions["GroundState"] = function(self,state)
		local user = self.player.Character
		local CombatData = user:FindFirstChild("CombatData")
		if CombatData then
			local onGround = CombatData:FindFirstChild("OnGround")
			if onGround then
				 self.player.Character.CombatData.OnGround.Value = state
			end
		end
	end
	
	StatFunctions["Faction"] = function(self,Value)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character
		
		
		if Value == "Pirate" then
			Profile.UserData.Faction = "Pirate"
		elseif Value == "Marine" then
			Profile.UserData.Faction = "Marine"
		elseif Value == "Revolutionary" then
			Profile.UserData.Faction = "Revolutionary"
		elseif Value == "Civilian" then
			Profile.UserData.Faction = "Civilian"
		end
		self.player:SetAttribute('Faction', Profile.UserData.Faction)
		return Profile.UserData.Faction
	end
	
	StatFunctions["StatGet"] = function(self,optionTable)
		
	end

	return StatFunctions end
