return function(Server)
	
	local LibraryInfo = Server.LibraryInfo

	local Network = {}
	return {
		EquipItem = function(Player,...)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			Profile.InventoryManager:EquipItem(...)
		end,
		UnequipItem = function(Player,...)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			Profile.InventoryManager:UnequipItem(...)
		end,
		ChangeItemSlot = function(Player,...)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			Profile.InventoryManager:ChangeItemSlot(...)
		end,
		ActionItem = function(Player, itemTable)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			
			local itemData = LibraryInfo[itemTable.Name]
			if not itemData then warn("MISSING ITEM DATA"..itemTable.Name.." FOR ACTION") return end
			local itemInfo = Profile.InventoryManager:GetItemById(itemTable.Id)
			if not itemInfo then warn("MISSING ITEM"..itemTable.Name.." FOR ACTION") return end
			
			local ActionPathing
			if itemData.Type == "Food" then
				ActionPathing = {"Shared","Eat"}
			elseif itemData.Type == "Weapon" then
				--input Equipping Check Function
				return
			elseif itemData.Type == "Equipment" then
				--input Equipping Check Function
				return
			elseif itemData.Type == "Utility" then
				ActionPathing = {"Shared",itemData.Action}
			else
				return print("NO ACTION YET")
			end
			Profile.ActionManager:StartAction(ActionPathing,itemInfo)
		--	Profile.InventoryManager:ChangeItemSlot(...)
		end,
	} end