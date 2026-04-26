local CombatUtility = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local SharedFunctions = require(Nodes.Effects.Functions)
local Auxiliary = require(Nodes.Utility.Auxiliary)
local Debris = require(Nodes.Utility.Debris)

function CombatUtility:DragRope(parent,infoTable)

	local Rope = Instance.new("RopeConstraint")
	Rope.Thickness = infoTable.Thickness or 0.4
	Rope.Visible = infoTable.Visible or false
	Rope.Attachment0 = infoTable.Attachment0
	Rope.Attachment1 = infoTable.Attachment1
	Rope.Length = infoTable.Length or 5
	Rope.Parent = parent

	if infoTable.Duration then
		Debris:AddItem(Rope,infoTable.Duration)
	end

	return Rope
end

function CombatUtility:RemoveRope(Parent, Whitelist)
	for i,v in pairs(Parent:GetChildren()) do 
		if v:IsA("RopeConstraint") then
			if v.Name ~= "NoRemove" and v.Name ~= Whitelist then
				v:Destroy()
			end
		end
	end
end

function CombatUtility:AlignKnockback(user,infoTable)

	local AlignAttach = ReplicatedStorage.Utility.AlignPart.AlignAttach:Clone()
	AlignAttach.Name = infoTable.Name or AlignAttach.Name
	AlignAttach.AlignPosition.MaxAxesForce = infoTable.MaxForce or Vector3.new(1e8,1e8,1e8)
	AlignAttach.AlignPosition.MaxVelocity = infoTable.Velocity or 1e9
	AlignAttach.AlignPosition.Responsiveness = infoTable.Responsiveness or 10
	AlignAttach.AlignPosition.RigidityEnabled = infoTable.Rigidity or false
	AlignAttach.AlignPosition.Position = infoTable.Position
	
	AlignAttach.Parent = user:WaitForChild("HumanoidRootPart")

	Debris:AddItem(AlignAttach,infoTable.Duration)
end

function CombatUtility:LVPlacer(user,infoTable)

	local LVAttach = ReplicatedStorage.Utility.LVPart.LVAttach:Clone()
	LVAttach.LinearVelocity.MaxAxesForce = infoTable.MaxForce or Vector3.new(1e5,1e5,1e5)
	LVAttach.LinearVelocity.VectorVelocity = infoTable.Velocity or Vector3.new(0,0,0)
	LVAttach.Parent = user:WaitForChild("HumanoidRootPart")
	
	if infoTable.Duration then
		Debris:AddItem(LVAttach,infoTable.Duration)
	end
	
	return LVAttach
end

function CombatUtility:BVPlacer(parent,infoTable)
	if infoTable.AngularVelocity then
		parent.AssemblyAngularVelocity += infoTable.AngularVelocity;
	end;
	
	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.Name = infoTable.Name or "BodyVel"
	BodyVelocity.MaxForce = infoTable.MaxForce or Vector3.new(50000000,50000000,50000000)
	BodyVelocity.Velocity = infoTable.Velocity or Vector3.zero

	BodyVelocity.Parent = parent

	if infoTable.Duration then
		if infoTable.Ease then
			TweenService:Create(BodyVelocity, TweenInfo.new(infoTable.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Velocity = Vector3.zero}):Play();
		end;
		Debris:AddItem(BodyVelocity,infoTable.Duration)
	end
	
	
	return BodyVelocity
end

