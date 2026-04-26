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
	
	Action.Constants = {ParryTime = 0.2,Cooldown = 1}

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
		if not self.Entity.ActionManager.Validator.Check(self.Entity,script.Name,self.Checks) then return end

		local Anim = self.Entity.Animator:Fetch(`Weapons/Fists/Parry`);
		Anim.Priority = Enum.AnimationPriority.Action
		Anim:SetAttribute("Speed",1.5)
		Anim:Play();
		
		self.Character:SetAttribute('Parrying', true);
		self.Entity.Server.Parrying = true;
		task.delay(Action.Constants.ParryTime,function()
			self.Character:SetAttribute('Parrying', false);
			self.Entity.Server.Parrying = false;
		end)
		self.Entity.Cooldowns:Set(script.Name, Action.Constants.Cooldown);
	end

	return Action end