return function(Server)
	
	local LibraryInfo = Server.LibraryInfo

	local Network = {}
	return {
		ClientEffectsAll = function(Player, EffectData,Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			
			Profile.VFX:FireAll(EffectData,Params or {})
		end,
	} end