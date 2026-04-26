return function(Client)
	local FXClient = {}
	local player = Client.player
	local Network = Client.Network
	local Utilities = Client.Utilities

	local RunService = game:GetService('RunService')
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PhysicsService = game:GetService("PhysicsService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local SoundHandler = require(Nodes.Utility.SoundHandler)
	local Auxiliary = require(Nodes.Utility.Auxiliary)
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	local RockScatter = require(Nodes.Effects.RockScatter)
	
	local EffectsFolder = workspace:WaitForChild("EffectsFolder")
	
	local PlayerGui = player:WaitForChild('PlayerGui')
	local UI = PlayerGui:WaitForChild("UI")

	FXClient.EatFood = function(self: {any}, Args: {any}, ServerCall: boolean?)
		local HUD = PlayerGui.HUD
		
		local hungerHolder = HUD.HUDHolder.hungHolder
		
		for i,hungFrame in pairs(hungerHolder:GetChildren()) do
			if not hungFrame:IsA('Frame') then continue end
			hungFrame.glow.ImageTransparency = 1
			hungFrame.glow.Visible = true
			local tween = TweenService:Create(hungFrame.glow, TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, 0, true), {ImageTransparency = 0})
			tween:Play()
		end
	end

	
	return FXClient end
