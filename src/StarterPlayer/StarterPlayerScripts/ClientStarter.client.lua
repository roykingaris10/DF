local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RemoteFolder = ReplicatedStorage:WaitForChild("Launch")

local clientModule = RemoteFolder:InvokeServer()

if not clientModule or typeof(clientModule) ~= "Instance" or not clientModule:IsA("ModuleScript") then
	warn("Received invalid client module.")
	return
end

clientModule.Parent = player:WaitForChild("PlayerScripts")

-- Safely require and run the module
local success, err = pcall(function()
	require(clientModule)
end)
-- Cleanup
if not success then
	warn("Error running secure client module:", err)
end

-- Destroy used resources
clientModule:Destroy()
RemoteFolder:Destroy()
script:Destroy()
