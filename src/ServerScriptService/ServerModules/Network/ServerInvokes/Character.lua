return function(Server)
	local Network = {}

	return {
		NewSlotCreated = function(Player,Slot: number,newPlayerCustomization: {any})
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			return Profile:NewSlotCreated(Slot,newPlayerCustomization)
		end,
		
		FilterName = function(Player,filterName: string)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
		
			return Profile:FilterName(filterName)
		end,
		
		RequestSlots = function(Player)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local SlotCount = Profile.Data.SlotData
			
			return Profile.Data.SlotData.SlotsAvailable
		end,
		
		CurrentRace = function(Player, Slot: number, newSlot: boolean)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			return Profile:GetSlotRace(Slot,newSlot)
		end,


	} end