
-- Ragdoll Module
local Ragdoll = {}

local RagdollData = require(script.RagdollData)

local attachmentCFrames = {
	["Neck"] = {CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},
	["Left Shoulder"] = {CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1), CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1)},
	["Right Shoulder"] = {CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	["Left Hip"] = {CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
	["Right Hip"] = {CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
}

local ragdollInstanceNames = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

--//Module
local Ragdoll = {};

local function createColliderPart(part: BasePart, Entity: {any})
	if not part then return end
	local rp = Instance.new("Part")
	rp.Name = "ColliderPart"
	rp.Size = part.Size*.7;
	rp.Massless = true			
	rp.CFrame = part.CFrame
	rp.Transparency = 1
	rp.CollisionGroup = (Entity.Character._CanCollide and 'Ragdoll') or 'Nothing';

	local wc = Instance.new("WeldConstraint")
	wc.Part0 = rp
	wc.Part1 = part

	wc.Parent = rp
	rp.Parent = part

	if Entity.Player then
		rp:SetNetworkOwner(Entity.Player);
	end;
end

function Ragdoll:replaceJoints(Character: Model, Entity: {any})
	if not Character or not Character:IsDescendantOf(workspace.Entities) then return end;

	local Humanoid = Character:FindFirstChildOfClass('Humanoid');
	local HRP = Character:FindFirstChild('HumanoidRootPart');

	for _, motor: Motor6D in pairs(Character:GetDescendants()) do
		if motor:IsA("Motor6D") then
			if not attachmentCFrames[motor.Name] then return end
			motor.Enabled = false;
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.CFrame = attachmentCFrames[motor.Name][1]
			a1.CFrame = attachmentCFrames[motor.Name][2]

			a0.Name = "RagdollAttachment"
			a1.Name = "RagdollAttachment"

		--	createColliderPart(motor.Part1, Entity)
		--	motor.Part1.CollisionGroup = 'Ragdoll';

			local b = Instance.new("BallSocketConstraint")
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Name = "RagdollConstraint"

			b.LimitsEnabled = true
			b.TwistLimitsEnabled = false
			b.MaxFrictionTorque = 0
			b.Restitution = 0.2
			b.UpperAngle = 45
			b.TwistLowerAngle = -45
			b.TwistUpperAngle = 45

			if motor.Name == "Neck" then
				b.TwistLimitsEnabled = true
				b.TwistLowerAngle = -45
				b.TwistUpperAngle = 45
			end

			a0.Parent = motor.Part0
			a1.Parent = motor.Part1
			b.Parent = motor.Parent
		end
	end

	Humanoid.AutoRotate = false --> Disabling AutoRotate prevents the Character rotating in first person or Shift-Lock
end

function Ragdoll:resetJoints(Character: Model)
	if not Character or not Character:IsDescendantOf(workspace.Entities) then return end;

	local Humanoid = Character:FindFirstChildOfClass('Humanoid');
	local HRP = Character:FindFirstChild('HumanoidRootPart');

	if Humanoid.Health < 1 then return end
	for _, instance in pairs(Character:GetDescendants()) do
		if ragdollInstanceNames[instance.Name] then
			instance:Destroy()
		end

		if instance:IsA("Motor6D") then
			instance.Enabled = true;
		end

		if instance:IsA('BasePart') then
			instance.CollisionGroup = 'Characters';
		end
	end

	Humanoid.AutoRotate = true
end;


function Ragdoll:BuildCollisionParts(user: Character)
	for _,v in pairs(user:GetChildren()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			local p = v:Clone()
			p.Parent = v
			p.CanCollide = false
			p.Massless = true
			p.Size = Vector3.one
			p.Name = "Collide"
			p.Transparency = 1
			p.CollisionGroup = "RagParts"
			p:ClearAllChildren()
			
			local weld = Instance.new("Weld")
			weld.Parent = p
			weld.Part0 = v
			weld.Part1 = p
		end
	end
end

function Ragdoll:EnableMotor6D(user: Character, enabled: boolean)
	for _,v in pairs(user:GetDescendants()) do
		
		if v.Name == "Handle" or v.Name == "RootJoint" or v.Name == "Neck" or v.Name == "HandMotor" or v.Name == "HandleWeld" then continue end
		
		if v:IsA("Motor6D") then v.Enabled = enabled end
	--	if v:IsA("BasePart") then v.CollisionGroup = if enabled then user else "Ragdoll" end
	end
end

function Ragdoll:BuildJoints(user: Character)
	local RootPart = user:FindFirstChild("HumanoidRootPart")
	
	for _,v in pairs(user:GetDescendants()) do
		if not v:IsA("BasePart") or v:FindFirstAncestorOfClass("Accessory") or v.Name == "Handle" or v.Name == "Torso" or v.Name == "HumanoidRootPart" then continue end
		
		if not RagdollData[v.Name] then continue end
		
		local a0: Attachment, a1: Attachment = Instance.new("Attachment"), Instance.new("Attachment")
		local joint: Constraint = script.SocketFolder:FindFirstChild(RagdollData[v.Name].Joint):Clone()
		
		a0.Name = "RAGDOLL_ATTACHMENT"
		a0.Parent = v
		a0.CFrame = RagdollData[v.Name].CFrame[2]
		
		a1.Name = "RAGDOLL_ATTACHMENT"
		a1.Parent = RootPart
		a1.CFrame = RagdollData[v.Name].CFrame[1]
		
		joint.Name = "RAGDOLL_CONSTRAINT"
		joint.Parent = v
		joint.Attachment0 = a0
		joint.Attachment1 = a1
		
		v.Massless = true
	end
end

function Ragdoll:DestroyJoints(user: Character)
	user.HumanoidRootPart.Massless = false
	
	for _,v in pairs(user:GetDescendants()) do
		if v.Name == "RAGDOLL_ATTACHMENT" or v.Name == "RAGDOLL_CONSTRAINT" then v:Destroy() end
		if not v:IsA("BasePart") or v:FindFirstAncestorOfClass("Accessory") or v.Name == "Torso" or v.Name == "Head" then continue end
	end
end

function Ragdoll:EnableCollisionParts(user: Character, enabled: boolean)
	for _,v in pairs(user:GetChildren()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.CanCollide = not enabled
			v.Collide.CanCollide = enabled
		end
	end
end


return Ragdoll
