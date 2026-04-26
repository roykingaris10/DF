-- EnhancedTypewriter.lua
local EnhancedTypewriter = {}
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

EnhancedTypewriter.Defaults = {
	TypewriterSpeed = 0.08,          -- Seconds between each character
	CharacterShakeIntensity = 3,     -- How much each character shakes
	CharacterShakeDuration = 0.3,    -- How long shake lasts
	SizeTweenScale = 1.5,            -- How much to scale up
	SizeTweenDuration = 0.4,         -- How long size tween lasts
	CharacterSpacing = 0.8,          -- Space between characters (0.5 = tight, 1.5 = wide)
	WordSpacing = 2.0,               -- Extra space for spaces between words
	ColorSequence = {                -- Colors to cycle through
		Color3.fromRGB(255, 0, 0),   -- Red
		Color3.fromRGB(255, 165, 0), -- Orange
		Color3.fromRGB(255, 255, 0), -- Yellow
		Color3.fromRGB(0, 255, 0),   -- Green
		Color3.fromRGB(0, 0, 255),   -- Blue
		Color3.fromRGB(148, 0, 211)  -- Violet
	},
	FinalColor = Color3.fromRGB(255, 255, 255), -- Color after effects
	Font = Enum.Font.GothamBlack,	 -- Font Family
	FontWeight = Enum.FontWeight.Regular, --Font Weight
	Italic = false, 					 -- Italics
	FinalSize = 14,                  -- Final text size
	UseRainbowColors = true,         -- Whether to use color sequence
}

-- Helper function to merge settings with defaults
local function mergeSettings(customSettings)
	local settings = {}

	-- Copy defaults first
	for key, value in pairs(EnhancedTypewriter.Defaults) do
		settings[key] = value
	end

	-- Override with custom settings
	if customSettings then
		for key, value in pairs(customSettings) do
			settings[key] = value
		end
	end

	return settings
end

-- Create individual character label
local function createCharacterLabel(character, parent, index, totalChars, settings)
	local charLabel = Instance.new("TextLabel")
	charLabel.Name = "Char_" .. index
	charLabel.Size = UDim2.new(0, 0, 0, 0) -- Start at size 0
	charLabel.Position = UDim2.new(0, 0, 0.5, 0)
	charLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	charLabel.BackgroundTransparency = 1
	charLabel.Text = character
	charLabel.TextColor3 = settings.ColorSequence[1]
	charLabel.TextSize = settings.FinalSize
	charLabel.TextTransparency = 1 -- Start invisible
	charLabel.Font = settings.Font
	local style 
	if settings.Italic then
		style = Enum.FontStyle.Italic
	else
		style = Enum.FontStyle.Normal
	end
	charLabel.FontFace = Font.new(charLabel.FontFace.Family,settings.FontWeight,style)
	charLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	charLabel.TextStrokeTransparency = 0.3
	charLabel.Parent = parent

	return charLabel
end

local function calculateAlignmentOffset(totalWidth, alignment, parentSize)
	if alignment == "Left" then
		return -parentSize.X / 2  -- Start from left edge
	elseif alignment == "Right" then
		return parentSize.X / 2 - totalWidth  -- End at right edge
	else -- "Center"
		return -totalWidth / 2  -- Center within the container
	end
end

local function setupContainerPosition(container, totalWidth, alignment, parentFrame)
	if alignment == "Left" then
		container.Position = UDim2.new(0, 0, 0.5, 0)
		container.AnchorPoint = Vector2.new(0, 0.5)
	elseif alignment == "Right" then
		container.Position = UDim2.new(1, 0, 0.5, 0)
		container.AnchorPoint = Vector2.new(1, 0.5)
	else -- "Center"
		container.Position = UDim2.new(0.5, 0, 0.5, 0)
		container.AnchorPoint = Vector2.new(0.5, 0.5)
	end
end

