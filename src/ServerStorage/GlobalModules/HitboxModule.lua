local HitboxModule = {}

--local Server = require(script.Parent)
--local Utilities = Server.Utilities
local HTTPService = game:GetService('HttpService')
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function HitboxModule.Hitboxer(Character,ToolName,FunctionName,Size,cframe,Utilities)
	local Player = Players:GetPlayerFromCharacter(Character)
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

	local overlapParams = OverlapParams.new()
	local DetectionArea = workspace:GetPartBoundsInBox(cframe,Vector3.new(4.6, 5.8, 6.15),overlapParams)
	Utilities.RegionVisual(Size,cframe)
	local Attacked = {}
	for _,Object in pairs(DetectionArea) do -- loops through the items that are currently in the hitbox

		if Object:IsA("BasePart") and Object.Parent and Object.Parent ~= Character then
			if Object.Parent:FindFirstChild("Humanoid") and Object.Parent:FindFirstChild("Humanoid").Health > 0 then
				local EnemyHumanoid = Object.Parent:FindFirstChild("Humanoid")
				if not Attacked[table.find(Attacked,Object.Parent)] then
					table.insert(Attacked,Object.Parent)
				end	
				coroutine.wrap(function()
					task.wait(.15)
					for i =1 , #Attacked do
						if Attacked[i] == Object.Parent then
							table.remove(Attacked,i)
						end
					end
				end)()

				if EnemyHumanoid.Parent:FindFirstChild("Choosing") then return end
				if EnemyHumanoid.Parent:FindFirstChild("Choosing") == nil then
					Utilities.AddValue("BoolValue", "Choosing", false, Character, .35)

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

function HitboxModule.BasicHitbox(Character,HitboxTable,Size,cframe,duration)

	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	
	if HitboxTable == nil then 
		HitboxTable = {}
	end
	local HitFunction

	local Attacked = {}
--	HitFunction = RunService.Heartbeat:Connect(function()
		local HitboxSize = HitboxTable.Size or Vector3.new(6, 5, 7)
		local HitboxCFrame = HitboxTable.CFrame or RootPart.CFrame*CFrame.new(0,0,-3.3)

	--	Utilities.RegionVisual(HitboxSize,HitboxCFrame)

		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = HitboxTable.IgnoreTable or {}

		local DetectionArea = workspace:GetPartBoundsInBox(HitboxCFrame,HitboxSize,overlapParams)

		for _,object in pairs(DetectionArea) do
			if object:IsA("BasePart") and object.Parent then
				if object.Parent:FindFirstChild("Humanoid") and object.Parent:FindFirstChild("Humanoid").Health > 0 then
					if not Attacked[table.find(Attacked,object.Parent)] then 
						table.insert(Attacked,object.Parent)
					end

					task.spawn(function()
						task.wait(0.1)
						for i = 1 , #Attacked do
							if Attacked[i] == object.Parent then
								table.remove(Attacked,i)
							end
						end
						
					end)

					local EnemyHumanoid = object.Parent:FindFirstChild("Humanoid")

				end
			end
		end	
--	end)

--	task.wait(HitboxTable.Duration or 0.05)
--	HitFunction:Disconnect()

	return Attacked
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
		overlapParams.FilterDescendantsInstances = {workspace.DebrisFolder,Character}

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