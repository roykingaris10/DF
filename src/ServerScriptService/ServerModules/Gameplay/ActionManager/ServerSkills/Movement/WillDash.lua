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
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)

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
		local DashInfo = GameSettings.WillDashInfo
		local Enabled = Args.Held

		if Enabled then
			if not self.Entity.ActionManager.Validator.Check(self.Entity,script.Name,self.Checks) then return end
			self.Entity.Cooldowns:Set('WillDash', DashInfo.Cooldown);
			self.Entity.Character:SetAttribute('WillDashing', true);
			self.Entity.Character:SetWillProc(false);
			local Duration = 0.1
			local OffsetDist = 1.75
			local MoveRadius = 2
			local MoveSpeed = 85
			local FadeTime = 0.175
			local EffectData = {
				EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
				Func = "CloneMirage";
			}
			self.Entity.VFX:FireAll(EffectData,{Duration,OffsetDist,MoveRadius,MoveSpeed,FadeTime})
			
			local EffectData = {
				EffectModule = Kits.Nodes.EffectsModules.Shared.Dash;
				Func = "WillDash";
			}
			self.Entity.VFX:FireAll(EffectData,{})
			CombatUtility:CharacterVisible(self.Entity.Character.Rig,true)
			
		else
			CombatUtility:CharacterVisible(self.Entity.Character.Rig,false)
			self.Entity.Character:SetAttribute('WillDashing', false);

		end

	end

	return Action end