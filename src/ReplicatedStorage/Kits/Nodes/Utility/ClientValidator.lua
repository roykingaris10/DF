--//Variable
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');

local Kits = ReplicatedStorage.Kits
local Nodes: Folder = Kits.Nodes;

local Cooldowns = require(Nodes.Utility.ClientCooldownManager);

--//Module
local Validator = {};
Validator.DefaultConditions = {
	Stun = true;
	Cooldown = true;
	Ragdoll = true;
	Active = true;
	Blocking = true;
};

Validator.Checks = {
	Cooldown = function(Entity: {any}, SkillName: string)
		return Entity.Cooldowns.OnCooldown[SkillName];
	end;
	
	Ragdoll = function(Entity: {any})
		return Entity.Character:GetAttribute('Ragdolled');
	end;
	
	Stun = function(Entity: {any})
		return Entity.Character:GetAttribute('Stunned');
	end;
	
	Active = function(Entity: {any})
		return Entity.Character:GetAttribute('Active');
	end;
	
	Blocking = function(Entity: {any}, Skill: ModuleScript)
		return Entity.Character:GetAttribute('Blocking');
	end;
};

Validator.ParseConditions = function(Conditions: {any})
	if not Conditions then return end;
	local Parsed = table.clone(Validator.DefaultConditions);
	
	for i,v in Conditions do
		Parsed[i] = v;
	end;
	
	return Parsed;
end;

Validator.Validate = function(Entity: {any}, SkillName: string, Conditions: {any})
	if Entity.Character:GetAttribute('Dead') then
		warn('Can not use skills while character is dead!');
		return;
	end;
	
	local SkillConditions = Validator.ParseConditions(Conditions) or Validator.DefaultConditions;
	if SkillConditions.None then
		return true;
	end;
	
	for CheckName: string, Func: () -> () in Validator.Checks do
		local ConditionVal = SkillConditions[CheckName];
		if not ConditionVal then continue end;
		if Func(Entity, SkillName, ConditionVal) then return end;
	end;
	
	return true;
end;

return Validator;