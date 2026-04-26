local Server = require(script.Parent)
local Network = Server.Network
local Players = game:GetService("Players")

local PlayerListService = {}

function PlayerListService.BroadcastUpdate()
	for _, client in ipairs(Players:GetPlayers()) do
		Network:post("PlayerListUpdate", client)
	end
end

function PlayerListService.OnCrewChange(player)
	PlayerListService.BroadcastUpdate()
end

Players.PlayerAdded:Connect(function(player)
	task.wait(1)

	local statFolder = player:WaitForChild("StatFolder", 5)
	if statFolder then
		local userFolder = statFolder:WaitForChild("UserFolder", 5)
		if userFolder then
			userFolder:GetAttributeChangedSignal("Crew"):Connect(function()
				-- When crew changes, broadcast to all clients
				PlayerListService.BroadcastUpdate()
			end)
		end
	end

	PlayerListService.BroadcastUpdate()
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerListService.BroadcastUpdate()
end)

return PlayerListService