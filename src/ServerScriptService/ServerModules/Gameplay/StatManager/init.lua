--//Variable
local Server = require(script.Parent)
local LibraryInfo = Server.LibraryInfo
local ServerStorage = game:GetService('ServerStorage');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CONFIG = require(script.Configs);

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local GameSettings = require(Nodes.Data.GameSettings)

local StatManager = {};
StatManager.__index = StatManager;

local function calculateExpToNextLevel(level)
	return math.floor(StatManager.Constants.BaseExp * (StatManager.Constants.ExpMultiplier ^ (level - 1)))
end

StatManager.new = function(Entity: {any})
	local self = setmetatable({

		Parent = Entity;	
		SlotProfile = Entity.SlotProfile;
		Health = Entity.SlotProfile.statInfo.Health or 100,
		Will = 100,
		Stamina = Entity.SlotProfile.statInfo.Stamina or 100,
		Posture = 0,
		Hunger = Entity.SlotProfile.statInfo.Hunger or 100,

		MaxHealth = 100,
		MaxWill = 100,
		MaxStamina = 100,
		MaxPosture = 100,
		MaxHunger = 100,
		
		LastFullHungerTick = 0,
		
		Movement = {
			Defaults = {
				WalkSpeed = 14,
				JumpPower = 50,
			},
			Absolute = {}, -- {source = {Values = {WalkSpeed?, JumpPower?, Priority?}, Expire = tick?}}
			Buffs = {},    -- {source = {Values = {WalkSpeedAdd?, WalkSpeedMult?, JumpAdd?, JumpMult?}, Expire = tick?}}
		},

		_Connections = {};
		_Cached = {};

	}, StatManager);

	return self;
end;

local CombatDataStates = {
	--[[
	Stunned = {
		Movement = {
			WalkSpeed = 0,
			JumpPower = 0,
			Priority = 100, -- High priority overrides everything
		},
	},]]
	CombatDisable = {
		BlockCombat = true, -- No movement changes, just flag for combat checks
	},
	NoJump = {
		Movement = {
			JumpPower = 0,
			Priority = 50,
		},
	},
	NoWalk = {
		Movement = {
			WalkSpeed = 0,
			Priority = 50,
		},
	},
	Rooted = {
		Movement = {
			WalkSpeed = 0,
			JumpPower = 0,
			Priority = 75,
		},
	},
	RollKnockback = {
		Movement = {
			WalkSpeed = 10,
			JumpPower = 0,
			Priority = 40,
		},
	},
	SlowWalk = {
		Movement = {
			WalkSpeedMult = 0.5, -- Buff-style (multiplicative)
		},
	},
}


function StatManager:Execute()

end;

function StatManager:ResourcesSetup()
	local player = self.Parent.player
	local character = self.Parent.Character.Rig
	local humanoid = self.Parent.Character.Humanoid
	if self.Hunger == self.MaxHunger then
		self.LastFullHungerTick = tick()
	end
	
	self:SetupCombatDataWatcher()
	
	self._Connections["StatConn"] = RunService.Heartbeat:Connect(function(dt)
		if not self.Parent.Character.Alive or not character or not humanoid then self._Connections["StatConn"]:Disconnect() return end
		-- COMBAT CHECK//
		local inCombat = (tick() - self.Parent.InCombatTick) < GameSettings.InCombatDuration

		-- HEALTH REGEN//
		local baseRegen = inCombat and CONFIG.Health.BaseRegenInCombat or CONFIG.Health.BaseRegenOutOfCombat

		local hungerPercent = self.Hunger / CONFIG.Hunger.Max
		local hungerPenalty = 1 - ((1 - hungerPercent) * CONFIG.Health.LowHungerPenalty)

		--	local gearRegenBonus = self.HealthRegenBonus or 0

		local finalRegen = baseRegen * hungerPenalty --+ gearRegenBonus

		self:ChangeHealth(self.Health + finalRegen * dt)


		-- WILL REGEN//
		local willRegen
		if inCombat then
			willRegen = CONFIG.Will.RegenCombat * dt
		else
			willRegen = CONFIG.Will.RegenOutCombat * dt
		end

		self:ChangeWill(willRegen)

		-- STAMINA REGEN//
		local staminaRegen = inCombat
			and CONFIG.Stamina.InCombat
			or CONFIG.Stamina.OutCombat
		self:ChangeStamina(staminaRegen * dt)
		
		-- HUNGER DECAY//
		local missingHP = (self.MaxHealth - self.Health) / self.MaxHealth
		local extraDecay = missingHP * CONFIG.Hunger.MissingHealthDecayMultiplier
		local decay = (CONFIG.Hunger.BaseDecay + extraDecay) * dt

		-- Detect reaching full
		if self.Hunger >= self.MaxHunger then
			if not self.WasFullHunger then
				self.LastFullHungerTick = tick()
				self.WasFullHunger = true
			end
		else
			-- Hunger dropped below max, reset the state
			self.WasFullHunger = false
		end

		-- Apply decay only after grace time has passed
		if self.WasFullHunger then
			if (tick() - self.LastFullHungerTick) >= CONFIG.Hunger.FullGraceTime then
				self:ChangeHunger(-decay)
			end
		else
			-- Normal decay when not full
			self:ChangeHunger(-decay)
 		end

		-- POSTURE DECAY//
		if (tick() - self.Parent.LastPostureHit) > CONFIG.Posture.DecayDelay then
			self:ChangePosture(self.Posture+(-CONFIG.Posture.DecayRate * dt))
		end
		
		self.Parent.Character:SetAttribute("TimeScale",self.Parent.RunTime.FinalTimeScale or 1)
		self.Parent.Character:SetAttribute("InCombatTick",self.Parent.InCombatTick)
		self:UpdateMovement()
	end)
