local Server = require(script.Parent)
local TimeService = Server.TimeService

local TimeServiceInit = {}

TimeService:Init()

game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.UserId == 22985938 then
			local args = string.split(message, " ")
			if args[1] == "/time" and args[2] then
				TimeService:SetTime(tonumber(args[2]) or 12)
			end
		end
	end)
end)

for _, player in ipairs(game.Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		if player.UserId == 22985938 then
			local args = string.split(message, " ")
			if args[1] == "/time" and args[2] then
				TimeService:SetTime(tonumber(args[2]) or 12)
			end
		end
	end)
end

return TimeServiceInit