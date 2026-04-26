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
		self.Checks = {"Ragdoll","Stunned","Cooldown", "WillProc"}
		return self
	end

	function Action:Start(Args)
		local WillInfo = GameSettings.WillProc
		if not self.Entity.ActionManager.Validator.Check(self.Entity,"WillProc",self.Checks) then return end
		if self.Entity.StatManager.Will < WillInfo.Cost then return end
		self.Entity.Character:SetWillProc(true);

		--	self.Entity.Combat:AddIFrame(DashInfo.Side.IFrameDuration);
		--	self.VFX:Fire('General/Dash', 'Side', {Side=MoveDirection});
		
		self.Entity.StatManager:ChangeWill(-WillInfo.Cost)

		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "WillProc";
		}
		self.Entity.VFX:FireAll(EffectData,{})
		
		local startTick = tick()
		repeat task.wait() until WillInfo.Duration + startTick < tick() or not self.Entity.Character.WillProc
		self.Entity.Character:SetWillProc(false);
		self.Entity.Cooldowns:Set('WillProc', WillInfo.Cooldown);
	end

	return Action end