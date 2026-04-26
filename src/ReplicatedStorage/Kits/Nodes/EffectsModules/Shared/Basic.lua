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
	local CameraShaker = require(Nodes.Utility.CameraShaker)
	local LightningBolt = require(Nodes.Effects.LightningBolt)
	local LightningSparks = require(Nodes.Effects.LightningBolt:WaitForChild("LightningSparks"))
	
	local EffectsFolder = workspace:WaitForChild("EffectsFolder")
	--[[
	FXClient.Uptilt = function(self: {any}, Args: {any}, ServerCall: boolean?)
		local VictimCFr = Args[1].Victim.Character.Root.CFrame;

		SoundHandler.Spawn(`Universal/LightAttack/{self.Character.Rig:GetAttribute('PlayingCharacter')}/Hit/Uptilt`,  Args[1].Victim.Character.Root, 2);

		local HitEffect: Model = Auxiliary.Client.SpawnGroup(Assets.UptiltStart, VictimCFr, 4);
		Auxiliary.Client.Emit(HitEffect.Root);

		Auxiliary.Client.BindMesh(HitEffect.Ring, function(Ring)
			local TweenTime = .23;

			TweenService:Create(Ring, TweenInfo.new(TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = Ring.Position + Vector3.yAxis*10}):Play();

			task.spawn(function()
				TweenService:Create(Ring, TweenInfo.new(TweenTime*.45, Enum.EasingStyle.Linear), {Size = Vector3.new(5,1.2,5), Transparency = 1}):Play();
				task.wait(TweenTime*.45);

				TweenService:Create(Ring, TweenInfo.new(TweenTime*(1-.45), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = Vector3.new(3.5,.45,3.5), Transparency = 1}):Play();
			end);

			task.wait(TweenTime);
		end);
	end;
	]]
	FXClient.CriticalAirRush = function(self: {any}, Args: {any}, ServerCall: boolean?)	
		SoundHandler.Spawn('Movement/Teleport Soru v2', self.Character.Root, 1);
	end
	
	FXClient.SlamBounce = function(self: {any}, Args: {any}, ServerCall: boolean?)	
		local FloorPos = Args[1];
		RockScatter.new(CFrame.new(FloorPos+Vector3.new(0,3,0)), 4, 15, {0.7,1,1.2}, Args[2], Args[3])
		SoundHandler.Spawn('Combat/rocksmash', self.Character.Root, 2);

		task.spawn(Auxiliary.Rock.Crater, CFrame.new(FloorPos+Vector3.new(0,3,0)), {

			MinAngleVariation = 40;
			MaxAngleVariation = 65;
			LayerRingRandomization = true;

			Rocks = 4;

			RaycastRange = 15;
			BaseDuration = 3,
			ExposeLevel = -0.3;
			Distance = 1;	
			Layers = 3;
			LayerScaling = 0.11;

			SizeMagnitude = Vector3.new(0.7,1.5,0.25);

		});
		task.spawn(Auxiliary.Rock.Explode, CFrame.new(FloorPos+Vector3.new(0,3,0)), {
			Rocks = 5;
			SizeMagnitude = .5;
			HorizontalVelocity = -3;
			VerticalVelocity = 8;
			RayRange = 15;
			Lifespan = 3;
		});
	end
	
	FXClient.AirCombatTag = function(self: {any}, Args: {any}, ServerCall: boolean?)	
		local AirComboTarget = self.Character.Rig:FindFirstChild("AirComboTarget")
		if not AirComboTarget or not self.Character.Rig:GetAttribute("AirComboTarget") then return end
		local Marker = Kits.Storage.AirCombatMarker:Clone()
		Marker.Parent = AirComboTarget.Value.HumanoidRootPart
		Marker.BillboardGui.Adornee = AirComboTarget.Value.HumanoidRootPart
		repeat task.wait() until not AirComboTarget.Parent or not AirComboTarget.Value:GetAttribute("Uptilted")-- or not AirComboTarget.Value:GetAttribute("AirComboTarget")
		Marker:Destroy()
	end
	
	FXClient.Evasive = function(self: {any}, Args: {any}, ServerCall: boolean?)	
		SoundHandler.Spawn('Combat/Evasive', self.Character.Root, 1.5);
		local Highlight = Instance.new("Highlight")
		Highlight.FillTransparency = 0.75
		Highlight.FillColor = Color3.fromRGB(120, 53, 255)
		Highlight.OutlineTransparency = 0
		Highlight.OutlineColor = Color3.fromRGB(102, 0, 255)
		Highlight.Parent = self.Character.Rig
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Enabled = true
		local tween = TweenService:Create(Highlight, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out,0,true), {FillTransparency = 1, OutlineTransparency = 1})
		tween:Play()
		Client.Debris:AddItem(Highlight, 0.3)
	end
	
	FXClient.ParryFX = function(self: {any}, Args: {any}, ServerCall: boolean?)	
		local sparks = Auxiliary.Client.SpawnGroup(script.Parry, self.Character.Root.CFrame*CFrame.new(0,0,-1), 1);
		Client.EffectFunctions:Emit(sparks)
		Client.EffectFunctions:ToneDown(sparks)
		SoundHandler.Spawn('Combat/parry clash', self.Character.Root, 1.1);
	end
	
	FXClient.DownslamFX = function(self: {any}, Args: {any}, ServerCall: boolean?)	
		local FloorPos = Args[1]
		local color = Args[2]
		local mat = Args[3]

		RockScatter.new(CFrame.new(FloorPos+Vector3.new(0,3,0)), 8, 25, {0.7,1,1.2}, color, mat)
		SoundHandler.Spawn('Universal/Explosion', self.Character.Root, 5);
		
		task.spawn(Auxiliary.Rock.Crater, CFrame.new(FloorPos+Vector3.new(0,3,0)), {

			MinAngleVariation = 40;
			MaxAngleVariation = 65;
			LayerRingRandomization = true;

			Rocks = 4;

			RaycastRange = 15;
			BaseDuration = 5,
			ExposeLevel = -0.3;
			Distance = 3;	
			Layers = 3;
			LayerScaling = 0.18;

			SizeMagnitude = Vector3.new(1,1.75,0.25);

		});
		task.spawn(Auxiliary.Rock.Explode, CFrame.new(FloorPos+Vector3.new(0,3,0)), {
			Rocks = 8;
			SizeMagnitude = .5;
			HorizontalVelocity = -3;
			VerticalVelocity = 8;
			RayRange = 15;
			Lifespan = 3;
		});
	
		local SlamPart = script.DownslamVFX:Clone()
		SlamPart.CFrame = CFrame.new(FloorPos)
		SlamPart.Parent = workspace.EffectsFolder
		Client.Debris:AddItem(SlamPart,2)
		Client.EffectFunctions:Emit(SlamPart)
	
		local attach1tween = TweenService:Create(SlamPart.attach1,TweenInfo.new(0.2),{Position = Vector3.new(13,0,0)})
		local attach2tween = TweenService:Create(SlamPart.attach2,TweenInfo.new(0.2),{Position = Vector3.new(-13,0,0)})
		local attach3tween = TweenService:Create(SlamPart.attach3,TweenInfo.new(0.2),{Position = Vector3.new(-13,0,0)})
		local attach4tween = TweenService:Create(SlamPart.attach4,TweenInfo.new(0.2),{Position = Vector3.new(13,0,0)})

		local beam1tween = TweenService:Create(SlamPart.Beam,TweenInfo.new(0.2),{CurveSize0 = -15,CurveSize1 = 15,Width0 = 6,Width1 = 6})
		local beam2tween = TweenService:Create(SlamPart.Beam2,TweenInfo.new(0.2),{CurveSize0 = -15,CurveSize1 = 15,Width0 = 6,Width1 = 6})

		attach1tween:Play()
		attach2tween:Play()
		attach3tween:Play()
		attach4tween:Play()

		beam1tween:Play()
		beam2tween:Play()
		beam1tween.Completed:Wait()

		local beam1tween2 = TweenService:Create(SlamPart.Beam,TweenInfo.new(0.3,Enum.EasingStyle.Quart),{Width0 = 0,Width1 = 0})
		local beam2tween2 = TweenService:Create(SlamPart.Beam2,TweenInfo.new(0.3,Enum.EasingStyle.Quart),{Width0 = 0,Width1 = 0})

		beam1tween2:Play()
		beam2tween2:Play()
	end

	FXClient.WillProc = function(self: {any}, Args: {any}, ServerCall: boolean?)
	--	if ServerCall and self.IsClient then return end;
		local Enabled = Args[1]
		local RootCFr = self.Character.Root.CFrame;
	--	SoundHandler.Spawn('Movement/Dash', self.Character.Root, 3);
		SoundHandler.Spawn('Basic/madnesslightning', self.Character.Root, 1);
		local WillAura = Auxiliary.Client.SpawnGroup(script.WillAura, RootCFr);
		
		local weld = Instance.new("WeldConstraint")
		weld.Parent = WillAura
		weld.Part0 = WillAura
		weld.Part1 = self.Character.Root
		
		repeat task.wait(0.1) until not self.Character.Rig:GetAttribute("WillProc")
		Client.EffectFunctions:Enable(WillAura, false)
	--	WillAura:Destroy()
	end;
	
	
	FXClient.CloneMirage = function(self: {any},Args: {any})
		local Duration = Args[1] or 0.1
		local OffsetDist = Args[2] or 1.75
		local MoveRadius = Args[3] or 0.75
		local MoveSpeed = Args[4] or 60
		local FadeTime = Args[5] or 0.2

		local Root = self.Character.Root
		local RootCFr = Root.CFrame

		local clones = {}
		local startCFrames = {}
		local seeds = {}
		local outwardDirs = {}

		for i = 1, 2 do
			self.Character.Rig.Archivable = true
			local clone = self.Character.Rig:Clone()
			clone.Name = self.Character.Rig.Name .. "_Mirage"
			local hrp = clone:FindFirstChild("HumanoidRootPart")

			clone.HumanoidRootPart.Anchored = true

			-- cleanup scripts & collisions
			for _, obj in ipairs(clone:GetDescendants()) do
				if obj:IsA("Script") or obj:IsA("LocalScript") or obj.Name == "PostureAttach" or obj.Name == "CDBillboard" then
					obj:Destroy()
				elseif obj:IsA("BasePart") then
					obj.CanCollide = false
					obj.CollisionGroup = "Nothing"
				end
			end

			CombatUtility:CharacterVisible(clone,false)

			local hum = clone:FindFirstChildWhichIsA("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				hum:ChangeState(Enum.HumanoidStateType.Physics)
			end

			clone.Parent = EffectsFolder

			local side = (i == 1 and -1 or 1)
			local offset = RootCFr.RightVector * (OffsetDist * side)
			clone:PivotTo(RootCFr + offset)

			startCFrames[i] = hrp.CFrame

			-- outward direction NEVER changes → clean outward drift
			local initialDif = (hrp.Position - Root.Position)
			outwardDirs[i] = (initialDif.Magnitude > 0) and initialDif.Unit or RootCFr.RightVector

			-- noise seeds
			seeds[i] = {
				x = math.random(1,99999),
				z = math.random(1,99999)
			}

			table.insert(clones,clone)
		end
		self.Character.Rig.Archivable = false

		local startTime = os.clock()

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			local t = os.clock() - startTime
			local progress = math.clamp(t / (Duration + FadeTime), 0, 1)

			-- Stop only after movement & fading both finish
			if t > Duration + FadeTime then
				conn:Disconnect()
			end

			for i, clone in ipairs(clones) do
				local hrp = clone:FindFirstChild("HumanoidRootPart")
				if not hrp then continue end

				local s = seeds[i]
				local baseCF = startCFrames[i]

				-- jitter
				local dx = math.noise(t * MoveSpeed, s.x) * MoveRadius
				local dz = math.noise(t * MoveSpeed, s.z) * MoveRadius

				-- Outward drift that grows
				local outward = outwardDirs[i]
				local outwardStrength = progress * OffsetDist * 0.6
				local outOffset = outward * outwardStrength
				
				
				clone:PivotTo(
					baseCF * CFrame.new(
						dx + outOffset.X,
						0,
						dz + outOffset.Z
					)
				)

				-- Fade while moving
				if t >= Duration then
					local fadeProgress = math.clamp((t - Duration) / FadeTime, 0, 1)

					for _, part in ipairs(clone:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = fadeProgress
						end
					end
				end
			end
		end)

		task.delay(Duration + FadeTime + 0.05, function()
			for _, clone in ipairs(clones) do
				clone:Destroy()
			end
		end)
	end
	
	FXClient.BlockBreak = function(self: {any},Args: {any})
		local Root = self.Character.Root
		
		local blockBreak = script.blockbreak.BreakAttach:Clone()
		blockBreak.Parent = self.Character.Rig.Torso
		
		Client.EffectFunctions:Emit(blockBreak)
		Client.Debris:AddItem(blockBreak)
		
		SoundHandler.Spawn('Combat/BlockBreak', self.Character.Root, 1);
		
		local HeadStun = script.HeadStun:Clone()
		HeadStun.Parent = workspace.EffectsFolder

		local weld = Instance.new("Weld")
		weld.Parent = HeadStun
		weld.Part0 = self.Character.Rig.Head
		weld.Part1 = HeadStun
		Client.Debris:AddItem(HeadStun,1)
		Client.Debris:AddItem(weld,1)

		task.wait(0.8)

		Client.EffectFunctions:Emit(HeadStun)

		local beamtween = TweenService:Create(HeadStun.stunattach1.Beam,TweenInfo.new(0.2),{Width0 = 0,Width1 = 0})
		beamtween:Play()
		local beamtween2 = TweenService:Create(HeadStun.stunattach1.Beam2,TweenInfo.new(0.2),{Width0 = 0,Width1 = 0})
		beamtween2:Play()
	end
	
	FXClient.ClashingInitialCamera = function(self: {any}, Args: {any})
		Client.CameraShake:Shake(CameraShaker.Presets.Clashing)
		
		local camera = workspace.CurrentCamera
		local fovtween = TweenService:Create(camera,TweenInfo.new(0.25),{FieldOfView = 85})
		fovtween:Play()
		task.wait(0.15)
		Client.CameraShake:Shake(CameraShaker.Presets.Clashing)
		repeat task.wait() until not self.Character.Rig.Parent or not self.Character.Rig:GetAttribute("Clashing")
		
		local fovtween = TweenService:Create(camera,TweenInfo.new(0.2),{FieldOfView = 70})
		fovtween:Play()
	end
	
	FXClient.LightningClash = function(self: {any}, Args: {any})
		local midpointCF = Args[1] * CFrame.Angles(0,math.rad(90),0)
		
		local attach = Instance.new("Attachment")
		attach.Parent = workspace.EffectsFolder
		attach.Position = midpointCF.Position
		
		local function SpawnAttachmentBetween(minDist, maxDist, xSpreadDeg, ySpreadDeg)
			-- Random distance
			local distance = math.random(minDist, maxDist)

			-- Random spread angles
			local randomX = math.rad(math.random(-xSpreadDeg, xSpreadDeg))
			local randomY = math.rad(math.random(-ySpreadDeg, ySpreadDeg))

			-- Apply spread rotation
			local spreadCF = midpointCF
				* CFrame.Angles(randomX, randomY, 0)

			-- Move forward relative to spread
			local finalPosition = spreadCF.Position + (spreadCF.LookVector * distance)

			-- Create attachment
			local attachment = Instance.new("Attachment")
			attachment.WorldPosition = finalPosition
			attachment.Parent = workspace.EffectsFolder -- or wherever you want

			return attachment
		end
		
		local function LightningCreate()
			local attach2 = SpawnAttachmentBetween(5, 12, 360, 35)
			Client.Debris:AddItem(attach2,2)
			
			local HighlightProperties = {
				FillColor = Color3.fromRGB(0, 0, 0),
				OutlineColor = Color3.fromRGB(255, 255, 255),
				FillTransparency = 0,
				OutlineTransparency = 1,
				DepthMode = Enum.HighlightDepthMode.Occluded
			}
			
			local Lightning1 = LightningBolt.new(attach,attach2, math.random(4,7),HighlightProperties)
			Lightning1.MinRadius = 0.2
			Lightning1.MaxRadius = 2
			Lightning1.AnimationSpeed = 10
			Lightning1.FadeLength = 0.5
			Lightning1.PulseLength = 1.35
			Lightning1.Thickness = 0.4
			Lightning1.PulseSpeed = 5.7
			Lightning1.Frequency = 6
			Lightning1.Color = Color3.fromRGB(255, 0, 0)
		end
		
		repeat 
			LightningCreate()
			LightningCreate()
	--		LightningSparks.new(Lightning2)
			local SpawnInterval = math.random(15,90)/1000
			task.wait(SpawnInterval)
		until not self.Character.Rig.Parent or not self.Character.Rig:GetAttribute("Clashing")
		
		Client.Debris:AddItem(attach,1)
	end
	
	FXClient.ClashingFX = function(self: {any}, Args: {any})
		local MidPoint = Args[1]
		
	--	RockScatter.new(CFrame.new(MidPoint+Vector3.new(0,3,0)), 3, 15, {0.4,0.7,1})
	--	SoundHandler.Spawn('Universal/Explosion', self.Character.Root, 5);
		local WillAura = Auxiliary.Client.SpawnGroup(script.Clashing, CFrame.new(MidPoint));
		Client.EffectFunctions:Emit(WillAura)
		Client.EffectFunctions:Enable(WillAura,true)
		task.spawn(Auxiliary.Rock.Crater, CFrame.new(MidPoint+Vector3.new(0,3,0)), {

			MinAngleVariation = 40;
			MaxAngleVariation = 65;
			LayerRingRandomization = true;

			Rocks = 4;

			RaycastRange = 15;
			BaseDuration = 3,
			ExposeLevel = -0.3;
			Distance = 3;	
			Layers = 2;
			LayerScaling = 0.18;

			SizeMagnitude = Vector3.new(1,1.75,0.15);
		});
		
		task.spawn(Auxiliary.Rock.Explode, CFrame.new(MidPoint+Vector3.new(0,3,0)), {
			Rocks = 3;
			SizeMagnitude = .2;
			HorizontalVelocity = -3;
			VerticalVelocity = 8;
			RayRange = 15;
			Lifespan = 3;
		});
		
		local ImpactIntervals = {0.4,0.675}
		local IntervalsReached = 0
		
		local StartTime = tick()
	
		local IntervalsReached = 0
		
		local StartTime = tick()
		repeat 
			task.wait()
			if StartTime + ImpactIntervals[1] <= tick() and IntervalsReached < 1 then
				IntervalsReached = 1
				task.spawn(Auxiliary.Rock.Crater, CFrame.new(MidPoint+Vector3.new(0,3,0)), {

					MinAngleVariation = 40;
					MaxAngleVariation = 65;
					LayerRingRandomization = true;

					Rocks = 5;

					RaycastRange = 15;
					BaseDuration = 3,
					ExposeLevel = -0.3;
					Distance = 5;	
					Layers = 2;
					LayerScaling = 0.18;

					SizeMagnitude = Vector3.new(1.2,1.75,0.25);
				});
				
				task.spawn(Auxiliary.Rock.Explode, CFrame.new(MidPoint+Vector3.new(0,3,0)), {
					Rocks = 3;
					SizeMagnitude = .4;
					HorizontalVelocity = -3;
					VerticalVelocity = 8;
					RayRange = 15;
					Lifespan = 3;
				});
			elseif StartTime + ImpactIntervals[2] <= tick() and IntervalsReached < 2 then
				IntervalsReached = 2
				task.spawn(Auxiliary.Rock.Crater, CFrame.new(MidPoint+Vector3.new(0,3,0)), {

					MinAngleVariation = 40;
					MaxAngleVariation = 65;
					LayerRingRandomization = true;

					Rocks = 6;

					RaycastRange = 15;
					BaseDuration = 5,
					ExposeLevel = -0.15;
					Distance = 6;	
					Layers = 1;
					LayerScaling = 0.18;

					SizeMagnitude = Vector3.new(1.5,2,0.325);
				});
				
				task.spawn(Auxiliary.Rock.Explode, CFrame.new(MidPoint+Vector3.new(0,3,0)), {
					Rocks = 4;
					SizeMagnitude = .6;
					HorizontalVelocity = -3;
					VerticalVelocity = 8;
					RayRange = 15;
					Lifespan = 3;
				});
			end
			
		until not self.Character.Rig.Parent or not self.Character.Rig:GetAttribute("Clashing")
		Client.EffectFunctions:Enable(WillAura,false)
	end

	FXClient.ClashingMirage = function(self: {any}, Args: {any})
		local Duration      = Args[1] or 0.15
		local FadeTime      = Args[2] or 0.25
		local MoveSpeed     = Args[3] or 50
		local MoveRadius    = Args[4] or 0.4
		local BackDistance  = Args[5] or 5
		local CloneColor 	= Args[6] or Color3.fromRGB(255, 255, 255)
		local ConeAngle     = 25

		local Root = self.Character.Root
		local Character = self.Character.Rig
		
		local function getBackwardDirection(rootPart, angleDeg)
			-- Get the current backward direction based on character's facing
			local backward = -rootPart.CFrame.LookVector
			local angleRad = math.rad(angleDeg)

			-- create orthonormal basis
			local right = rootPart.CFrame.RightVector
			local up = rootPart.CFrame.UpVector

			-- random offsets inside cone
			local yaw = (math.random() - 0.5) * 2 * angleRad
			local pitch = (math.random() - 0.5) * 2 * angleRad

			-- Start with backward direction and add random offsets
			local dir = backward
				+ right * math.tan(yaw)
				+ up * math.tan(pitch)

			return dir.Unit
		end

		local function SpawnSoul()
			if not Character:GetAttribute("Clashing") then
				return
			end

			Character.Archivable = true
			local clone = Kits.Storage.CloneLite:Clone()
			Character.Archivable = false

			clone.Name = Character.Name .. "_Soul"

			local hrp = clone:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			hrp.Anchored = true

			for _, obj in ipairs(clone:GetDescendants()) do
				if obj:IsA("Script") or obj:IsA("LocalScript") then
					obj:Destroy()
				elseif obj:IsA("BasePart") or obj:IsA("MeshPart") then
					obj.Color = CloneColor
					obj.Material = Enum.Material.Neon
					if Character:FindFirstChild(obj.Name) then
						obj.CFrame = Character[obj.Name].CFrame 
						obj.Anchored = true
					end
					obj.CanCollide = false
					obj.CollisionGroup = "Nothing"
				elseif obj:IsA("Motor6D") then
					obj.Enabled = false
				end
			end

			clone.Parent = EffectsFolder
			clone:PivotTo(Root.CFrame)

			local seeds = {
				x = math.random(1,9999),
				z = math.random(1,9999)
			}
			
			local BackwardDir = getBackwardDirection(Root, ConeAngle)

			local startTime = os.clock()
			local totalTime = Duration + FadeTime

			-- Store initial position for relative movement calculation
			local startCF = Root.CFrame

			local conn
			conn = RunService.Heartbeat:Connect(function(dt)
				local elapsed = os.clock() - startTime

				if elapsed >= totalTime then
					conn:Disconnect()
					clone:Destroy()
					return
				end

				local currentRootCF = Root.CFrame

				local alpha = math.clamp(elapsed / totalTime, 0, 1)
				local smoothAlpha = 1 - (1 - alpha)^3

				-- ULTRA SMOOTH - Almost no movement
				local jitterIntensity = 0.35 -- Barely 1 centimeter of movement
				local noiseSpeed = MoveSpeed * 0.1  -- Very slow

				local dx = math.noise(elapsed * noiseSpeed, seeds.x) * jitterIntensity
				local dz = math.noise(elapsed * noiseSpeed, seeds.z) * jitterIntensity * 0.3  -- Even less forward/back

				-- Backward movement (this is the main motion)
				local backwardOffset = BackwardDir * (smoothAlpha * BackDistance)

				-- Almost imperceptible jitter
				local rightJitter = currentRootCF.RightVector * dx
				local forwardJitter = currentRootCF.LookVector * dz

				local finalPosition = currentRootCF.Position + backwardOffset + rightJitter + forwardJitter
				local finalCF = CFrame.new(finalPosition) * (currentRootCF - currentRootCF.Position)

				clone:PivotTo(finalCF)

				local startTransparency = 0.9
				local endTransparency = 1.0
				local fadeAlpha = startTransparency + (alpha * (endTransparency - startTransparency))
				-- This equals: 0.5 + (alpha * 0.5)

				for _, part in ipairs(clone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = fadeAlpha
					end
				end
			end)
		end

		task.spawn(function()
			while Character:GetAttribute("Clashing") do
				SpawnSoul()
				local SpawnInterval = math.random(250,600)/1000
				task.wait(SpawnInterval)
			end
		end)
	end
	
	return FXClient end
