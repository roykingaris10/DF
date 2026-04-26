return function(Server)

	local InventoryFunctions = {}

	local Utilities = Server.Utilities
	local Network = Server.Network
	local Animations = Server.Animations
	local CharacterCustomizationInfo = Server.CharacterCustomizationInfo
	local LibraryInfo = Server.LibraryInfo
	
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Debris = game:GetService("Debris")
	
	local Items = ServerStorage.Tools
	
	InventoryFunctions["ToolbarCleaner"] = function(self)
		local Profile = self:RequestSlotProfile(self.player)
		for i, v in pairs(Profile.Inventory) do
			if v.ToolbarSlot > 0 then
				for id,values in pairs(Profile.Inventory) do
					if v.ToolbarSlot == values.ToolbarSlot and i ~= id then
						values.ToolbarSlot = 0
					end
				end
			end
		end
	end
	
	function InventoryFunctions:getItemById(dataTable, itemId)
		-- Check if the item exists in the table
		local item = dataTable[itemId]
		if not item then
			warn("Item with ID '" .. tostring(itemId) .. "' not found.")
			return nil
		end

		-- Return the found item
		return item
	end


	return InventoryFunctions end
