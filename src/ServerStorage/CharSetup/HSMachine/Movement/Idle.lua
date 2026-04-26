return function(Client)
	local State = {}
	local player = Client.player
	local Network = Client.Network
	
	
	State["Enter"] = function(self,Params)
		print("bruppy")
	end
	
	State["Update"] = function(self,Params)

	end
	
	State["Exit"] = function(self,Params)

	end

return State end
