local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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

local Server
task.spawn(function()
	local OkFramework = ServerScriptService:WaitForChild("OkFramework", 30)
	if not OkFramework then return end
	Server = require(OkFramework)
end)

local function getEntity(player)
	if not Server then return nil end
	if not Server.EntityService or not Server.EntityService.Find then return nil end
	return Server.EntityService.Find(player)
end

RequestRespawn.OnServerEvent:Connect(function(player)
	local entity = getEntity(player)
	if entity and entity.Character and entity.Character.Respawn then
		entity.Character:Respawn()
	else
		player:LoadCharacter()
	end
	RespawnReady:FireClient(player)
end)

return nil
