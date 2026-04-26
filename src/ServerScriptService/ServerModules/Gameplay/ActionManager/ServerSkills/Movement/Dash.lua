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
		self.Checks = {"Active","Ragdoll","Stunned","Dashing","Cooldown"}
		self.ValidDirections = {'Left', 'Right', 'Forward', 'Backward'};
		return self
	end

	function Action:Start(Args)
		local DashInfo = GameSettings.DashInfo
		local Enabled = Args.Held
		local MoveDirection = Args.MoveDirection
	
		local IsSide = (MoveDirection == 'Left' or MoveDirection == 'Right');
		local DirectionName = (IsSide and 'Side') or MoveDirection;

		if Enabled then
			if not self.Entity.ActionManager.Validator.Check(self.Entity,script.Name,self.Checks) then print("checkkyy") return end
			self.Entity.Cooldowns:Set('Dash', DashInfo.Cooldown);
			self.Entity.Character:SetAttribute('Dashing', true);
			self.Entity.Character:SetActive(true)
			if IsSide then
			--	self.Entity.Combat:AddIFrame(DashInfo.Side.IFrameDuration);
			--	self.VFX:Fire('General/Dash', 'Side', {Side=MoveDirection});
	
				local EffectData = {
					EffectModule = Kits.Nodes.EffectsModules.Shared.Dash;
					Func = "Side";
				}
				self.Entity.VFX:FireAll(EffectData,{MoveDirection})
				task.delay(.02, function()
					self.Entity.Character:SetActive(false);
				end);
			elseif DirectionName == 'Backward' then
			--	local IFrame = self.Entity.Combat:AddIFrame(DashInfo.Backward.IFrameDuration);
				local EffectData = {
					EffectModule = Kits.Nodes.EffectsModules.Shared.Dash;
					Func = "Backward";
				}
				self.Entity.VFX:FireAll(EffectData,{1})
			else
			--	local IFrame = self.Entity.Combat:AddIFrame(DashInfo.Front.IFrameDuration);	
				self.Entity.Character:SetAttribute('ForwardDashing', true);
				local EffectData = {
					EffectModule = Kits.Nodes.EffectsModules.Shared.Dash;
					Func = "Forward";
				}
				self.Entity.VFX:FireAll(EffectData)
				local EffectData = {
					EffectModule = Kits.Nodes.EffectsModules.Shared.Dash;
					Func = "Woosh";
				}
				self.Entity.VFX:FireAll(EffectData)
			end;
		else
			self.Entity.Character:SetAttribute('Dashing', false);
			self.Entity.Character:SetActive(false);
			self.Entity.Character:SetAttribute('ForwardDashing', false);
		end

	end

	return Action end