end

function StatManager:ProcessCombatData()
	local combatData = self.Parent.Character.CombatData
	if not combatData then return end

	for stateName, stateConfig in pairs(CombatDataStates) do
		local folder = combatData:FindFirstChild(stateName)
		local isActive = folder ~= nil

		local sourceKey = "CombatData_" .. stateName

		if isActive then
			-- Apply movement changes if defined
			if stateConfig.Movement then
				local values = stateConfig.Movement
				local priority = values.Priority
				if values.WalkSpeed ~= nil or values.JumpPower ~= nil then
					-- Absolute override
					self:SetAbsolute(sourceKey, {
						WalkSpeed = values.WalkSpeed,
						JumpPower = values.JumpPower,
						Priority = priority or 0,
					})
				else
					-- Buff/debuff (multiplicative or additive)
					self:AddBuff(sourceKey, {
						WalkSpeedAdd = values.WalkSpeedAdd,
						WalkSpeedMult = values.WalkSpeedMult,
						JumpAdd = values.JumpAdd,
						JumpMult = values.JumpMult,
					})
				end
			end
		else
			-- State no longer active, remove it
			self:RemoveAbsolute(sourceKey)
			self:RemoveBuff(sourceKey)
		end
	end
end

function StatManager:SetupCombatDataWatcher()
	local combatData = self.Parent.Character.CombatData
	if not combatData then return end

	self._Connections["CombatDataAdded"] = combatData.ChildAdded:Connect(function(child)
		self:ProcessCombatData()
	end)

	self._Connections["CombatDataRemoved"] = combatData.ChildRemoved:Connect(function(child)
		self:ProcessCombatData()
	end)

	self:ProcessCombatData()
end

function StatManager:UpdateMovement()
	local now = tick();
	local needsRecalc = false;

	-- Clear expired absolutes
	for source, entry in pairs(self.Movement.Absolute) do
		if entry.Expire and now >= entry.Expire then
			self.Movement.Absolute[source] = nil;
			needsRecalc = true;
		end;
	end;

	-- Clear expired buffs
	for source, entry in pairs(self.Movement.Buffs) do
		if entry.Expire and now >= entry.Expire then
			self.Movement.Buffs[source] = nil;
			needsRecalc = true;
		end;
	end;

	if needsRecalc then
		self:RecalculateMovement();
	end;
end;

