-- //Services// --

local TweenService = game:GetService("TweenService")

-- //Module// --

local BubbleModule = {}

function BubbleModule:CreateBubble(bubbleInfo) -- Origin CFrame, Start Size, Start Transparency, End Size, Time
	local Part = script.Mesh:Clone()
	Part.CFrame = bubbleInfo.CF
	Part.Anchored = true
	Part.CanCollide = false
	Part.Massless = true
	Part.Parent = bubbleInfo.Parent or workspace.EffectsFolder 
	Part.Material = Enum.Material.Glass
	Part.Size = bubbleInfo.StartSize or Vector3.new(0,0,0)
	Part.Transparency = bubbleInfo.StartTransparency or 0
	
	local RequiredHighlight = Instance.new("Highlight")
	RequiredHighlight.Enabled = false
	RequiredHighlight.Parent = Part
	
	game.Debris:addItem(Part, bubbleInfo.Time or 0.5)

	local Info = TweenInfo.new(
		bubbleInfo.Time or 0.5, -- Length
		bubbleInfo.TweenStyle or Enum.EasingStyle.Sine, -- Easing Style
		Enum.EasingDirection.Out, -- Easing Direction
		0, -- Times repeated
		false, -- Reverse
		0 -- Delay
	)

	local Goals =
		{
			Transparency = 1;
			Size = bubbleInfo.EndSize or Vector3.new(10,10,10);
		}

	local Tween = TweenService:Create(Part, Info, Goals)

	Tween:Play()
end

return BubbleModule
