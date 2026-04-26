return function(Client)
	
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	local Handlers = {
		VFXAll = function(EffectData, EffectInfo)
			Client.EffectsClient:Execute(EffectData,EffectInfo)
		end,
		VFXClient = function(EffectData, EffectInfo)
			Client.EffectsClient:Execute(EffectData,EffectInfo)
		end,
	}
	
	return Handlers end