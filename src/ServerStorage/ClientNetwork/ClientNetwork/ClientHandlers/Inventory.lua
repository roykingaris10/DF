return function(Client)
	
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	local Handlers = {
		SpawnSetup = function(Weapon, InventoryData, ToolbarData)
			Client.InventoryClient:EquipWeapon(Weapon)
			Client.InventoryClient:InventoryUpdate(InventoryData)
			Client.InventoryClient:ToolbarUpdate(ToolbarData)
		end,
		EquippedWeaponInfo = function(...)
			Client.InventoryClient:EquipWeapon(...)
		end;
		InventoryUpdate = function(...)
			Client.InventoryClient:InventoryUpdate(...)
		end;
		ToolbarUpdate = function(...)
			Client.InventoryClient:ToolbarUpdate(...)
		end;
		EquipItem =function(...)
			Client.InventoryClient:EquipItem(...)
		end;
		UnequipItem =function(...)
			Client.InventoryClient:UnequipItem(...)
		end;
		ItemChanged = function(...)
			Client.InventoryClient:ItemChanged(...)
		end;
		RemoveItem = function(...)
			Client.InventoryClient:RemoveItem(...)
		end;	
	}
	
	return Handlers end