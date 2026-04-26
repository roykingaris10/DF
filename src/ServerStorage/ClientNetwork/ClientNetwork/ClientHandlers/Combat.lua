return function(Client)
	
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	local Handlers = {
		AnimationStop = function()

		end,
		RemoveAllBodyForces = function(Parent)
			CombatUtility:RemoveAllBodyForces(Parent)
		end,
		BPPlacer = function(Parent,Params)
			CombatUtility:BPPlacer(Parent,Params)
		end,
		BGPlacer = function(Parent,Params)
			CombatUtility:BGPlacer(Parent,Params)
		end,
		--[[
		SetCooldown = function(...)
			Client.Entity.Cooldowns:Set(...)
		end;]]
		
	}
	
	return Handlers end