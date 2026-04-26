 --//Variable
local Server = require(script.Parent)
local Network = Server.Network

local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');
local RunService = game:GetService("RunService")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local CooldownManager = {};
local SkillsFolder  = {}

--//Module

--//TODO - SETUP THE TIME SCALING AND PAUSE FEATURES
CooldownManager.__index = CooldownManager;

CooldownManager.new = function(Entity: {any})
	local self = setmetatable({
		
		Parent = Entity;
		cooldownData = {};
		
		timeScale  = 1;
		useScaledTime = false;
		
	}, CooldownManager);
	
	return self;
end;

function CooldownManager:Set(keyName: string, duration: number, callback: (...any) -> (...any)?) :boolean
	assert(keyName, "Missing keyName for a cooldown")
	assert(duration, "Missing duration for a ["..keyName.."] cooldown")
	assert(duration >= 0, "Duration cannot be negative for ["..keyName.."] cooldown")
	
	local now = os.clock()
	local expires = now + duration
	
--	local realDuration = self.useScaledTime and (duration / self.timeScale) or duration

	if not self.cooldownData then
		self.cooldownData = {}
	end
	
	if self.cooldownData[keyName] and self.cooldownData[keyName].cleanupTask then
		local success, result = pcall(function()
			task.cancel(self.cooldownData[keyName].cleanupTask)
		end)
	end

	self.cooldownData[keyName] = {
		Start = now,
		Duration = duration,
		expires = expires,
		Paused = false,
		PauseRemaining = nil,
		TimeScale = 1,
	}
	
	if duration > 0 then
		self.cooldownData[keyName].cleanupTask = task.spawn(function()
			task.wait(duration)
			if self.cooldownData and self.cooldownData[keyName] then
				self:Remove(keyName)
				if callback then
					callback()
				end
			end
		end)
	end
	
	--Sync(player, "Start", abilityName, self.PlayerData[player][abilityName])
--	Server.PacketLinks["SetCooldown"]:FireClient(self.Parent.player,keyName,duration)
	if self.Parent.player then
		Server.PacketLinks["DisplayCooldown"]:FireClient(self.Parent.player,keyName,duration)
	end
	
	--Send signal to Client
end

function CooldownManager:Add(keyName: string, duration: number)
	if not self.cooldownData[keyName]then
		return self:Set(keyName, duration)
	end
end

function CooldownManager:Check(keyName: string)
	if not self.cooldownData then
		return false
	end

	local entry = self.cooldownData[keyName]
	if entry then
		return true
	end

	return false
end

function CooldownManager:Remove(keyName: string)
	if self.cooldownData and self.cooldownData[keyName] then
		local cleanupTask = self.cooldownData[keyName].cleanupTask
		if cleanupTask then
			local success, result = pcall(function()
				task.cancel(cleanupTask)
			end)
		end
		self.cooldownData[keyName] = nil


		return true
	end
	return false
end
--[[
function CooldownManager:Remove(keyName: string)
	if not self:Check(keyName) then return end
	
	self.cooldownData[keyName] = nil
	
	if next(self.cooldownData) == nil then
		self.cooldownData = nil
	end

	return true
end
]]
function CooldownManager:Reset()

end

function CooldownManager:Pause()

end

function CooldownManager:Resume()

end

function CooldownManager:SetTimeScale()

end

function CooldownManager:AdjustDuration()

end

function CooldownManager:AdjustAllDurations()

end

function CooldownManager:ClearAll()
	if not self.cooldownData then
		return
	end

	-- Cancel all cleanup tasks
	for keyName, data in pairs(self.cooldownData) do
		if data.cleanupTask then
			task.cancel(data.cleanupTask)
		end
	end

	-- Clear all cooldown data
	self.cooldownData = {}
end

function CooldownManager:AddOld(SkillName: string, Duration: number?)
	local Prev = self.OnCooldown[SkillName];

	if Duration then
		local EndTime = os.clock()+Duration;
		self.OnCooldown[SkillName] = EndTime;
	else
		self.OnCooldown[SkillName] = true;
	end;

	local function CheckCondition()
		local CurrentValue = self.OnCooldown[SkillName];
		if typeof(CurrentValue) == 'number' then
			return os.clock() >= self.OnCooldown[SkillName];
		else
			return not self.OnCooldown[SkillName];
		end;
	end;

	task.spawn(function()
		if Prev then return end;
		repeat wait() until CheckCondition();
		self.OnCooldown[SkillName] = nil;
	end);

	if self.Parent.player and Duration then
		--	Network:post('Cooldown', {Skill=SkillName, Duration=Duration}, false, self.Parent.Player);
		--put bind event on client for cooldowns yuuh
	end;
end;

function CooldownManager:Stop(SkillName: string)
	self.OnCooldown[SkillName] = nil;
end;

function CooldownManager:Destroy()

end;

return CooldownManager;