local ClientUI = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local ClientSFX = require(Nodes.Utility["ClientSFX"])

local Player = game:GetService('Players').LocalPlayer
local PlayerGui = Player:WaitForChild('PlayerGui')

local CameraShaker = require(Nodes.Utility.CameraShaker)
local Camera = workspace.CurrentCamera
local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
	Camera.CFrame = Camera.CFrame * shakeCf
end)
camShake:Start()


local SoundService = game:GetService("SoundService")
local UISFXFolder = Kits:WaitForChild("Sounds")

function TweenForm(Frame,Time, Style, Direction, RepeatCount, Return, DelayTime, Value)
	return TweenService:Create(Frame,TweenInfo.new(Time,Style,Direction,RepeatCount,Return,DelayTime),Value)
end

--// Effects
function ClientUI.TextTransition(params)

	local Temporary = Instance.new(params.Type)
	Temporary.Value = params.Start or 0

	Temporary:GetPropertyChangedSignal("Value"):Connect(function()
		params.Label.Text = string.format(params.Mask, Temporary.Value)
	end)

	TweenService:Create(Temporary, TweenInfo.new(params.Duration), {
		Value = params.Finish
	}):Play()

end

function ClientUI:PartyHoverButton(button: GuiObject, color : Color3, rotation : IntValue)
	local OriginalSize = button.Size
	local OriginalRotation = button.Rotation
	local OriginalColor = button.ImageLabel.ImageColor3

	-- visuals
	local Tweens = {
		ButtonEnter = TweenForm(button, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0, {
			Size = UDim2.fromScale( button.Size.X.Scale + (button.Size.X.Scale * 0.05) , button.Size.Y.Scale + (button.Size.Y.Scale * 0.05)),
			Rotation = OriginalRotation + rotation,
		}),
		ButtonLeave = TweenForm(button, 0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0, {
			Size = OriginalSize,
			Rotation = OriginalRotation
		}),
		StrokeEnter = TweenForm(button.UIStroke, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0, {
			Thickness = 2,
		}),
		StrokeLeave = TweenForm(button.UIStroke, 0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0, {
			Thickness = 0,
		}),
		ImageEnter = TweenForm(button.ImageLabel, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0, {
			ImageColor3 = color
		}),
		ImageLeave = TweenForm(button.ImageLabel, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0, {
			ImageColor3 = OriginalColor
		}),
	}

	button.MouseEnter:Connect(function()
		ClientSFX.PlaySFX(UISFXFolder.Hover2)
		Tweens.ButtonEnter:Play()
		Tweens.ImageEnter:Play()
		Tweens.StrokeEnter:Play()
	end)

	button.MouseLeave:Connect(function()
		Tweens.ButtonLeave:Play()
		Tweens.ImageLeave:Play()
		Tweens.StrokeLeave:Play()
	end)
end

function ClientUI:CloseHoverButton(button: GuiObject, color : Color3)
	local OriginalSize = button.Size
	local OriginalColor = button.ImageColor3

	-- visuals
	local Tweens = {
		ButtonEnter = TweenForm(button, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0, {
			ImageColor3 = color
		}),
		ButtonLeave = TweenForm(button, 0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0, {
			ImageColor3 = OriginalColor
		}),
	}

	button.MouseEnter:Connect(function()
		ClientSFX.PlaySFX(UISFXFolder.Click5)
		Tweens.ButtonEnter:Play()
	end)

	button.MouseLeave:Connect(function()
		Tweens.ButtonLeave:Play()
	end)
end

function ClientUI:OpenUI()
	if Lighting.Blur.Size ~= 15 then
	--	if SettingsModule.NoCameraShake then return end
		Player.Character:SetAttribute("Menu", true)

		camShake:StopAllShakes()
		camShake:Shake(CameraShaker.Presets["SmallBump"])

		TweenService:Create(Lighting.Blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = 15
		}):Play()

		TweenService:Create(Camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			FieldOfView = 80
		}):Play()

		--PlayerGui.MainGui.PlayFrame.Visible = false
		--PlayerGui.QueueGui.Enabled = false
	end
end

