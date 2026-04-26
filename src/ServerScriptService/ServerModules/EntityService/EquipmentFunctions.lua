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
	
	InventoryFunctions["GiveEquipped"] = function(self,equippedRequest)
		local Profile = self:RequestSlotProfile(self.player)
		local found = false
		local itemTable = {}
		local itemID

		for i,v in pairs(Profile.equipped) do

			if equippedRequest == i then
				for id,traits in pairs(v) do
				itemID = id
				itemTable = traits
				found = true
				end
				
			end
		end
		
		if found == true then
			return itemTable, itemID
		end
	end
	
	InventoryFunctions["GiveEquipmentNames"] = function(self)
		local Profile = self:RequestSlotProfile(self.player)
		local found = false
		local itemNameTable = {}
		for i,v in pairs(Profile.equipped) do 
			if next(v) then
				for id,traits in pairs(v) do
					itemNameTable[i] = traits.Name
					found = true
				end

			end
		end
		
		return itemNameTable
	end

	return InventoryFunctions end
