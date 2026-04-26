local Server = require(script.Parent)

local Network = Server.Network
local ServerStorage = game:GetService('ServerStorage')
local Remotes = game:GetService('ReplicatedStorage')

-- Launch
local launchedPlayers = {}
Remotes:WaitForChild('Launch').OnServerInvoke = function(player)
	if launchedPlayers[player] then player:Kick() return end
	launchedPlayers[player] = true
	local PlayerGui = player:WaitForChild('PlayerGui')
	local client = ServerStorage.Client:Clone()
	ServerStorage.GlobalModules:Clone().Parent = client
	ServerStorage.GameInfo:Clone().Parent = client
	ServerStorage.ClientModules:Clone().Parent = client
	ServerStorage.ClientNetwork:Clone().Parent = client
	ServerStorage.CharSetup:Clone().Parent = client
	client.Parent = PlayerGui
	return client
end


Network:bindFunction('Ping', function(player)
	return math.floor((player:GetNetworkPing()) * 1000)
end)






return nil