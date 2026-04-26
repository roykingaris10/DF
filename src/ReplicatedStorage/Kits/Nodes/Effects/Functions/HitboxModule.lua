local HitboxModule = {}

local HTTPService = game:GetService('HttpService')
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

function HitboxModule.BasicHitbox(Character,Object,cframe,Size,filter,Utilities)

	local Player = Players:GetPlayerFromCharacter(Character)
	local RootPart = Character:FindFirstChild("HumanoidRootPart")

		local Attacked = {}
		
		--Utilities.RegionVisual(Size,Object.CFrame * cframe)
		
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
			overlapParams.FilterDescendantsInstances = {filter}
			
		local DetectionArea = workspace:GetPartBoundsInBox(Object.CFrame * cframe,Size,overlapParams)

		for _,object in pairs(DetectionArea) do
				if object:IsA("BasePart") and object.Parent then
					if object.Parent:FindFirstChild("Humanoid") and object.Parent:FindFirstChild("Humanoid").Health > 0 then
						if not Attacked[table.find(Attacked,object.Parent)] then 
							table.insert(Attacked,object.Parent)
					end
					end
				end
			end	
	
		if #Attacked == 0 then
				return false
			else 
				return true, Attacked
		end
end

function HitboxModule.CircularBasicHitbox(Character,Object,cframe,radius,filter,Utilities)

	local Player = Players:GetPlayerFromCharacter(Character)
	local RootPart = Character:FindFirstChild("HumanoidRootPart")

	local Attacked = {}

	--Utilities.RegionVisual(Size,Object.CFrame * cframe)
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {filter}
	
	 --VISUALIZER
	--local sphereCast = ReplicatedStorage.spherecast:Clone()
	--sphereCast.Parent = workspace.EffectsFolder
	--sphereCast.CFrame = Character:FindFirstChild("HumanoidRootPart").CFrame
	--sphereCast.Size = Vector3.new(1,1,1)*(radius*2)
	--Debris:AddItem(sphereCast,0.015)

	local DetectionArea = workspace:GetPartBoundsInRadius((Object.CFrame * cframe).Position, radius,overlapParams)

	for _,object in pairs(DetectionArea) do
		if object:IsA("BasePart") and object.Parent then
			if object.Parent:FindFirstChild("Humanoid") and object.Parent:FindFirstChild("Humanoid").Health > 0 then
				if not Attacked[table.find(Attacked,object.Parent)] then 
					table.insert(Attacked,object.Parent)
				end
			end
		end
	end	

	if #Attacked == 0 then
		return false
	else 
		return true, Attacked
	end
end

function HitboxModule.BallDetectHitbox(Character,Object,cframe,radius,filter,Utilities)

	local Player = Players:GetPlayerFromCharacter(Character)
	local RootPart = Character:FindFirstChild("HumanoidRootPart")

	local Attacked = {}

	--Utilities.RegionVisual(Size,Object.CFrame * cframe)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {filter}

	--VISUALIZER
	--local sphereCast = ReplicatedStorage.spherecast:Clone()
	--sphereCast.Parent = workspace.EffectsFolder
	--sphereCast.CFrame = Character:FindFirstChild("HumanoidRootPart").CFrame
	--sphereCast.Size = Vector3.new(1,1,1)*(radius*2)
	--Debris:AddItem(sphereCast,0.015)

	local DetectionArea = workspace:GetPartBoundsInRadius((Object.CFrame * cframe).Position, radius,overlapParams)

	for _,object in pairs(DetectionArea) do
		if object:IsA("BasePart") and object.Parent then
			if CollectionService:HasTag(object, "ActiveBall") then
				if not Attacked[table.find(Attacked, object)] then
					table.insert(Attacked, object)
				end
			end
		end
	end	

	if #Attacked == 0 then
		return false
	else 
		return true, Attacked
	end
end

function HitboxModule.SingleTargetHitbox(Character,HeirName,FunctionName,Size,cframe,duration,hitNum,Utilities)
	--4, 4.5, 3
	local Player = Players:GetPlayerFromCharacter(Character)
	local RootPart = Character:FindFirstChild("HumanoidRootPart")

	local HitFunction

	local Attacked = {}
	HitFunction = RunService.Heartbeat:Connect(function()
		local HitboxSize = Size
		local HitboxCFrame = cframe

		Utilities.RegionVisual(HitboxSize,HitboxCFrame)

		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {workspace.EffectsFolder,Character}

		local DetectionArea = workspace:GetPartBoundsInBox(HitboxCFrame,HitboxSize,overlapParams)

		for _,object in pairs(DetectionArea) do
			if object:IsA("BasePart") and object.Parent then
				if object.Parent:FindFirstChild("Humanoid") and object.Parent:FindFirstChild("Humanoid").Health > 0 then
					if not Attacked[table.find(Attacked,object.Parent)] then 
						table.insert(Attacked,object.Parent)
					end

					coroutine.wrap(function()
						task.wait(.3)
						for i = 1 , #Attacked do
							if Attacked[i] == object.Parent then
								table.remove(Attacked,i)
							end
						end
					end)()

					local EnemyHumanoid = object.Parent:FindFirstChild("Humanoid")

				end
			end
		end	
	end)

	task.wait(duration)
	HitFunction:Disconnect()
	if #Attacked == 0 then
		return false
	else 
		return true, Attacked
	end
end

return HitboxModule