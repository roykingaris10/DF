return function(Client)
	local ClientNetwork = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local PacketLinks = Client.PacketLinks
	
	local ClientHandlers = require(script.ClientHandlers)(Client)
	local ClientInvokes = require(script.ClientInvokes)(Client)
	local UnreliableClientHandlers = require(script.UnreliableClientHandlers)(Client)
	
	function ClientNetwork.Init()

		for Name, Handler in ClientHandlers do
			if not PacketLinks[Name] then continue end
			PacketLinks[Name].OnClientEvent:Connect(Handler)
		end
		for Name, Invocation in ClientInvokes do
			if not PacketLinks[Name] then continue end
			PacketLinks[Name].OnClientInvoke = Invocation
		end
		for Name, UnreliableHandler in UnreliableClientHandlers do
			if not PacketLinks[Name] then continue end
			PacketLinks.Unreliables[Name].OnClientEvent:Connect(UnreliableHandler)
		end
		
		Network:bindFunction('ClientFunction', function(fnName, ...)
			if not ClientInvokes[fnName] then
				warn('Client received bad invoke-request ('..tostring(fnName)..')')
				return
			end
			return ClientInvokes[fnName]( ...)
		end)

		Network:bindEvent('ClientEvent', function(fnName, ...)
			if not ClientHandlers[fnName] then
				warn('Client received bad request ('..tostring(fnName)..')')
				return
			end
			ClientHandlers[fnName]( ...)
		end)
	end
	
	
	return ClientNetwork end

	


