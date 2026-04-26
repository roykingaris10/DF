local TweenScaleModel = {}

-- linearly interpolates between two values
local function lerp(a, b, t)
	return a + (b - a) * t
end

-- Smoothly scale a model over time using ScaleTo
function TweenScaleModel.Tween(model, targetScale, duration)
	assert(model and model:IsA("Model"), "Model is required")
	assert(type(targetScale) == "number" and targetScale > 0, "Target scale must be a positive number")

	local startScale = model:GetScale()
	local elapsed = 0
	local heartbeat = game:GetService("RunService").Heartbeat

	-- Tween loop
	task.spawn(function()
		while elapsed < duration do
			local dt = heartbeat:Wait()
			elapsed += dt
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local currentScale = lerp(startScale, targetScale, alpha)
			model:ScaleTo(currentScale)
		end	
		model:ScaleTo(targetScale) -- Ensure final scale is set exactly
	end)
end

return TweenScaleModel