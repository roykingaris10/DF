local cooldownDuration = 10 
local startTime = 0
local isCooldownActive = false

-- Function to start the cooldown
local function startCooldown()
	isCooldownActive = true
	startTime = tick()  
end

-- Connect the function to RenderStepped to update the cooldown every frame
game:GetService("RunService").RenderStepped:Connect(function()
	script.Parent.Parent.Visible = true
	if isCooldownActive then
		local elapsedTime = tick() - startTime

		local PercentNumber = math.clamp((elapsedTime / cooldownDuration) * 360, 0, 360)

		local F1 = script.Parent.Parent.Frame1.ImageLabel
		local F2 = script.Parent.Parent.Frame2.ImageLabel

		F1.UIGradient.Rotation = script.FlipProgress.Value == false and math.clamp(PercentNumber, 0, 180) or 180 - math.clamp(PercentNumber, 0, 180)
		F2.UIGradient.Rotation = script.FlipProgress.Value == false and math.clamp(PercentNumber, 180, 360) or 180 - math.clamp(PercentNumber, 180, 360)

		print("going")

		if script.MissingPartType.Value == "Color" then
			F1.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, script.ColorOfPercentPart.Value),
				ColorSequenceKeypoint.new(0.5, script.ColorOfPercentPart.Value),
				ColorSequenceKeypoint.new(0.501, script.ColorOfMissingPart.Value),
				ColorSequenceKeypoint.new(1, script.ColorOfMissingPart.Value)
			})
			F2.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, script.ColorOfPercentPart.Value),
				ColorSequenceKeypoint.new(0.5, script.ColorOfPercentPart.Value),
				ColorSequenceKeypoint.new(0.501, script.ColorOfMissingPart.Value),
				ColorSequenceKeypoint.new(1, script.ColorOfMissingPart.Value)
			})
			F1.UIGradient.Transparency = NumberSequence.new(0)
			F2.UIGradient.Transparency = NumberSequence.new(0)
		elseif script.MissingPartType.Value == "Trans" then
			F1.UIGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, script.TransOfPercentPart.Value),
				NumberSequenceKeypoint.new(0.5, script.TransOfPercentPart.Value),
				NumberSequenceKeypoint.new(0.501, script.TransOfMissingPart.Value),
				NumberSequenceKeypoint.new(1, script.TransOfMissingPart.Value)
			})
			F2.UIGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, script.TransOfPercentPart.Value),
				NumberSequenceKeypoint.new(0.5, script.TransOfPercentPart.Value),
				NumberSequenceKeypoint.new(0.501, script.TransOfMissingPart.Value),
				NumberSequenceKeypoint.new(1, script.TransOfMissingPart.Value)
			})
			F1.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
			F2.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
		elseif script.MissingPartType.Value == "TransAndColor" then
			F1.UIGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, script.TransOfPercentPart.Value),
				NumberSequenceKeypoint.new(0.5, script.TransOfPercentPart.Value),
				NumberSequenceKeypoint.new(0.501, script.TransOfMissingPart.Value),
				NumberSequenceKeypoint.new(1, script.TransOfMissingPart.Value)
			})
			F2.UIGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, script.TransOfPercentPart.Value),
				NumberSequenceKeypoint.new(0.5, script.TransOfPercentPart.Value),
				NumberSequenceKeypoint.new(0.501, script.TransOfMissingPart.Value),
				NumberSequenceKeypoint.new(1, script.TransOfMissingPart.Value)
			})
			F1.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, script.ColorOfPercentPart.Value),
				ColorSequenceKeypoint.new(0.5, script.ColorOfPercentPart.Value),
				ColorSequenceKeypoint.new(0.501, script.ColorOfMissingPart.Value),
				ColorSequenceKeypoint.new(1, script.ColorOfMissingPart.Value)
			})
			F2.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, script.ColorOfPercentPart.Value),
				ColorSequenceKeypoint.new(0.5, script.ColorOfPercentPart.Value),
				ColorSequenceKeypoint.new(0.501, script.ColorOfMissingPart.Value),
				ColorSequenceKeypoint.new(1, script.ColorOfMissingPart.Value)
			})
		else
			script.MissingPartType.Value = "Trans"
			error("Unknown Type. Only 3 available: “Trans”, “Color” and “TransAndColor”, changing to “Trans”.")
		end

		if elapsedTime >= cooldownDuration then
			isCooldownActive = false 
			script.Parent.Value = 0  
			game.Debris:AddItem(script.Parent.Parent.Parent, 0.1)
		end
	end
end)

startCooldown()
