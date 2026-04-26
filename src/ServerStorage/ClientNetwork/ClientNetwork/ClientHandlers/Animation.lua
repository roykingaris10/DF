return function(Client)
	
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	local Handlers = {
		CaptureCommand = function(Params)
			Client.Entity.AnimHandler:CaptureCommand(Params.Command, Params)
		end,
		
	}
	
	return Handlers end