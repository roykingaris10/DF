local ScriptService = script.Parent
local ServerStorage = game:GetService('ServerStorage')
local ServerScript = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local moduleFolder = ScriptService:WaitForChild('ServerModules')
local infoFolder = ServerStorage:WaitForChild('GameInfo')
local globalModules = ServerStorage:WaitForChild('GlobalModules')
local OkFramework = script:WaitForChild('OkFramework')
OkFramework.Parent = ScriptService

local SoundHandler = require(ReplicatedStorage.Kits.Nodes.Utility.SoundHandler)
local Auxiliary = require(ReplicatedStorage.Kits.Nodes.Utility.Auxiliary)
SoundHandler:Cache();
task.spawn(Auxiliary.Shared.StartCache);

local Server = require(OkFramework)
Server.gameVersion = "DFTest.V.001" -- To change game version

local HttpService = game:GetService('HttpService')
task.spawn(function()
	local success, ServerInfo
	Server.regionName = "Unknown"
	Server.countryCode = "Unknown"
	while not success do
		success = pcall(function()ServerInfo = HttpService:JSONDecode(HttpService:GetAsync('http://ip-api.com/json/')) end)
		task.wait(0.2) 
	end
	Server.RegionInfo = tostring(ServerInfo.regionName .. ", " .. ServerInfo.countryCode) or 'N/A'
	workspace:SetAttribute("RegionInfo",Server.RegionInfo)
end)

for _, module in pairs(globalModules:GetChildren()) do
	Server[module.Name] = require(module)
end

for _, module in pairs(infoFolder:GetChildren()) do
	Server[module.Name] = require(module)
end

Server.PostHTTP = function(player, str)
	local message = HttpService:JSONEncode({content = (player.Name .. ' has attempted to ' .. str) , username = ('Exploiter: '..player.Name)})
	local success, err = pcall(function() 
		HttpService:PostAsync('', message)
	end)
	if not success then warn(err) end
end

--local PhysicsService = game:GetService("PhysicsService")
--PhysicsService:CreateCollisionGroup("Characters")
--PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)

local function install(module)
	print('Installing:', module.Name)
	module.Parent = OkFramework
	Server[module.Name] = require(module)
end

for _, name in pairs({'Network', 'DataProfileService'}) do
	install(moduleFolder[name])
end

for _, module in pairs(moduleFolder.Game:GetChildren()) do
	if module:IsA('ModuleScript') then
		install(module)
	end
end

for _, module in pairs(moduleFolder.Gameplay:GetChildren()) do
	if module:IsA('ModuleScript') then
		install(module)
	end
end

for _, module in pairs(moduleFolder:GetChildren()) do
	if module:IsA('ModuleScript') then
		install(module)
	end
end

Server.HitboxClass = require(ReplicatedStorage.Kits.Nodes.Gameplay.HitboxClass)
Server.CurrentPlayers = {}

local function NewPlayer(Player: Player)
	local Entity = Server.EntityService.new(nil, Player);
	if not Entity then return end
	table.insert(Server.CurrentPlayers,Player)
	Entity.Character:BindSpawn();
	--	Entity.Data.TimesVisited += 1;
--	Server.ServerChat:PlayerLog("Enter",Player.Name)
end;

local function RemovingPlayer(Player: Player)
	local Entity = Server.EntityService.Find(Player);
	if not Entity then return end;
	local index = table.find(Server.CurrentPlayers,Player)
	if index then
		table.remove(Server.CurrentPlayers,index)
	end
	Entity:Destroy();
--	Server.ServerChat:PlayerLog("Leave",Player.Name)
end;

for _,v: Player in Players:GetPlayers() do
	if Server.EntityService.Find(v) then return end;
	NewPlayer(v);
end;

Players.PlayerAdded:Connect(NewPlayer);
Players.PlayerRemoving:Connect(RemovingPlayer);

workspace.Entities.ChildRemoved:Connect(function(child)
	if workspace.CombatData:FindFirstChild(child.Name) then
		print("clearing "..child.Name.." CombatData")
		workspace.CombatData:FindFirstChild(child.Name):Destroy()
	end
end)

task.delay(1,function()
	Server.MobSpawner:SpawnDefault();
end)
