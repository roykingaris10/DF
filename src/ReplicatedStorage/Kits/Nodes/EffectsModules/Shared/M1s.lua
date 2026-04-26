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
	local CameraShaker = require(Nodes.Utility.CameraShaker)
	local EffectsFolder = workspace:WaitForChild("EffectsFolder")
	
	FXClient.M1s = function(self: {any}, Args: {any}, ServerCall: boolean?)
	--	if ServerCall and self.IsClient then return end;
		local Enabled = Args[1]
		local RootCFr = self.Character.Root.CFrame;
		local SwingSound = SoundHandler.Spawn('Universal/punchwhoosh', self.Character.Root, 3);
		SwingSound.PlaybackSpeed = math.random(900,1100)/1000
	end;
	
	FXClient.HitStop = function(self: {any}, Args: {any}, ServerCall: boolean?)
		--	if ServerCall and self.IsClient then return end;
		Client.CameraShake:Shake(CameraShaker.Presets.HitStop)
		local camera = workspace.CurrentCamera
		task.delay(0.125,function()
	--		camera.CameraType = Enum.CameraType.Scriptable
		end)
		local fovtween = TweenService:Create(camera,TweenInfo.new(0.1),{FieldOfView = 60})
		fovtween:Play()
		
		task.wait(0.4)
	--	camera.CameraType = Enum.CameraType.Custom
		local fovtween = TweenService:Create(camera,TweenInfo.new(0.2),{FieldOfView = 70})
		fovtween:Play()
	end;
	
	FXClient.Hits = function(self: {any}, Args: {any}, ServerCall: boolean?)
		--	if ServerCall and self.IsClient then return end;
		local WeaponName = self.Character.Rig:GetAttribute("CurrentEquippedWeapon") or "Fists"
		local HitNum = Args[1]
		local RootCFr = self.Character.Root.CFrame;
		local SwingSound = SoundHandler.Spawn(`Weapons/{WeaponName}/Hit/{HitNum}`, self.Character.Root, 3);
		
	end;
	
	FXClient.AirHits = function(self: {any}, Args: {any}, ServerCall: boolean?)
		--	if ServerCall and self.IsClient then return end;
		local WeaponName = self.Character.Rig:GetAttribute("CurrentEquippedWeapon") or "Fists"
		local HitNum = Args[1]
		local RootCFr = self.Character.Root.CFrame;
		local SwingSound = SoundHandler.Spawn(`Weapons/{WeaponName}/Hit/{HitNum}`, self.Character.Root, 3);

	end;
	
	return FXClient end
