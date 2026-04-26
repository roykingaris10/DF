
local RunService = game:GetService('RunService')

local Player = game.Players.LocalPlayer
local Character = Player.Character
local Humanoid = Character:WaitForChild('Humanoid')
local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
local Torso = Character:WaitForChild('Torso')

-- Original C0 Reference

local RootJointOriginalC0 = HumanoidRootPart.RootJoint.C0
local NeckOriginalC0 = Torso.Neck.C0
local RightHipOriginalC0 = Torso['Right Hip'].C0
local LeftHipOriginalC0 = Torso['Left Hip'].C0
local PlayersTable = {}

--Customizable Settings

local RangeOfMotion = 35
local RangeOfMotionTorso = 70 - RangeOfMotion
local RangeOfMotionXZ = RangeOfMotion/140
local LerpSpeed = 0.004

--Main Code

RangeOfMotion = math.rad(RangeOfMotion)
RangeOfMotionTorso = math.rad(RangeOfMotionTorso)

function CheckCombatValues(Character,checkTable)
	local ValueCheck = false
	for i,value in pairs(checkTable) do
		if Character:GetAttribute(value) then
			ValueCheck = true
			
		end
	end

	if ValueCheck == true then
		return true
	else
		return false
	end
end

local checkTable = {"Ragdoll","Stunned","Dashing","NoMovement","ClientActive","Active","CurrentlyAttacking","HitShake"}

function Calculate( dt, HumanoidRootPart, Humanoid, Torso )
	if not HumanoidRootPart.Parent then return end
--	if CheckCombatValues(HumanoidRootPart.Parent,checkTable) then print("RANGEDAAA") RangeOfMotion = math.rad(0) RangeOfMotionTorso = math.rad(0) end
	local DirectionOfMovement = HumanoidRootPart.CFrame:VectorToObjectSpace( HumanoidRootPart.AssemblyLinearVelocity )
	DirectionOfMovement = Vector3.new( DirectionOfMovement.X / Humanoid.WalkSpeed, 0, DirectionOfMovement.Z / Humanoid.WalkSpeed )

	local XResult = ( DirectionOfMovement.X * (RangeOfMotion - (math.abs( DirectionOfMovement.Z ) * (RangeOfMotion / 2) ) ) )
	local XResultTorso = ( DirectionOfMovement.X * (RangeOfMotionTorso - (math.abs( DirectionOfMovement.Z ) * (RangeOfMotionTorso / 2) ) ) )
	local XResultXZ = ( DirectionOfMovement.X * (RangeOfMotionXZ - (math.abs( DirectionOfMovement.Z ) * (RangeOfMotionXZ / 2) ) ) )

	if DirectionOfMovement.Z > 0.1 then
		XResult *= -1
		XResultTorso *= -1
		XResultXZ *= -1
	end

	local RightHipResult = RightHipOriginalC0 * CFrame.new(-XResultXZ, 0, -math.abs(XResultXZ) + math.abs( -XResultXZ ) ) * CFrame.Angles( 0, -XResult, 0 )
	local LeftHipResult = LeftHipOriginalC0 * CFrame.new(-XResultXZ, 0, -math.abs(-XResultXZ) + math.abs( -XResultXZ ) ) * CFrame.Angles( 0, -XResult, 0 )
	local RootJointResult = RootJointOriginalC0 * CFrame.Angles( 0, 0, -XResultTorso )
	local NeckResult = NeckOriginalC0 * CFrame.Angles( 0, 0, XResultTorso )

	local LerpTime = 1 - LerpSpeed ^ dt
	if CheckCombatValues(HumanoidRootPart.Parent,checkTable) == true then
		Torso['Right Hip'].C0 = RightHipOriginalC0
		Torso['Left Hip'].C0 = LeftHipOriginalC0
--		HumanoidRootPart.RootJoint.C0 = RootJointOriginalC0
		Torso.Neck.C0 = NeckOriginalC0
	else
		Torso['Right Hip'].C0 = Torso['Right Hip'].C0:Lerp(RightHipResult, LerpTime)
		Torso['Left Hip'].C0 = Torso['Left Hip'].C0:Lerp(LeftHipResult, LerpTime)
		HumanoidRootPart.RootJoint.C0 = HumanoidRootPart.RootJoint.C0:Lerp(RootJointResult, LerpTime)
		Torso.Neck.C0 = Torso.Neck.C0:Lerp(NeckResult, LerpTime)
	end
end

RunService.RenderStepped:Connect(function(dt)
	for _, Player in game.Players:GetPlayers() do
		if Player.Character == nil then continue end
		if table.find( PlayersTable, Player ) then continue end
		table.insert(PlayersTable, Player)
	end

	for i, Player in pairs(PlayersTable) do

		if Player == nil then
			table.remove( PlayersTable, i )
			continue
		end

		if game.Players:FindFirstChild(Player.Name) == nil then
			table.remove( PlayersTable, i )
			continue
		end

		if Player.Character == nil then
			table.remove( PlayersTable, i )
			continue
		end

		local HumanoidRootPart = Player.Character:FindFirstChild('HumanoidRootPart')
		local Humanoid = Player.Character:FindFirstChild('Humanoid')
		local Torso = Player.Character:FindFirstChild('Torso')

		if HumanoidRootPart == nil or Humanoid == nil or Torso == nil then
			continue
		end

		Calculate(dt, HumanoidRootPart, Humanoid, Torso)

	end

end)