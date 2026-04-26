return function(Server)
	local Network = Server.Network
	local Utilities = Server.Utilities
	local LibraryInfo = Server.LibraryInfo
	local ServerScriptService = game:GetService('ServerScriptService');
	local ReplicatedStorage = game:GetService("ReplicatedStorage");
	local Players = game:GetService('Players');

	local Entities = workspace.Entities


	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

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
		Cooldown = function(Entity: {any}, Skill: string)
			return Entity.Cooldowns.cooldownData[Skill];
		end;
		
		CombatDisable = function(Entity: {any}, Skill: string)
			return Entity.Character.CombatData:FindFirstChild("CombatDisable");
		end;

		Ragdoll = function(Entity: {any}, Skill: string)
			return Entity.Character.Ragdolled;
		end;

		Stun = function(Entity: {any}, Skill: string)
			return Entity.Character.Stunned;
		end;
		
		WillProc = function(Entity: {any}, Skill: string)
			return Entity.Character.WillProc;
		end;

		Active = function(Entity: {any}, Skill: string)
			return Entity.Character.Active;
		end;

		Awakened = function(Entity: {any}, Skill: string)
			return not Entity.Character.Awakened;
		end;

		Blocking = function(Entity: {any}, Skill: string)
			return Entity.Server.Blocking;
		end;
		
		Parrying = function(Entity: {any}, Skill: string)
			return Entity.Server.Parrying;
		end;
		
		AttackBuffer = function(Entity: {any}, Skill: string)
			return Entity.Character:GetAttribute("AttackBuffer");
		end;
		
		AerialBuffer = function(Entity: {any}, Skill: string)
			return Entity.Character:GetAttribute("AerialBuffer");
		end;

		Dashing = function(Entity: {any}, Skill: string)
			return Entity.Character:GetAttribute("Dashing");
		end;
		
		BlockBuffer = function(Entity: {any}, Skill: string)
			return Entity.Character:GetAttribute("BlockBuffer");
		end;
	};

	Validator.ParseConditions = function(Conditions: Configuration?)
		if not Conditions then return end;
		local Parsed = table.clone(Validator.DefaultConditions);

		for _,v: ValueBase in Conditions:GetChildren() do
			Parsed[v.Name] = v.Value;
		end;

		return Parsed;
	end;

	Validator.Validate = function(Entity: {any}, Skill: ModuleScript, CustomConditions: {any})
		if not Entity.Character.Alive then return end;

		local SkillConditions = CustomConditions or Validator.ParseConditions(Skill:FindFirstChild('Conditions')) or Validator.DefaultConditions;
		if SkillConditions.None then
			return true;	
		end;

		for CheckName: string, Func: () -> () in Validator.Checks do
			local ConditionVal = SkillConditions[CheckName];
			if not ConditionVal then continue end;
			if Func(Entity, Skill, ConditionVal) then return end;
		end;
		return true;
	end;

	Validator.Check = function(Entity: {any},Skill: string, CheckTable: {any})
		if not Entity.Character.Alive then return end;
		
		
		for i,value in pairs(CheckTable) do
	--		if not Validator.Checks[value] then  warn("missing validator check: "..value) continue end
			if Entity.Character.CombatData:FindFirstChild(value) then return end
			if Validator.Checks[value] then
				if Validator.Checks[value](Entity,Skill) then return end
			end
		end
		return true;
	end;

	return Validator; end