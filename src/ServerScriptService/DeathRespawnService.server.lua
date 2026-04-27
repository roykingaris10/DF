local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.RespawnTime = math.huge

local function getOrCreate(name, className)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then return existing end
	local r = Instance.new(className)
	r.Name = name
	r.Parent = ReplicatedStorage
	return r
end

local RequestRespawn = getOrCreate("RequestRespawn", "RemoteEvent")
local RespawnReady = getOrCreate("RespawnReady", "RemoteEvent")

RequestRespawn.OnServerEvent:Connect(function(player)
	player:LoadCharacter()
	RespawnReady:FireClient(player)
end)

return nil