function StatManager:RecalculateMovement()
	local character = self.Parent.Character.Rig;
	if not character then return end;

	local final = {
		WalkSpeed = self.Movement.Defaults.WalkSpeed,
		JumpPower = self.Movement.Defaults.JumpPower,
	};

	--Check absolutes by priority
	local topPriority = -math.huge;
	local winningAbsolute = nil;

	for source, entry in pairs(self.Movement.Absolute) do
		local abs = entry.Values;
		local priority = abs.Priority or 0;
		if priority >= topPriority then
			topPriority = priority;
			winningAbsolute = abs;
		end;
	end;

	if winningAbsolute then
		if winningAbsolute.WalkSpeed ~= nil then
			final.WalkSpeed = winningAbsolute.WalkSpeed*self.Parent.RunTime.FinalTimeScale or 1;
		end;
		if winningAbsolute.JumpPower ~= nil then
			final.JumpPower = winningAbsolute.JumpPower;
		end;
	else
		--Apply buffs/debuffs
		local walk = self.Movement.Defaults.WalkSpeed;
		local jump = self.Movement.Defaults.JumpPower;

		for source, entry in pairs(self.Movement.Buffs) do
			local buff = entry.Values;
			if buff.WalkSpeedAdd then
				walk = walk + buff.WalkSpeedAdd;
			end;
			if buff.WalkSpeedMult then
				walk = walk * buff.WalkSpeedMult;
			end;
			if buff.JumpAdd then
				jump = jump + buff.JumpAdd;
			end;
			if buff.JumpMult then
				jump = jump * buff.JumpMult;
			end;
		end;

		final.WalkSpeed = walk*self.Parent.RunTime.FinalTimeScale or 1;
		final.JumpPower = jump;
	end;

	character:SetAttribute("WalkSpeed", final.WalkSpeed);
	character:SetAttribute("JumpPower", final.JumpPower);

	-- For NPCs, apply directly to humanoid
	if not self.Parent.player then
		local humanoid = self.Parent.Character.Humanoid;
		if humanoid then
			humanoid.WalkSpeed = final.WalkSpeed;
			humanoid.JumpPower = final.JumpPower;
		end;
	end;
end;

function StatManager:SetAbsolute(source, values, duration)
	local expireTime = duration and (tick() + duration) or nil;
	self.Movement.Absolute[source] = {Values = values, Expire = expireTime};
	self:RecalculateMovement();
end;

function StatManager:RemoveAbsolute(source)
	self.Movement.Absolute[source] = nil;
	self:RecalculateMovement();
end;

-- Add buff/debuff (stacks additively/multiplicatively)
-- values = {WalkSpeedAdd = number?, WalkSpeedMult = number?, JumpAdd = number?, JumpMult = number?}
function StatManager:AddBuff(source, values, duration)
	local expireTime = duration and (tick() + duration) or nil;
	self.Movement.Buffs[source] = {Values = values, Expire = expireTime};
	self:RecalculateMovement();
end;

function StatManager:RemoveBuff(source)
	self.Movement.Buffs[source] = nil;
	self:RecalculateMovement();
end;

function StatManager:ChangeHealth(amount, NoDeath: boolean?)
	if not self.Parent.Character.Alive then return end;
	
	self.Health = amount
	self.Health = math.clamp(self.Health, 0, self.MaxHealth)
	self.Parent.Character.Humanoid.Health = self.Health;
	self.Parent.Character.Rig:SetAttribute("Health",self.Health)
	
	if not NoDeath and self.Health <= 0 then
		self.Parent.Character:OnDeath();
	end;
end

function StatManager:ChangeStamina(amount)
	if not self.Parent.Character.Alive then return end;
	self.Stamina += amount
	self.Stamina = math.clamp(self.Stamina, 0, self.MaxStamina)
	self.Parent.Character.Rig:SetAttribute("Stamina",self.Stamina)
end

function StatManager:ChangeWill(amount)
	self.Will += amount
	self.Will = math.clamp(self.Will, 0, self.MaxWill)
	self.Parent.Character.Rig:SetAttribute("Will",self.Will)
end

function StatManager:ChangePosture(amount)
	if not self.Parent.Character.Alive then return end;
	self.Posture = amount
	self.Posture = math.clamp(self.Posture, 0, self.MaxPosture)
	self.Parent.Character.Rig:SetAttribute("Posture",self.Posture)
end

function StatManager:ChangeHunger(amount)
	self.Hunger += amount
	self.Hunger = math.clamp(self.Hunger, 0, self.MaxHunger)
	self.Parent.Character.Rig:SetAttribute("Hunger",self.Hunger)
end

function StatManager:PlayerSetup()
	local StatFolder = Instance.new("Folder")
	StatFolder.Name = "StatFolder"
	StatFolder.Parent = self.Parent.player

	local foldertable = {"Settings","User","Statistics"}
	for i = 1,#foldertable do
		local sectionFolder = Instance.new("Folder")
		sectionFolder.Name = foldertable[i].."Folder"
		sectionFolder.Parent = StatFolder
	end

	local QuestFolder = Instance.new("Folder")
	QuestFolder.Name = "QuestFolder"
	QuestFolder.Parent = self.Parent.player

	for i = 1,4 do
		local questsection = Instance.new("Folder")
		questsection.Name = i
		questsection.Parent = QuestFolder
	end

	self:SetupSettingsAttr()
	self:SetupStatisticsAttr()
	self:SetupPlayerAttr()
	self:SetupInnerDialogue()
end

