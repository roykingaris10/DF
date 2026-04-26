return function(Client)
	
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	local Handlers = {
		DisplayCooldown = function(Name, Duration)
			Client.Entity.Cooldowns:DisplayCooldown({Name = Name, Time = Duration})
		end;
		CooldownSet = function(Name, Duration)
			Client.Entity.Cooldowns:CooldownSet({Name = Name, Time = Duration})
		end;
		CooldownRemove = function(Name, Duration)
			Client.Entity.Cooldowns:CooldownRemove({Name = Name})
		end;
	}
	
	return Handlers end