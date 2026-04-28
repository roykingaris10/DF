local Client = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes
local Trove = require(Nodes.Utility.Trove);
local GameSettings = require(Nodes.Data.GameSettings);
local Auxiliary = require(Nodes.Utility.Auxiliary)
local SoundHandler = require(Nodes.Utility.SoundHandler);
local ClientTypes = require(Nodes.Data.ClientTypes)
local Client: ClientTypes.Client = {}

task.spawn(Auxiliary.Shared.StartCache);
Auxiliary.Client.SpawnCameraRig();
Auxiliary.Client.Cache();
SoundHandler:Cache();
Client.HitboxClass = require(Nodes.Gameplay.HitboxClass)

local player = game:GetService('Players').LocalPlayer
Client.player = player
local Character = player.Character or player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

Client.CameraControl = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetCameras()
Client.MasterControl = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
Client.MasterControl:Disable()
Client.loaded = false

local Network = {}
do
	local event = game:GetService('ReplicatedStorage').POST
	local func  = game:GetService('ReplicatedStorage').GET

	local auth
	local boundEvents = {}
	local boundFuncs  = {}

	function Network:setKey()
		auth = func:InvokeServer('generate')
	end

	event.OnClientEvent:connect(function(fnId, ...)
		if not boundEvents[fnId] then return end
		boundEvents[fnId](...)
	end)

	func.OnClientInvoke = function(fnId, ...)
		if not boundFuncs[fnId] then return end
		return boundFuncs[fnId](...)
	end

	function Network:bindEvent(name, callback)
		boundEvents[name] = callback
	end

	function Network:bindFunction(name, callback)
		boundFuncs[name] = callback
	end

	function Network:post(...)
		if not auth then return end
		event:FireServer(auth, ...)
	end

	function Network:get(...)
		if not auth then return end
		return func:InvokeServer(auth, ...)
	end
	Client.Network = Network
end

-- Disable Backpack Logic
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local FoldersForLoading = {script.GlobalModules, script.GameInfo, script.ClientNetwork, script.CharSetup, script.ClientModules }
local Startingtable = {script.CharSetup.CharacterHandler,script.CharSetup.Inputter,script.ClientNetwork.ClientNetwork,
	script.ClientModules.UISetup,script.ClientModules.CrewClient, script.ClientModules.InventoryClient,
	script.ClientModules.EffectsClient, script.ClientModules.FootstepsClient, script.ClientModules.PlayerList, script.ClientModules.DialogueHandler, script.ClientModules.FactionClient, script.ClientModules.RegionController,
	script.ClientModules.TimeWeatherController,  script.ClientModules.MenuClient, script.ClientModules.SettingsController, script.ClientModules.TopbarController, script.ClientModules.PartyClient,
	script.ClientModules.CompassController, script.ClientModules.NotificationController, script.ClientModules.DeathClient}

for _, folder in pairs(FoldersForLoading) do
	for i, obj in pairs(folder:GetChildren()) do
		local module = require(obj)
		if type(module) == 'function' then module = module(Client) end
		Client[obj.Name] = module
	end
end

for _, ModuleStart in Startingtable do
	if Client[ModuleStart.Name].Init then task.spawn(Client[ModuleStart.Name].Init)
	else
		warn('Unexpected issue')
	end
	
end

Client.Network:setKey()
Client.MasterControl:Enable()
Client.loaded = true
print('Client Setup Completed')

return nil