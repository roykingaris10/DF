local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local billboard = script.Parent
	local adornee = billboard.Adornee or billboard.Parent

local BASE_DISTANCE = 15 
local MIN_SCALE = 1.1 
local MAX_SCALE = 10    

RunService.RenderStepped:Connect(function()
	if not adornee or not adornee:IsA("BasePart") then return end

	local distance = (camera.CFrame.Position - adornee.Position).Magnitude
	local scale = math.clamp(BASE_DISTANCE / distance, MIN_SCALE, MAX_SCALE)

	billboard.Size = UDim2.fromOffset(60 * scale, 20 * scale)
end)