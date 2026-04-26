local Utilities = {}


local HTTPService = game:GetService('HttpService')
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CombatData = workspace.CombatData

_G.CheckMove = function(MoveName)
	return true
end

_G.Debris = function(Item,Duration)
	coroutine.resume(coroutine.create(function()
		wait(Duration)
		Item:Destroy()
	end))
end;

function Utilities.destroy(object, duration)
	task.spawn(function()
		task.wait(duration)
		object:Destroy()
	end)	
end

function Utilities.removeDupes(tabler)
	local newTable = {}
	for _, value in ipairs(tabler) do
		if not table.find(newTable,value) then
			table.insert(newTable,value)
		end
	end
	return newTable
end

function Utilities.Create(instanceType)
	return function(data)
		local obj = Instance.new(instanceType)
		for i, v in pairs(data) do
			local success = pcall(function()
				if type(i) == 'number' then
					v.Parent = obj
				elseif type(v) == 'function' then
					obj[i]:Connect(v)
				else
					obj[i] = v
				end
			end)
			if not success then
				error('Could not create')
			end
		end
		return obj
	end
end

function Utilities.TweenValue(Start, Time, End, Object)
	local NumValue = Instance.new('NumberValue')
	NumValue.Value = Start
	TweenService:Create(NumValue, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = End}):Play()
	game:GetService('Debris'):AddItem(NumValue, Time)

	if Object then
		NumValue.Changed:Connect(function(New)
			Object.Size = NumberSequence.new(New)
		end)
	end

	return NumValue
end

function Utilities.ToClockTime(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return string.format("%02i", Minutes)..":"..string.format("%02i", Seconds)
end

function Utilities.Shuffle(Table, numOfShuffles)
	for i = 1, numOfShuffles do
		local j = math.random(#Table)
		Table[i], Table[j] = Table[j], Table[i]
	end
	return Table
end 

function Utilities.guid() 
	return HTTPService:GenerateGUID()
end

function Utilities.IgnoreYCFrame(origin, lookat) 
	return CFrame.new(origin, Vector3.new(lookat.X, origin.Y, lookat.Z))
end

function  Utilities.len(dict)
	local counter = 0 
	for _, v in pairs(dict) do
		counter = counter + 1
	end
	return counter
end

function Utilities.TagAdd(storeTable: {}, Character, TagName: string, Value: any, Type: string, Duration: any)
	local CombatFolder = CombatData:FindFirstChild(Character.Name)
	if not CombatFolder then return false end

	local TagObj = Instance.new(Type or "Folder")
	TagObj.Name = TagName
	TagObj.Parent = CombatFolder

	if Value then
		TagObj.Value = Value
	end

	if Duration then
		Debris:AddItem(TagObj, Duration)
	end
	
	if storeTable then
		table.insert(storeTable, TagObj)
	end

	return TagObj
end

function Utilities.ClearTable(storeTable:{})
	for i,v in pairs(storeTable) do
		if v.Parent then
			v:Destroy()
		end
	end
	storeTable = nil
end

function Utilities.CheckTags(tagTable:{},Character)
	local CombatFolder = CombatData:FindFirstChild(Character.Name)
	if not CombatFolder then return false end
	local found = false
	for i,tagName in pairs(tagTable) do
		if CombatFolder:FindFirstChild(tagName) then
			found = true
			break
		end
	end
	return found
end

function Utilities.ExtrapolateMovingCFrame(Part: BasePart, UnitDirection: Vector3?, Rate: number): CFrame
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

function Utilities.Raycast(Origin: Vector3?,Direction: Vector3?,Range: number, RayParams:RaycastParams)
	local Raycast = workspace:Raycast(Origin,Direction * Range,RayParams)
	if Raycast then
		return Raycast
	else
		return nil
	end
end

return Utilities
