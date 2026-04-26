local Explosion = {}

local DB = game:GetService("Debris")
local TS = game:GetService("TweenService")

function Explosion.new(ExplodeInfo)

	local CF = ExplodeInfo.CF
	local Size = ExplodeInfo.Size or 15
	local Count = ExplodeInfo.Count or math.random(4,6)
	local explodeColor = ExplodeInfo.Color or Color3.fromRGB(255, 97, 35)
	local explodeColor2 = ExplodeInfo.Color2 or Color3.fromRGB(83, 83, 83)
	local maxRadius = ExplodeInfo.Radius or 3
	local NeonState = ExplodeInfo.Neon or true
	local Time = ExplodeInfo.Time or .5

	
	local sizeTI = TweenInfo.new(
		Time, -- Time
		Enum.EasingStyle.Back, -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal)
		0 -- DelayTime
	)
	local colorTI = TweenInfo.new(
		Time-.1, -- Time
		Enum.EasingStyle.Cubic, -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal)
		0.2 -- DelayTime
	)
	local grayTI = TweenInfo.new(
		Time-.15, -- Time
		Enum.EasingStyle.Cubic, -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal -- DelayTime
		0.2 -- DelayTime
	)
	

	local model = script.ExplosionMeshModel
	for i = 1, Count do
		local expl = model:Clone()
		
		local CF = CF * CFrame.new(
			math.random(-maxRadius,maxRadius),
			math.random(-maxRadius,maxRadius),
			math.random(-maxRadius,maxRadius)
		) * CFrame.Angles(
			math.rad(math.random(0,360)),
			math.rad(math.random(0,360)),
			math.rad(math.random(0,360))
		)
		expl.ExplosionGray.CFrame = CF
		
		
		
		expl.ExplosionColor.Color = explodeColor
		expl.ExplosionGray.Color = explodeColor2

		expl.Parent = workspace.EffectsFolder

		for _, part in ipairs(expl:GetChildren()) do
			TS:Create(part, sizeTI, {Size = Vector3.new(1,1,1) * Size}):Play()
			
			if part.Name == "ExplosionColor" then
				if NeonState == false then
					part.Material = Enum.Material.Plastic
				end
				TS:Create(part, colorTI, {Transparency = 1,Size = part.Size*1.2}):Play()
			elseif part.Name == "ExplosionGray" then
				TS:Create(part, grayTI, {Transparency = 1,Size = part.Size*1.2}):Play()
			end
		end
		
		DB:AddItem(expl, Time+1)
	end
end

return Explosion