function CombatUtility:BPPlacer(Parent,infoTable)

	local BodyPosition = Instance.new("BodyPosition")
	BodyPosition.Name = infoTable.Name or "BodyPos"
	BodyPosition.MaxForce = infoTable.MaxForce or Vector3.new(1e7,1e7,1e7)
	BodyPosition.P = infoTable.P or 1200
	BodyPosition.D = infoTable.D or 750
	BodyPosition.Position = infoTable.Position

	BodyPosition.Parent = Parent

	if infoTable.Duration then
		if infoTable.Ease then
			TweenService:Create(BodyPosition, TweenInfo.new(infoTable.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {P = 0}):Play();
		end;
		Debris:AddItem(BodyPosition,infoTable.Duration)
	end
	return BodyPosition
end

function CombatUtility:BGPlacer(parent,infoTable)

	local BodyGyro = Instance.new("BodyGyro")
	BodyGyro.Name = infoTable.Name or "BodyGyro"
	BodyGyro.MaxTorque = infoTable.MaxTorque or Vector3.new(1e7,1e7,1e7)
	BodyGyro.P = infoTable.P or 1200
	BodyGyro.CFrame = infoTable.CFrame

	BodyGyro.Parent = parent

	if infoTable.Duration then
		if infoTable.Ease then
			TweenService:Create(BodyGyro, TweenInfo.new(infoTable.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {P = 0}):Play();
		end;
		Debris:AddItem(BodyGyro,infoTable.Duration)
	end
	return BodyGyro
end

function CombatUtility:BAVPlacer(parent,infoTable)

	local BodyAngularVel = Instance.new("BodyAngularVelocity")
	BodyAngularVel.Name = infoTable.Name or "BodyAngularVel"
	BodyAngularVel.MaxTorque = infoTable.MaxTorque or Vector3.new(1e7,1e7,1e7)
	BodyAngularVel.P = infoTable.P or 1200
	BodyAngularVel.AngularVelocity = infoTable.AngularVelocity

	BodyAngularVel.Parent = parent

	if infoTable.Duration then
		if infoTable.Ease then
			TweenService:Create(BodyAngularVel, TweenInfo.new(infoTable.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {P = 0}):Play();
		end;
		Debris:AddItem(BodyAngularVel,infoTable.Duration)
	end
	return BodyAngularVel
end

function CombatUtility:getFarthestCharacter(part : BasePart,Table)
	local farthestDistance, farthestCharacter = 0, nil
	for _, Characters in ipairs(Table) do
		if not Characters.Parent then return end
		if not Characters:FindFirstChild("HumanoidRootPart") then return end
		local distance = (Characters.HumanoidRootPart.Position - part.Position).Magnitude
		if distance >= farthestDistance then
			farthestDistance = distance
			farthestCharacter = Characters
		end
	end
	return farthestDistance, farthestCharacter
end

function CombatUtility:RemoveBV(Parent, Whitelist)
	for i,v in pairs(Parent:GetChildren()) do 
		if v:IsA("BodyVelocity") then
			if v.Name ~= "NoRemove" and v.Name ~= Whitelist then
				v:Destroy()
			end
		end
	end
end

function CombatUtility:RemoveBP(Parent, Whitelist)
	for i,v in pairs(Parent:GetChildren()) do 
		if v:IsA("BodyPosition") then
			if v.Name ~= "NoRemove" and v.Name ~= Whitelist then
				v:Destroy()
			end
		end
	end
end

function CombatUtility:RemoveAllBodyForces(Parent, Whitelist)
	for i,v in pairs(Parent:GetChildren()) do 
		if v:IsA("BodyPosition") or v:IsA("BodyVelocity") then
			if v.Name ~= "NoRemove" and v.Name ~= Whitelist then
				v:Destroy()
			end
		end
	end
end

function CombatUtility:RotateTo(part, pos, duration)
	local BodyGyro = Instance.new("BodyGyro") 
	BodyGyro.MaxTorque = Vector3.new(5e4, 5e4, 5e4)
	BodyGyro.D = 100
	BodyGyro.P = 5e4
	BodyGyro.CFrame = CFrame.new(part.Position, pos)
	BodyGyro.Parent = part
	
	Debris:AddItem(BodyGyro, duration)
end

function CombatUtility:WallCollideCheck(Character,Duration)
	local RootPart = Character.HumanoidRootPart
	local Radius = 2
	local DURATION = tick() + Duration
	
	local rayconnection 
	
	rayconnection = RunService.Heartbeat:Connect(function()
		
		local velCF = CFrame.lookAt(RootPart.Position,RootPart.Position+RootPart.AssemblyLinearVelocity)
		local origin = Character.HumanoidRootPart.Position
		local dir =  velCF.LookVector*Radius
		local blacklistparams = {workspace.Entities,workspace.EffectsFolder,workspace.Effects,workspace.MockFolder}
		
		local testRay = Instance.new("Part")
		testRay.Parent = workspace
		testRay.Anchored = true
		testRay.CanCollide = false
		testRay.Color = Color3.fromRGB(134, 255, 120)
		testRay.Transparency = 0.6
		testRay.Size = Vector3.new(0.1, 0.1, Radius)

		game.Debris:AddItem(testRay,0.01)
		
		local BackRay = SharedFunctions.RayHit:Start(origin,dir,blacklistparams)
		
		if BackRay then
			testRay.Color = Color3.fromRGB(255, 0, 4)
			local distance = (origin - BackRay.Position).Magnitude
			testRay.Size = Vector3.new(0.1, 0.1, distance)
			testRay.CFrame = CFrame.lookAt(origin, BackRay.Position)*CFrame.new(0, 0, -distance/2)
			CombatUtility:RemoveAllBodyForces(RootPart)
			local HoldBP = Instance.new("BodyPosition")
			HoldBP.Name = "AirPusher"
			HoldBP.MaxForce = Vector3.new(1e9,1e9,1e9)
			HoldBP.Position = RootPart.Position
			HoldBP.P = 12000
			HoldBP.D = 750
			--	EnemyBP.P = 4e4
			HoldBP.Parent = RootPart
			game.Debris:AddItem(HoldBP, 0.8)
			rayconnection:Disconnect()
			
		else
			local distance = (origin - dir).Magnitude
			--				testRay.CFrame = CFrame.lookAt(originPos,dir) * CFrame.new(0,0,-Radius/2)
			testRay.CFrame = CFrame.lookAt(origin,origin+dir) * CFrame.new(0,0,-Radius/2)
		end
	end)
end

function CombatUtility:DownSlam(Entity,AttackerEntity,Type: string, DampenDuration)
	local RootPart = Entity.Character.Rig:FindFirstChild("HumanoidRootPart")
	local AttackerRoot = AttackerEntity.Character.Rig:FindFirstChild("HumanoidRootPart")
	if not RootPart then return end
	if not AttackerRoot then return end
	
	local AttackerCF = CombatUtility.ExtrapolateMovingCFrame(AttackerRoot)
	local RootCF = CombatUtility.ExtrapolateMovingCFrame(RootPart)

	local tvelocity = Instance.new("BodyVelocity",RootPart)
	tvelocity.MaxForce = Vector3.new(1,1,1)*1e6
	local TrueVelocity
	if Type == "Down" then
		TrueVelocity = Vector3.new(0,-120,0)
		tvelocity.Velocity = TrueVelocity

	elseif Type == "Custom" then
		TrueVelocity = AttackerCF
		tvelocity.Velocity = TrueVelocity
	else
		local angle = math.rad(45) -- e.g. 45 degrees
		local horizontalForce = 90 -- your multiplier for the push
		local verticalForce = -70 -- e.g. -70 like before

		local direction = AttackerCF.LookVector * math.cos(angle)
		TrueVelocity = direction * horizontalForce + Vector3.new(0, verticalForce, 0)
		tvelocity.Velocity = TrueVelocity
	end

	Entity.RunTime.BodyMovers["DownSlamVelo"] = {
		Instance        = tvelocity,
		Velocity        = TrueVelocity,
		--Duration        = Data.Duration,
		--Ease            = true,
		EaseStyle       = "Sine",
		ScaleOffRunTime = true,
		AntiGravity     = true,
		OnComplete      = function()
			-- BV:Destroy()
		end,
	}
	
	local state = false
	local rayResult = false
	local reflect = false

	Auxiliary.Shared.AnticipateSurface(Entity.Character.Rig, function(RaycastResult: RaycastResult,reflectionVector)
		tvelocity:Destroy()
		--[[
		CombatUtility:BVPlacer(RootPart,{
			Name = 'DampenVelocity',
			MaxForce = Vector3.new(math.huge,math.huge, math.huge),
			Velocity = Vector3.new(0,0,0),
			Duration = DampenDuration or 0.01
		})]]
		if reflectionVector and RaycastResult then
			local reflectvelocity = Instance.new("BodyVelocity")
			reflectvelocity.Parent = RootPart
			reflectvelocity.MaxForce = Vector3.new(1,1,1)*1e7
			reflectvelocity.P = 2000
			local reflectAngle = math.rad(-15) 
			local reflectDir = reflectionVector * math.cos(reflectAngle)
			reflectvelocity.Velocity = reflectDir * 50
			Debris:AddItem(reflectvelocity,0.2)
			rayResult = RaycastResult
			reflect = reflectionVector
		end
		state = "done"
	end,nil,nil,1,true,true);
	
	repeat task.wait() until state 
	return state, rayResult, reflect
end

function CombatUtility:DownSlamOLD(Character,AttackerChar,Type,DampenDuration)
	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	local AttackerRoot = AttackerChar:FindFirstChild("HumanoidRootPart")
	if not RootPart then return end
	if not AttackerRoot then return end

	local AttackerCF = CombatUtility.ExtrapolateMovingCFrame(AttackerRoot)
	local RootCF = CombatUtility.ExtrapolateMovingCFrame(RootPart)

	local tvelocity = Instance.new("BodyVelocity",RootPart)
	tvelocity.MaxForce = Vector3.new(1,1,1)*1e6
	if Type == "Down" then
		tvelocity.Velocity = Vector3.new(0,-120,0)

	elseif Type == "Custom" then
		tvelocity.Velocity = AttackerCF
	else
		local angle = math.rad(45) -- e.g. 45 degrees
		local horizontalForce = 90 -- your multiplier for the push
		local verticalForce = -70 -- e.g. -70 like before

		-- Calculate direction only using an angle
		local direction = AttackerCF.LookVector * math.cos(angle)
		--	+ AttackerCF.RightVector * math.sin(angle)

		-- Apply velocity
		tvelocity.Velocity = direction * horizontalForce + Vector3.new(0, verticalForce, 0)
	end

	--	tvelocity.Velocity = CFrame.new(RootPart.Position,Vector3.new(RootPart.Position.X,RootPart.Position.Y,RootPart.Position.Z)).LookVector * 45 + Vector3.new(0,-100,0)

	local rayconnection
	local Finished = false
	local slammed = false

	local ticker = tick()
--[[
	if Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Character.Humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding or Character.Humanoid:GetState() == Enum.HumanoidStateType.Jumping then
		local CurrentState = Character.Humanoid:GetState()
		local state
		repeat
			state = Character.Humanoid:GetState()
			RunService.Heartbeat:Wait()
		until
		state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Dead or tick() - ticker >= 0.7
	end
	]]
	local function detectGroundImpact()
		-- Cast a ray downward
		local rayDirection = Vector3.new(0, -1, 0) * 5 -- Adjust distance as needed

		local rayResult = workspace:Raycast(RootPart.Position, rayDirection, Auxiliary.Shared.RayParams.Map)

		if rayResult then
			print("Player has hit the ground!")
			return true
		else return false
		end
	end

	local impactCheckConnection
	impactCheckConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if detectGroundImpact() then
			-- Disconnect the impact check once the ground is hit
			impactCheckConnection:Disconnect()
			Finished = true
			slammed = true
		elseif tick() - ticker >= 1 then
			impactCheckConnection:Disconnect()
			Finished = true
		end
	end)

	repeat task.wait() until Finished
	tvelocity:Destroy()
	RootPart.Velocity = Vector3.new()
	CombatUtility:BVPlacer(RootPart,{
		Name = 'DampenVelocity',
		MaxForce = Vector3.new(math.huge,math.huge, math.huge),
		Velocity = Vector3.new(0,0,0),
		Duration = DampenDuration or 0.1
	})

	return slammed
end

function CombatUtility:AngledCrash(Character,Type,DampenDuration)
	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	if not RootPart then return end
	local tvelocity = Instance.new("BodyVelocity",RootPart)
	tvelocity.MaxForce = Vector3.new(1,1,1)*5e6
	if Type == "Down" then
		tvelocity.Velocity = RootPart.CFrame.UpVector * -100
	else
		tvelocity.Velocity = RootPart.CFrame.LookVector * 140 + Vector3.new(0,-85,0)
	end

	--	tvelocity.Velocity = CFrame.new(RootPart.Position,Vector3.new(RootPart.Position.X,RootPart.Position.Y,RootPart.Position.Z)).LookVector * 45 + Vector3.new(0,-100,0)

	local rayconnection
	local Finished = false
	local slammed = false

	local ticker = tick()

	local function detectGroundImpact()
		-- Cast a ray downward
		local rayDirection = Vector3.new(0, -1, 0) * 4.5 -- Adjust distance as needed
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {workspace.Map}
		rayParams.FilterType = Enum.RaycastFilterType.Include

		local rayResult = workspace:Raycast(RootPart.Position, rayDirection, rayParams)

		if rayResult then
			print("Player has hit the ground!")
			return true
		else return false
		end
	end

	local impactCheckConnection
	impactCheckConnection = game:GetService("RunService").Heartbeat:Connect(function()
		if detectGroundImpact() then
			-- Disconnect the impact check once the ground is hit
			impactCheckConnection:Disconnect()
			Finished = true
			slammed = true
		elseif tick() - ticker >= 1.5 then
			impactCheckConnection:Disconnect()
			Finished = true
		end
	end)

	repeat task.wait() until Finished
	tvelocity:Destroy()
	RootPart.Velocity = Vector3.new()
	
	CombatUtility:BVPlacer(RootPart,{
		Name = 'DampenVelocity',
		MaxForce = Vector3.new(math.huge,math.huge, math.huge),
		Velocity = Vector3.new(0,0,0),
		Duration = DampenDuration or 0.1
	})

	return slammed
end

function CombatUtility:isCharBehind(victimRootPart, HitterRootPart)

	local displacementVector: Vector3 = victimRootPart.Position - HitterRootPart.Position
	local direction: Vector3 = displacementVector.Unit
	local character1LV: Vector3 = victimRootPart.CFrame.LookVector

	local angle: number = math.acos(character1LV:Dot(direction))
	
	if angle >= math.rad(90) then
		return true
	else
		return false
	end
end

function CombatUtility:CharacterVisible(character,enable)
	for _, Part in pairs(character:GetDescendants()) do
		if Part:IsA("BasePart") or Part:IsA("MeshPart") or Part:IsA("Decal") then
			if Part.Name == "HumanoidRootPart" or Part.Name == "Collide" or Part.Name == "Head" or Part.Name == "BasePart" then continue end
			if Part:GetAttribute("IgnoreInvisible") == true then continue end
			if enable then
				Part.Transparency = 1
			else
				Part.Transparency = 0
			end
		end
	end
end

function CombatUtility:TweenCharacterVisibility(character, duration,value)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Decal") then
			if part.Name == "HumanoidRootPart" or part.Name == "Collide" then continue end
			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			local goal = {Transparency = value}

			-- Special handling for Decals
			if part:IsA("Decal") then
				goal = {Transparency = value}
			end

			local tween = TweenService:Create(part, tweenInfo, goal)
			tween:Play()
		end
	end
end

function CombatUtility.ExtrapolateMovingCFrame(Part: BasePart, UnitDirection: Vector3?, Rate: number): CFrame
	local LinearVel = Part.AssemblyLinearVelocity

	local LinearExtrapVel = Vector3.new(LinearVel.X, LinearVel.Y / 2, LinearVel.Z) / 4
	local Decay = (1 + (0.185 * LinearExtrapVel.Magnitude)^8)

	local ApplyDecay = function(Axis: number)
		return (math.abs(Axis / Decay) > math.abs(Axis / 2) and (Axis / Decay) or (Axis / 2))
	end

	local BaseCFrame
	if UnitDirection then
		local Pos = Part.CFrame.Position
		BaseCFrame = CFrame.new(Pos, Pos + UnitDirection)
	else
		BaseCFrame = Part.CFrame
	end

	return BaseCFrame + Vector3.new(
		ApplyDecay(LinearExtrapVel.X),
		LinearExtrapVel.Y,
		ApplyDecay(LinearExtrapVel.Z)
	) * (Rate or 1), LinearVel.Magnitude
end

return CombatUtility
