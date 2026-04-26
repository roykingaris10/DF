local EmitParticle = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Debris = require(ReplicatedStorage.Kits.Nodes.Utility.Debris)

function EmitParticle:Emit(Effect,Divider,Ignore)
	for _, Emitter in ipairs(Effect:GetDescendants()) do
		if Emitter:IsA('ParticleEmitter') then
			local Divider = Divider or 1
			local EmitCount = Emitter:GetAttribute('EmitCount') or 1
			local EmitRepeat = Emitter:GetAttribute('EmitRepeat') or 1
			local EmitDelay = Emitter:GetAttribute('EmitDelay') or 0

			coroutine.wrap(function()
				for _ = 1, EmitRepeat do
					local Ignore = Emitter.Name == Ignore
					--print("PArticleIsIgnoreInit",Ignore)
					
					if not Ignore then
						--print("not playin dat particle!!",Emitter)
						Emitter:Emit(math.ceil(EmitCount / Divider))
					end
					task.wait(EmitDelay)
				end
			end)()
		end
	end
end

function EmitParticle:ToneDown(Decendents)

	local VFX = Decendents:GetDescendants()
	for _, v in ipairs(VFX) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
		end

		for _, v in ipairs(VFX) do
			if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
				local goal = {}
				goal.Brightness = 0
				game.TweenService:Create(v,TweenInfo.new(.5),goal):Play()
			end
		end

	end

	for _, v in ipairs(VFX) do
		if v:IsA("Beam") then
			v.Enabled = false
		end
	end
	
	for _, v in ipairs(VFX) do
		if v:IsA("Trail") then
			v.Enabled = false
		end
	end

end

function EmitParticle:TurnOffLights(Effect)
	for _, v in ipairs(Effect:GetDescendants()) do
		if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
			local goal = {}
			goal.Brightness = 0
			game.TweenService:Create(v,TweenInfo.new(.5),goal):Play()
		end
	end
end

function EmitParticle:EnableParticle(Effect,State)
	for _, Emitter in ipairs(Effect:GetDescendants()) do
		if Emitter:IsA('ParticleEmitter') or Emitter:IsA("Beam") then
			Emitter.Enabled = State
		end
	end
end

function EmitParticle:TurnOn(Effect)
	EmitParticle:EnableParticle(Effect,true)
end
function EmitParticle:TurnOff(Effect)
	EmitParticle:EnableParticle(Effect,false)
end

local function GetLifetime(ParticleObject)
	local Lifetime = 0
	if ParticleObject:IsA("ParticleEmitter") then
		local EmitDelay = ParticleObject:GetAttribute("EmitDelay") or 0
		local EmitDuration = ParticleObject:GetAttribute("EmitDuration") or 0
		local TotalTime = EmitDelay + EmitDuration + ParticleObject.Lifetime.Max

		Lifetime = TotalTime
	else
		for i, v in ipairs(ParticleObject:GetDescendants()) do
			if v:IsA("ParticleEmitter") then
				local EmitDelay = v:GetAttribute("EmitDelay") or 0
				local EmitDuration = v:GetAttribute("EmitDuration") or 0
				local TotalTime = EmitDelay + EmitDuration + v.Lifetime.Max

				if TotalTime > Lifetime then
					Lifetime = TotalTime
				end
			end
		end
	end
	return Lifetime
end

function EmitParticle:BodyParticlesClean(Character)

	local VFX = Character:GetDescendants()
	for _, v in ipairs(VFX) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
			game.Debris:AddItem(v,2)

		end
	end

end

function EmitParticle:Enable(Part, Enabled, NoAutoClean)
	local Instances = Part:GetDescendants()
	table.insert(Instances, Part)

	for _, v in Instances do
		if v:IsA("Beam") or v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Enabled = Enabled
		end
	end

	if not Enabled and not NoAutoClean then
		Debris:AddItem(Part, GetLifetime(Part))
	end
end

function EmitParticle:PositionAtGround(Character, OriginPart, Part, Offset)
	local RayParams = RaycastParams.new()
	RayParams.FilterDescendantsInstances = {workspace.Map}
	RayParams.FilterType = Enum.RaycastFilterType.Include

	local Origin = Character[OriginPart].Position
	local Direction = Vector3.new(0,-6, 0)

	local RaycastResult = workspace:Raycast(Origin, Direction, RayParams)

	if RaycastResult then
		Part.Position = Offset and RaycastResult.Position + Offset or RaycastResult.Position
	else
		Part.Position = Character.HumanoidRootPart.Position + Vector3.new(0, -4, 0)
	end
end

function EmitParticle:Clone(Character,Color,Clones,Time)
	coroutine.wrap(function()
		task.wait(.2)
		for i = 1,Clones do
			
			task.wait(Time)
			
			for _,v in ipairs(Character:GetChildren()) do
				if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart"  then
					local ShocksIce = v:Clone()
					ShocksIce:ClearAllChildren()
					ShocksIce.Anchored = true
					ShocksIce.CanCollide = false
					ShocksIce.Parent = workspace.EffectsFolder
					ShocksIce.Material = "Neon"
					ShocksIce.Color = Color
					ShocksIce.Transparency = .7
					
					local Goal = {}
					Goal.Transparency = 1
					Goal.Size = ShocksIce.Size + Vector3.new(0.2, 0.2, 0.2)
					game.TweenService:Create(ShocksIce, TweenInfo.new(.5),Goal):Play()
					game.Debris:AddItem(ShocksIce,.5)
				end		
			end
			
		end
	end)()
end

function EmitParticle:randomWithNegatives(...)
	local numbers = {...}
	local options = {}

	for _, num in ipairs(numbers) do
		table.insert(options, num)
		table.insert(options, -num)
	end

	for i = #options, 2, -1 do
		local j = math.random(i)
		options[i], options[j] = options[j], options[i]
	end

	return options[math.random(#options)]
end

function EmitParticle:DisableAll(Parent)
	for _, v in Parent:GetDescendants() do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
			v.Enabled = false
		elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
			TweenService:Create(v, TweenInfo.new(.5), {Brightness = 0}):Play()
		end
	end
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

function EmitParticle:TweenScaleModel(model: Model, targetScale: number, duration: number)
	assert(model and model:IsA("Model"), "Model is required")
	assert(type(targetScale) == "number" and targetScale > 0, "Target scale must be a positive number")

	local startScale = model:GetScale()
	local elapsed = 0
	local heartbeat = RunService.Heartbeat

	task.spawn(function()
		while elapsed < duration do
			local dt = heartbeat:Wait()
			elapsed += dt
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local currentScale = lerp(startScale, targetScale, alpha)
			model:ScaleTo(currentScale)
		end	
		model:ScaleTo(targetScale)
	end)
end

return EmitParticle