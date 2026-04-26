return function(Server)

	local ProgressionFunctions = {}

	local Utilities = Server.Utilities
	local Network = Server.Network
	local Animations = Server.Animations
	local CharacterCustomizationInfo = Server.CharacterCustomizationInfo
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Debris = game:GetService("Debris")
	
	local Kits = ReplicatedStorage.Kits
	local RankToLevel = require(Kits.Nodes.InfoLibrary.RankToLevel)
	local RaceAccs = Kits.CustomizationAssets:WaitForChild("RaceAccessories")

	ProgressionFunctions["Combat"] = function(self,optionTable)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character
		
		if optionTable.Option == "Add" then
			Profile.XPInfo.Combat.Exp += optionTable.Value
			
			if Profile.XPInfo.Combat.Exp >= Profile.XPInfo.Combat.ExpToNextLevel then
				local Leftover = Profile.XPInfo.Combat.Exp - Profile.XPInfo.Combat.ExpToNextLevel
				Profile.XPInfo.Combat.Level += 1
				Profile.XPInfo.Combat.Exp = math.max(0,Leftover)
				Profile.XPInfo.Combat.ExpToNextLevel *= 1.3
			end
		end
	end
	--Options Set,Add,Return
	ProgressionFunctions["Stamina"] = function(self,optionTable)
		local Profile = self:RequestSlotProfile(self.player)
		local user = self.player.Character
		
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
	
	ProgressionFunctions["Health"] = function(self,optionTable)
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
	
	ProgressionFunctions["Will"] = function(self,optionTable)
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
	
	ProgressionFunctions["Hunger"] = function(self,optionTable)
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
	

	return ProgressionFunctions end
