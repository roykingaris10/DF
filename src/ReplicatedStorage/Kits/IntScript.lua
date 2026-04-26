local TimeWeatherService = require(game.ServerScriptService.Services.TimeWeatherService)

TimeWeatherService:Init()

game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		
		if player.UserId == 22985938 then
			local args = string.split(message, " ")

			if args[1] == "/weather" and args[2] then
				TimeWeatherService:SetWeather(args[2])
			elseif args[1] == "/time" and args[2] then
				TimeWeatherService:SetTime(tonumber(args[2]) or 12)
			elseif args[1] == "/event" and args[2] then
				TimeWeatherService:TriggerEvent(args[2])
			elseif args[1] == "/climate" and args[2] then
				TimeWeatherService:SetClimateZone(args[2])
			end
		end
	end)
end)