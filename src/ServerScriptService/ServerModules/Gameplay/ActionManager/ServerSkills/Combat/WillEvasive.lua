return function(Server)

	local Utilities = Server.Utilities
	local Network = Server.Network
	local LibraryInfo = Server.LibraryInfo

	local Debris = game:GetService("Debris")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local GameSettings = require(Nodes.Data.GameSettings);
	local Maid = require(Nodes.Utility.Maid)

	local Action = {}
	Action.__index = Action
	
	Action.Constants = {EvasiveTime = 0.2,Cooldown = 1}

	function Action.new(Entity)
		local self = setmetatable({}, Action)
		self.Entity = Entity
		self.Maid = Maid.new()
		self.Checks = {"Active","Ragdoll","Stunned","Dashing","Cooldown",}
		self.Character = Entity.Character
		return self
	end

	function Action:Start(Args)
		local Held = Args.Held
		if not Held then return end;
		if not self.Character:GetAttribute("Blocking") then return end
		if not self.Entity.ActionManager.Validator.Check(self.Entity,"Parry",self.Checks) then return end
		self.Entity.Character:SetWillProc(false);
		
		local Anim = self.Entity.Animator:Fetch(`General/WillEvasive`);
		Anim.Priority = Enum.AnimationPriority.Action
		Anim:SetAttribute("Speed",1.25)
		Anim:Play(0.05);
		
		local Duration = 0.04
		local OffsetDist = 0.35
		local MoveRadius = 1
		local MoveSpeed = 85
		local FadeTime = 0.08
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "CloneMirage";
		}
		self.Entity.VFX:FireAll(EffectData,{Duration,OffsetDist,MoveRadius,MoveSpeed,FadeTime})
		
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "Evasive";
		}
		self.Entity.VFX:FireAll(EffectData,{})
		
		self.Character:SetAttribute('WillEvasive', true);
		self.Entity.Server.WillEvasive = true;
		task.delay(Action.Constants.EvasiveTime,function()
			self.Character:SetAttribute('WillEvasive', false);
			self.Entity.Server.WillEvasive = false;
		end)
		self.Entity.Cooldowns:Set("Parry", Action.Constants.Cooldown);
	end

	return Action end