function ClientUI:CloseUI(SwappedUI)
	if not SwappedUI or typeof(SwappedUI) ~= "string" or not string.find(SwappedUI, "Button") then
		Player.Character:SetAttribute("Menu", false)
		TweenService:Create(Lighting.Blur, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = 0
		}):Play()

		TweenService:Create(Camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			FieldOfView = 70
		}):Play()

		--PlayerGui.MainGui.PlayFrame.Visible = true
		--PlayerGui.QueueGui.Enabled = true
	end
end

function ClientUI:SoundHover(frame: GuiObject)
	frame.MouseEnter:Connect(function()

		ClientSFX.PlaySFX(UISFXFolder.Hover3)
	end)
	
end

function ClientUI:ButtonMouseHover(button: GuiObject)

	local OriginalSize = button.Size
	local OriginalRotation = button.Rotation

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), {
			Size = UDim2.fromScale( button.Size.X.Scale + (button.Size.X.Scale*0.05) , button.Size.Y.Scale + (button.Size.Y.Scale*0.05)),
			Rotation = OriginalRotation + math.random(-3,3),
		}):Play()
		ClientSFX.PlaySFX(UISFXFolder.UI.UIHover)
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {
			Size = OriginalSize,
			Rotation = OriginalRotation
		}):Play()
	end)

end

function ClientUI:MenuButtonMouseHover(button: GuiObject)

	local OriginalSize = button.Size

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), {
			Size = UDim2.fromScale( button.Size.X.Scale + (button.Size.X.Scale*0.05) , button.Size.Y.Scale + (button.Size.Y.Scale*0.05)),
		}):Play()
		ClientSFX.PlaySFX(UISFXFolder.UI.BeepClick)
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {
			Size = OriginalSize,
		}):Play()
	end)

end

function ClientUI:InviteButtonMouseHover(button: GuiObject, rotation: IntValue)

	local OriginalSize = button.Size
	local OriginalRotation = button.Rotation

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {
			Size = UDim2.fromScale( button.Size.X.Scale + (button.Size.X.Scale*0.05) , button.Size.Y.Scale + (button.Size.Y.Scale*0.05)),
			Rotation = OriginalRotation + rotation,
		}):Play()
		ClientSFX.PlaySFX(UISFXFolder.UI)
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {
			Size = OriginalSize,
			Rotation = OriginalRotation
		}):Play()
	end)

end

function ClientUI:BoostButtonMouseHover(button: GuiObject, rotation: IntValue)

	local OriginalSize = button.Parent.ImageLabel.Size
	local OriginalRotation = button.Parent.ImageLabel.Rotation

	button.MouseEnter:Connect(function()
		TweenService:Create(button.Parent.ImageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {
			Size = UDim2.fromScale( button.Size.X.Scale + (button.Size.X.Scale*0.05) , button.Size.Y.Scale + (button.Size.Y.Scale*0.05)),
			Rotation = OriginalRotation + rotation,
		}):Play()
		ClientSFX.PlaySFX(UISFXFolder.UIHover)
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button.Parent.ImageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {
			Size = OriginalSize,
			Rotation = OriginalRotation
		}):Play()
	end)

end

function ClientUI:DynamicGradient(parameters)

	local Gradient = parameters.Gradient

	local StartColor = parameters.Color.Start
	local FinishColor = parameters.Color.Finish

	local Duration = parameters.Duration

	assert(Gradient and StartColor and FinishColor and Duration,
		"ClientUI / DynamicGradient - Please provide all parameters: Gradient, Color.Start, Color.Finish and Duration."
	)

	local ReferenceValue = Instance.new("NumberValue")
	ReferenceValue.Value = 1

	ReferenceValue.Changed:Connect(function()
		Gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, StartColor),

			ColorSequenceKeypoint.new(math.clamp(ReferenceValue.Value, 0.001, 0.999), StartColor),
			ColorSequenceKeypoint.new(math.clamp(ReferenceValue.Value + 0.005, 0.001, 0.999), FinishColor),

			ColorSequenceKeypoint.new(1, FinishColor),
		})
	end)

	local Tween = TweenService:Create(ReferenceValue, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {Value = 0})
	Tween:Play()

	Tween.Completed:Once(function()
		ReferenceValue:Destroy()
	end)

end


return ClientUI
