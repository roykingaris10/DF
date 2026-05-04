--[[
    SettingsController
    Location: Client Module
]]

return function(Client)
	local SettingsController = {}

	local player = Client.player
	local TweenService = game:GetService("TweenService")
	local SoundService = game:GetService("SoundService")
	local ContentProvider = game:GetService("ContentProvider")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PlayerGui = player:WaitForChild("PlayerGui")

	-- Get LowGFXService (it's a table, not a function)
	local LowGFXService = nil

	--═══════════════════════════════════════════════════════════════════════════
	-- STATE
	--═══════════════════════════════════════════════════════════════════════════

	local State = {
		lowGFXEnabled = false,
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
		if not LowGraphFrame then 
			warn("[SettingsController] lowGraphFrame not found")
			return false 
		end

		ToggleFrame = LowGraphFrame:FindFirstChild("toggleFrame")
		if not ToggleFrame then 
			warn("[SettingsController] toggleFrame not found")
			return false 
		end

		OnButton = ToggleFrame:FindFirstChild("on")
		OffButton = ToggleFrame:FindFirstChild("off")

		if not OnButton or not OffButton then
			warn("[SettingsController] on/off buttons not found")
			return false
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

	--═══════════════════════════════════════════════════════════════════════════
	-- LOAD SAVED SETTINGS
	--═══════════════════════════════════════════════════════════════════════════

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
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- PUBLIC API
	--═══════════════════════════════════════════════════════════════════════════

	function SettingsController:Init()
		-- Load LowGFXService
		local success, result = pcall(function()
			return require(ReplicatedStorage.Kits.Nodes.Utility.LowGFXService)
		end)

		if success then
			LowGFXService = result
		else
			warn("[SettingsController] Failed to load LowGFXService:", result)
		end

		if not setupReferences() then
			warn("[SettingsController] Failed to setup references")
			return
		end

		setupToggleButtons()
		loadSavedSettings()
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