-- Individual character entrance animation
local function animateCharacter(charLabel, index, settings)
	local originalPosition = charLabel.Position
	local targetSize = settings.FinalSize

	-- FIXED: Proper color cycling through the sequence
	local colorIndex = ((index - 1) % #settings.ColorSequence) + 1
	local startColor = settings.ColorSequence[colorIndex]

	-- Set initial color
	charLabel.TextColor3 = startColor

	-- Make character visible
	charLabel.TextTransparency = 0

	-- Size tween (scale up then down)
	charLabel.TextSize = 0
	local sizeTween1 = TweenService:Create(charLabel, TweenInfo.new(
		settings.SizeTweenDuration / 2, 
		Enum.EasingStyle.Back, 
		Enum.EasingDirection.Out
		), {
			TextSize = targetSize * settings.SizeTweenScale
		})

	local sizeTween2 = TweenService:Create(charLabel, TweenInfo.new(
		settings.SizeTweenDuration / 2, 
		Enum.EasingStyle.Bounce, 
		Enum.EasingDirection.Out
		), {
			TextSize = targetSize
		})

	-- Color tween - only if we're using rainbow colors
	local colorTween
	if settings.UseRainbowColors then
		colorTween = TweenService:Create(charLabel, TweenInfo.new(
			settings.SizeTweenDuration, 
			Enum.EasingStyle.Quad, 
			Enum.EasingDirection.Out
			), {
				TextColor3 = settings.FinalColor
			})
		colorTween:Play()
	else
		-- If not using rainbow, just set the final color immediately
		charLabel.TextColor3 = settings.FinalColor
	end

	-- Start size animations
	sizeTween1:Play()

	sizeTween1.Completed:Connect(function()
		sizeTween2:Play()
	end)

	-- Shake effect
	local shakeStart = tick()
	local shakeConnection
	shakeConnection = RunService.Heartbeat:Connect(function()
		if tick() - shakeStart > settings.CharacterShakeDuration then
			-- Return to original position
			TweenService:Create(charLabel, TweenInfo.new(0.1), {
				Position = originalPosition
			}):Play()
			shakeConnection:Disconnect()
			return
		end

		-- Random shake offset
		local shakeX = math.random(-settings.CharacterShakeIntensity, settings.CharacterShakeIntensity)
		local shakeY = math.random(-settings.CharacterShakeIntensity, settings.CharacterShakeIntensity)

		charLabel.Position = UDim2.new(
			originalPosition.X.Scale,
			originalPosition.X.Offset + shakeX,
			originalPosition.Y.Scale,
			originalPosition.Y.Offset + shakeY
		)
	end)

	return {
		SizeTween1 = sizeTween1,
		SizeTween2 = sizeTween2,
		ColorTween = colorTween,
		ShakeConnection = shakeConnection
	}
end

-- Main enhanced typewriter function
function EnhancedTypewriter:AnimateText(parentFrame, text, customSettings)
	local settings = mergeSettings(customSettings)

	-- Clear previous characters
	for _, child in ipairs(parentFrame:GetChildren()) do
		if child.Name:find("Char_") then
			child:Destroy()
		end
	end

	-- Create container for characters
	local container = Instance.new("Frame")
	container.Name = "TextContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = parentFrame

	local characters = {}
	local animations = {}

	-- Create all character labels (initially hidden)
	for i = 1, #text do
		local char = text:sub(i, i)
		local charLabel = createCharacterLabel(char, container, i, #text, settings)
		table.insert(characters, charLabel)
	end

	local totalWidth = 0
	for i, charLabel in ipairs(characters) do
		local char = text:sub(i, i)
		local spacing = settings.CharacterSpacing
		if char == " " then spacing = settings.WordSpacing end
		totalWidth = totalWidth + charLabel.TextSize * spacing
	end

	-- Position characters with proper alignment
	local startX = 0
	if settings.TextAlignment == "Center" then
		startX = -totalWidth / 2
	elseif settings.TextAlignment == "Right" then
		startX = -totalWidth
	end
	-- Left alignment: startX = 0

	local currentX = startX
	for i, charLabel in ipairs(characters) do
		local char = text:sub(i, i)
		local spacing = settings.CharacterSpacing
		if char == " " then spacing = settings.WordSpacing end

		charLabel.Position = UDim2.new(0.5, currentX, 0.5, 0)
		currentX = currentX + charLabel.TextSize * spacing
	end
	local currentIndex = 1

	local function animateNextCharacter()
		if currentIndex > #characters then return end

		local charLabel = characters[currentIndex]

		-- Animate this character
		local charAnimations = animateCharacter(charLabel, currentIndex, settings)
		table.insert(animations, charAnimations)

		currentIndex = currentIndex + 1

		-- FIXED: Use spawn to avoid blocking the thread with fast speeds
		if currentIndex <= #characters then
			spawn(function()
				task.wait(settings.TypewriterSpeed)
				animateNextCharacter()
			end)
		end
	end

	-- Start animation
	animateNextCharacter()

	return {
		Container = container,
		Characters = characters,
		Animations = animations,
		Stop = function()
			for _, animData in ipairs(animations) do
				if animData.ShakeConnection then
					animData.ShakeConnection:Disconnect()
				end
			end
		end
	}
end

-- Quick setup function for common use cases
function EnhancedTypewriter:QuickAnimate(parentFrame, text, options)
	local settings = mergeSettings({
		TypewriterSpeed = options and options.speed or nil,
		CharacterShakeIntensity = options and options.shake or nil,
		SizeTweenScale = options and options.scale or nil,
		FinalSize = options and options.size or nil,
		FinalColor = options and options.finalColor or nil,
		CharacterSpacing = options and options.spacing or nil,
		WordSpacing = options and options.wordSpacing or nil,
		UseRainbowColors = options and options.rainbow or nil,
		Font = options and options.font or nil,
		FontWeight = options and options.fontweight or nil,
		TextAlignment = options and options.alignment or nil,
	})

	if options and options.colors then
		settings.ColorSequence = options.colors
	end

	return self:AnimateText(parentFrame, text, settings)
end

-- Preset styles
EnhancedTypewriter.Presets = {
	TitleScreen = {
		TypewriterSpeed = 0.001,
		CharacterShakeIntensity = 1.2,
		CharacterShakeDuration = 0.03,
		SizeTweenScale = 1.4,
		SizeTweenDuration = 0.15,
		CharacterSpacing = 0.525,          -- Space between characters (0.5 = tight, 1.5 = wide)
		WordSpacing = 0.55,               -- Extra space for spaces between words
		ColorSequence = {
			Color3.fromRGB(0, 0, 0),  
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(255, 216, 125), 
		},
		FinalColor = Color3.fromRGB(255, 218, 123),
		Font = Enum.Font.Fondamento,
		Italic = true,
		TextAlignment = "Center",
		FinalSize = 14,
	},
	KJStyle = {
		TypewriterSpeed = 0.06,
		CharacterShakeIntensity = 4,
		CharacterShakeDuration = 0.03,
		SizeTweenScale = 1.8,
		SizeTweenDuration = 0.5,
		ColorSequence = {
			Color3.fromRGB(255, 255, 255),   -- Bright Red
			Color3.fromRGB(255, 51, 51), -- Bright Yellow
			Color3.fromRGB(100, 255, 100), -- Bright Green
			Color3.fromRGB(255, 202, 79), -- Purple
		},
		FinalColor = Color3.fromRGB(255, 255, 255),
		FinalSize = 14,
	},

	EpicStyle = {
		TypewriterSpeed = 0.1,
		CharacterShakeIntensity = 6,
		SizeTweenScale = 2.0,
		ColorSequence = {
			Color3.fromRGB(255, 215, 0),   -- Gold
			Color3.fromRGB(255, 255, 255), -- White
			Color3.fromRGB(192, 192, 192), -- Silver
		},
		FinalColor = Color3.fromRGB(255, 215, 0),
		FinalSize = 48,
	},

	CyberStyle = {
		TypewriterSpeed = 0.04,
		CharacterShakeIntensity = 2,
		SizeTweenScale = 1.3,
		ColorSequence = {
			Color3.fromRGB(0, 255, 255),   -- Cyan
			Color3.fromRGB(255, 0, 255),   -- Magenta
			Color3.fromRGB(0, 255, 255),   -- Cyan
		},
		FinalColor = Color3.fromRGB(0, 255, 255),
		FinalSize = 36,
	}
}

-- Function to use presets
function EnhancedTypewriter:AnimateWithPreset(parentFrame, text, presetName)
	local preset = self.Presets[presetName] or self.Presets.KJStyle
	return self:AnimateText(parentFrame, text, preset)
end

-- Cleanup function
function EnhancedTypewriter:Cleanup(parentFrame)
	local container = parentFrame:FindFirstChild("TextContainer")
	if container then
		container:Destroy()
	end
end

return EnhancedTypewriter