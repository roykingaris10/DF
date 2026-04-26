return function(Server)
	
	local LibraryInfo = Server.LibraryInfo

	local Network = {}
	return {
		Dash = function(Player, Enabled, moveDirection)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Movement","Dash"}
			Profile.ActionManager:StartAction(ActionPathing,Enabled,moveDirection)
		end,
		AirDash = function(Player, Enabled)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Movement","AirDash"}
			Profile.ActionManager:StartAction(ActionPathing,Enabled)
		end,
		WillDash = function(Player, Enabled)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Movement","WillDash"}
			Profile.ActionManager:StartAction(ActionPathing,Enabled)
		end,
		SetAbsolute = function(Player, source, values, duration)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			Profile.StatManager:SetAbsolute(source, values, duration)
		end,
		RemoveAbsolute = function(Player, source)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			Profile.StatManager:RemoveAbsolute(source)
		end,
	} end