function StatManager:SetupInnerDialogue()
	if self.SlotProfile.HasSeenInnerDialogue then return end
	local dreamTrait = self.SlotProfile.UserData.DreamTrait
	if not dreamTrait then return end

	local ok, InnerDialogue = pcall(function()
		return require(game:GetService("ReplicatedStorage").Kits.InnerDialogue)
	end)
	if not ok or not InnerDialogue then return end

	local text = InnerDialogue:Get(dreamTrait)
	if not text then return end

	self.Parent.player:SetAttribute("PendingInnerDialogue", text)
end

function StatManager:SetupSettingsAttr()
	local SettingsFolder = self.Parent.player.StatFolder.SettingsFolder
	SettingsFolder:SetAttribute("MusicVolume",self.Parent.Data.Settings.MusicVolume)
	SettingsFolder:SetAttribute("ScreenShake",self.Parent.Data.Settings.ScreenShake)
	SettingsFolder:SetAttribute("ShadowsEnabled",self.Parent.Data.Settings.ShadowsEnabled)
end

function StatManager:SetupStatisticsAttr()
	--//General

	for name, val in pairs(self.SlotProfile.summaryInfo) do
		self.Parent.player.StatFolder.StatisticsFolder:SetAttribute(name,val)
	end
end

function StatManager:SetupPlayerAttr()
	local UserFolder = self.Parent.player.StatFolder.UserFolder
	
	if self.SlotProfile.UserData.WillColor == nil then
		local rng = Random.new(os.clock() * 1e9 + tick() * 1e6)
		local h = rng:NextNumber(0, 1)
		local s = rng:NextNumber(0.55, 1)
		local v = rng:NextNumber(0.7, 1)
		local randomColor = Color3.fromHSV(h, s, v)
		self.SlotProfile.UserData.WillColor = {randomColor.R, randomColor.G, randomColor.B}
	end

	local wc = self.SlotProfile.UserData.WillColor
	local willColor = Color3.new(wc[1], wc[2], wc[3])
	self.Parent.player:SetAttribute("WillColor", willColor)
	
	UserFolder:SetAttribute("Level",self.SlotProfile.UserData.Level)
	UserFolder:SetAttribute("Faction",self.SlotProfile.UserData.Faction)
	UserFolder:SetAttribute("EXP",self.SlotProfile.UserData.EXP)
	UserFolder:SetAttribute("EXPTONEXT",self.SlotProfile.UserData.EXPTONEXT)
	UserFolder:SetAttribute("Beli",self.SlotProfile.UserData.Beli)
	UserFolder:SetAttribute("Crew",self.SlotProfile.UserData.Crew)
	UserFolder:SetAttribute("FirstName",self.SlotProfile.UserData.FirstName)
	UserFolder:SetAttribute("MiddleName",self.SlotProfile.UserData.MiddleName)
	UserFolder:SetAttribute("LastName",self.SlotProfile.UserData.LastName)
	UserFolder:SetAttribute("Bounty",self.SlotProfile.UserData.Bounty)
	UserFolder:SetAttribute("FactionRank",self.SlotProfile.UserData.FactionRank)
	UserFolder:SetAttribute("Race",self.SlotProfile.UserData.Race)
	UserFolder:SetAttribute("DreamTrait",self.SlotProfile.UserData.DreamTrait)
	UserFolder:SetAttribute("StatPoints",self.SlotProfile.statInfo.StatPoints)
	UserFolder:SetAttribute("SkillPoints",self.SlotProfile.statInfo.SkillPoints)
	for name, val in pairs(self.SlotProfile.statInfo.StatValues) do
		UserFolder:SetAttribute(name,val)
	end
end

function StatManager:SetupUserAttr()
	local CharacterRig = self.Parent.Character.Rig
	CharacterRig:SetAttribute("Health",self.Health)
	CharacterRig:SetAttribute("Stamina",self.Stamina)
	CharacterRig:SetAttribute("Hunger",self.Hunger)
	CharacterRig:SetAttribute("Will",self.Will)
	CharacterRig:SetAttribute("Posture",self.Posture)
	CharacterRig:SetAttribute("InCombatTick",self.Parent.InCombatTick)
end

function StatManager:CalculateStats()
	local CharacterRig = self.Parent.Character.Rig
	CharacterRig:SetAttribute("MaxHealth",self.MaxHealth)
	CharacterRig:SetAttribute("MaxStamina",self.MaxStamina)
	CharacterRig:SetAttribute("MaxHunger",self.MaxHunger)
	CharacterRig:SetAttribute("MaxWill",self.MaxWill)
	CharacterRig:SetAttribute("MaxPosture",self.MaxPosture)
end

function StatManager:Destroy()
	for _,v:RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;
end;

return StatManager;