--[[
    SettingsController
    Location: Client Module
]]

return function(Client)
	local SettingsController = {}

	local player = Client.player
	local TweenService = game:GetService("TweenService")
	local SoundService = game:GetService("SoundService")
	local UserInputService = game:GetService("UserInputService")
	local ContentProvider = game:GetService("ContentProvider")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PlayerGui = player:WaitForChild("PlayerGui")

	local LowGFXService = nil
	local AudioDirector = nil

	local State = {
		lowGFXEnabled = false,
		masterVolume = 1.0,
		dragging = false,
		connections = {},
	}

	--═══════════════════════════════════════════════════════════════════════════
	-- SOUNDS
	--═══════════════════════════════════════════════════════════════════════════

	local toggleSound = Instance.new("Sound")
	toggleSound.Name = "SettingsSFX_Toggle"
	toggleSound.SoundId = "rbxassetid://103866342467024"
	toggleSound.Volume = 0.3
	toggleSound.Parent = script

	local hoverSound = Instance.new("Sound")
	hoverSound.Name = "SettingsSFX_Hover"
	hoverSound.SoundId = "rbxassetid://108775056064359"
	hoverSound.Volume = 0.2
	hoverSound.Parent = script

	ContentProvider:PreloadAsync({toggleSound, hoverSound})

	--═══════════════════════════════════════════════════════════════════════════
	-- TWEEN CONFIG
	--═══════════════════════════════════════════════════════════════════════════

	local TweenConfig = {
		toggle = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		hover = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	}

	--═══════════════════════════════════════════════════════════════════════════
	-- REFERENCES
	--═══════════════════════════════════════════════════════════════════════════

	local UI
	local SettingsHolder
	local LowGraphFrame
	local ToggleFrame
	local OnButton
	local OffButton
	local VolumeSlide
	local VolumeTrack
	local VolumeMarker

	local function setupReferences()
		UI = PlayerGui:WaitForChild("UI")

		local topHolder = UI:FindFirstChild("topHolder")
		if not topHolder then
			warn("[SettingsController] TopHolder not found")
			return false
		end

		SettingsHolder = topHolder:FindFirstChild("SettingsHolder")
		if not SettingsHolder then
			warn("[SettingsController] SettingsHolder not found")
			return false
		end

		local mainFrame = SettingsHolder:FindFirstChild("mainFrame")
		if not mainFrame then
			warn("[SettingsController] mainFrame not found")
			return false
		end

		LowGraphFrame = mainFrame:FindFirstChild("lowGraphFrame")
		if LowGraphFrame then
			ToggleFrame = LowGraphFrame:FindFirstChild("toggleFrame")
			if ToggleFrame then
				OnButton = ToggleFrame:FindFirstChild("on")
				OffButton = ToggleFrame:FindFirstChild("off")
			end
		end

		VolumeSlide = mainFrame:FindFirstChild("volumeSlide")
		if VolumeSlide then
			VolumeTrack = VolumeSlide:FindFirstChild("slider")
				or VolumeSlide:FindFirstChild("ImageLabel")
			VolumeMarker = VolumeSlide:FindFirstChild("marker")
		end

		return true
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- TOGGLE VISUALS
	--═══════════════════════════════════════════════════════════════════════════

	local function updateToggleVisuals(enabled, instant)
		if not OnButton or not OffButton then return end

		local duration = instant and 0 or 0.2
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

		-- Only tween TextTransparency and ImageTransparency, never BackgroundTransparency
		if enabled then
			-- ON state - highlight "on" button
			if OnButton:IsA("TextButton") then
				TweenService:Create(OnButton, tweenInfo, {TextTransparency = 0}):Play()
			elseif OnButton:IsA("ImageButton") then
				TweenService:Create(OnButton, tweenInfo, {ImageTransparency = 0}):Play()
			end

			if OffButton:IsA("TextButton") then
				TweenService:Create(OffButton, tweenInfo, {TextTransparency = 0.5}):Play()
			elseif OffButton:IsA("ImageButton") then
				TweenService:Create(OffButton, tweenInfo, {ImageTransparency = 0.5}):Play()
			end
		else
			-- OFF state - highlight "off" button
			if OffButton:IsA("TextButton") then
				TweenService:Create(OffButton, tweenInfo, {TextTransparency = 0}):Play()
			elseif OffButton:IsA("ImageButton") then
				TweenService:Create(OffButton, tweenInfo, {ImageTransparency = 0}):Play()
			end

			if OnButton:IsA("TextButton") then
				TweenService:Create(OnButton, tweenInfo, {TextTransparency = 0.5}):Play()
			elseif OnButton:IsA("ImageButton") then
				TweenService:Create(OnButton, tweenInfo, {ImageTransparency = 0.5}):Play()
			end
		end
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- LOW GFX TOGGLE
	--═══════════════════════════════════════════════════════════════════════════

	local function setLowGFX(enabled)
		if State.lowGFXEnabled == enabled then return end

		State.lowGFXEnabled = enabled

		toggleSound:Stop()
		toggleSound:Play()

		updateToggleVisuals(enabled, false)

		-- Apply low GFX mode
		if LowGFXService then
			if enabled then
				LowGFXService.Enable()
			else
				LowGFXService.Disable()
			end
		end

		player:SetAttribute("LowGFXEnabled", enabled)

		print("[SettingsController] Low GFX Mode:", enabled and "ENABLED" or "DISABLED")
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- BUTTON SETUP
	--═══════════════════════════════════════════════════════════════════════════

	local function setupToggleButtons()
		if not OnButton or not OffButton then return end

		-- On button hover
		table.insert(State.connections, OnButton.MouseEnter:Connect(function()
			if not State.lowGFXEnabled then
				hoverSound:Stop()
				hoverSound:Play()
			end
		end))

		-- On button click
		table.insert(State.connections, OnButton.Activated:Connect(function()
			setLowGFX(true)
		end))

		-- Off button hover
		table.insert(State.connections, OffButton.MouseEnter:Connect(function()
			if State.lowGFXEnabled then
				hoverSound:Stop()
				hoverSound:Play()
			end
		end))

		-- Off button click
		table.insert(State.connections, OffButton.Activated:Connect(function()
			setLowGFX(false)
		end))
	end

	local function applyVolume(percent, instant)
		percent = math.clamp(percent or 0, 0, 1)
		State.masterVolume = percent
		player:SetAttribute("MasterVolume", percent)

		if AudioDirector and AudioDirector.SetMasterVolume then
			AudioDirector:SetMasterVolume(percent)
		end

		if VolumeMarker then
			local existingY = VolumeMarker.Position.Y
			local target = UDim2.new(percent, 0, existingY.Scale, existingY.Offset)
			if instant then
				VolumeMarker.Position = target
			else
				TweenService:Create(VolumeMarker, TweenConfig.toggle, { Position = target }):Play()
			end
		end
	end

	local function percentFromInput(inputPosition)
		if not VolumeTrack then return State.masterVolume end
		local origin = VolumeTrack.AbsolutePosition.X
		local span = VolumeTrack.AbsoluteSize.X
		if span <= 0 then return State.masterVolume end
		return math.clamp((inputPosition.X - origin) / span, 0, 1)
	end

	local function setupVolumeSlider()
		if not VolumeTrack then return end

		if VolumeTrack:IsA("GuiObject") then
			VolumeTrack.Active = true
		end

		table.insert(State.connections, VolumeTrack.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				State.dragging = true
				applyVolume(percentFromInput(input.Position), true)
			end
		end))

		table.insert(State.connections, VolumeTrack.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				if State.dragging then
					toggleSound:Stop()
					toggleSound:Play()
				end
				State.dragging = false
			end
		end))

		table.insert(State.connections, UserInputService.InputChanged:Connect(function(input)
			if not State.dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				applyVolume(percentFromInput(input.Position), true)
			end
		end))

		table.insert(State.connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				State.dragging = false
			end
		end))
	end

	local function loadSavedSettings()
		local savedLowGFX = player:GetAttribute("LowGFXEnabled")
		if savedLowGFX then
			State.lowGFXEnabled = savedLowGFX
			updateToggleVisuals(savedLowGFX, true)
			if savedLowGFX and LowGFXService then
				LowGFXService.Enable()
			end
		else
			updateToggleVisuals(false, true)
		end

		local savedVolume = player:GetAttribute("MasterVolume")
		if savedVolume == nil then savedVolume = 1.0 end
		applyVolume(savedVolume, true)
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- PUBLIC API
	--═══════════════════════════════════════════════════════════════════════════

	function SettingsController:Init()
		local lowOk, lowRes = pcall(function()
			return require(ReplicatedStorage.Kits.Nodes.Utility.LowGFXService)
		end)
		if lowOk then LowGFXService = lowRes end

		local audioOk, audioRes = pcall(function()
			return require(ReplicatedStorage.Kits.Audio.AudioDirector)
		end)
		if audioOk then AudioDirector = audioRes end

		if not setupReferences() then
			warn("[SettingsController] Failed to setup references")
			return
		end

		if OnButton and OffButton then
			setupToggleButtons()
		end
		setupVolumeSlider()
		loadSavedSettings()
	end

	function SettingsController:SetMasterVolume(percent)
		applyVolume(percent, false)
	end

	function SettingsController:GetMasterVolume()
		return State.masterVolume
	end

	function SettingsController:SetLowGFX(enabled)
		setLowGFX(enabled)
	end

	function SettingsController:ToggleLowGFX()
		setLowGFX(not State.lowGFXEnabled)
	end

	function SettingsController:IsLowGFXEnabled()
		return State.lowGFXEnabled
	end

	function SettingsController:Cleanup()
		for _, conn in ipairs(State.connections) do
			conn:Disconnect()
		end
		toggleSound:Destroy()
		hoverSound:Destroy()
	end

	return SettingsController
end