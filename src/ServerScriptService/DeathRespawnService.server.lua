local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

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

local function spawnPlayer(player)
	player:LoadCharacter()
	RespawnReady:FireClient(player)
end

RequestRespawn.OnServerEvent:Connect(function(player)
	spawnPlayer(player)
end)

Players.PlayerAdded:Connect(function(player)
	spawnPlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(spawnPlayer, player)
end
