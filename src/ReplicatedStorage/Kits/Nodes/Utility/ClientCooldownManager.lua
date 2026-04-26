--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local Timer = require(Nodes.Utility.Timer);
--//Module
local CooldownManager = {};
CooldownManager.__index = CooldownManager;

CooldownManager.new = function(Entity: Player)
	local self = setmetatable({
		
		Parent = Entity;
		OnCooldown = {};
		
	}, CooldownManager);
	
	return self;
end;

function CooldownManager:Add(SkillName: string, Duration: number?)
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
end;

function CooldownManager:Stop(SkillName: string)
	self.OnCooldown[SkillName] = nil;
end;

function CooldownManager:Destroy()
	
	
	
end;

return CooldownManager;