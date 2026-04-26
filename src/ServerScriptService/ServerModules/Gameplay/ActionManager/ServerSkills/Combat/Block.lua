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

	function Action.new(Entity)
		local self = setmetatable({}, Action)
		self.Entity = Entity
		self.Maid = Maid.new()
		self.Checks = {"Active","Ragdoll","Stunned","Dashing","Cooldown","BlockBuffer"}
		self.Character = Entity.Character
		return self
	end

	function Action:Start(Args)
		local Held = Args.Held
		if not Held then return end;
		if self.Entity.Server.Blocking then return end;
		
		local function BlockCycle()
			if not self.Entity.ActionManager.Validator.Check(self.Entity,script.Name,self.Checks) then
				repeat wait(.1) until not self.Entity.Server.Held.Block or self.Entity.ActionManager.Validator.Check(self.Entity,script.Name,self.Checks);
				if not self.Entity.Server.Held.Block then return end;
			end;
			
			local Anim = self.Entity.Animator:Fetch(`Weapons/Fists/Block`);
			Anim:Play(nil,nil,.2);

	--		SoundHandler.Spawn(`Universal/Block/Pose`, self.Character.Root, 2);

			self.Character:SetAttribute('Blocking', true);
			self.Entity.Server.Blocking = true;

	--		local NewMovement = self.Entity.Combat:ChangeMobility({Speed=4,Jump=0});

			repeat wait(.1) until not self.Entity.Server.Held.Block or not self.Entity.ActionManager.Validator.Check(self.Entity,script.Name,self.Checks) or not self.Entity.Server.Blocking;

			task.spawn(function()
				self.Entity.Animator:Fetch('Weapons/Fists/BlockFlinch'):Stop(0);
				for i = 1,3 do
				--	self.Animator:Fetch('Universal/Block/Reactions/'..i):Stop(0);
				end;
			end);

			if Anim then
				Anim:Stop(.1);
			end;

			self.Character:SetAttribute('Blocking', false);
			self.Entity.Server.Blocking = false;

		--	NewMovement.Remove();
		end;

		while self.Entity.Server.Held.Block do BlockCycle(); task.wait(.1); end;
	end

	return Action end