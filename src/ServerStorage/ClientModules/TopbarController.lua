return function(Client)
	local TopbarController = {}

	local player = Client.player
	local TweenService = game:GetService("TweenService")
	local SoundService = game:GetService("SoundService")
	local ContentProvider = game:GetService("ContentProvider")
	local UserInputService = game:GetService("UserInputService")
	local PlayerGui = player:WaitForChild("PlayerGui")

	--═══════════════════════════════════════════════════════════════════════════
	-- STATE
	--═══════════════════════════════════════════════════════════════════════════

	local State = {
		currentPanel = nil,
		isAnimating = false,
		connections = {},
		buttonOriginalSizes = {},
	}

	--═══════════════════════════════════════════════════════════════════════════
	-- SOUNDS
	--═══════════════════════════════════════════════════════════════════════════

	local Sounds = {
		open = Instance.new("Sound"),
		close = Instance.new("Sound"),
		click = Instance.new("Sound"),
		hover = Instance.new("Sound"),
	}

	Sounds.open.Name = "TopbarSFX_Open"
	Sounds.open.SoundId = "rbxassetid://10128766965"
	Sounds.open.Volume = 0.4
	Sounds.open.Parent = script

	Sounds.close.Name = "TopbarSFX_Close"
	Sounds.close.SoundId = "rbxassetid://105426467647022"
	Sounds.close.Volume = 0.4
	Sounds.close.Parent = script

	Sounds.click.Name = "TopbarSFX_Click"
	Sounds.click.SoundId = "rbxassetid://103866342467024"
	Sounds.click.Volume = 0.3
	Sounds.click.Parent = script

	Sounds.hover.Name = "TopbarSFX_Hover"
	Sounds.hover.SoundId = "rbxassetid://108775056064359"
	Sounds.hover.Volume = 0.2
	Sounds.hover.Parent = script

	ContentProvider:PreloadAsync({Sounds.open, Sounds.close, Sounds.click, Sounds.hover})

	local function playSound(soundName)
		local sound = Sounds[soundName]
		if sound then
			sound:Stop()
			sound:Play()
		end
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- TWEEN CONFIG
	--═══════════════════════════════════════════════════════════════════════════

	local TweenConfig = {
		panelFadeIn = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		panelFadeOut = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		buttonHover = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		buttonUnhover = TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		buttonPress = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		buttonRelease = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	}

	--═══════════════════════════════════════════════════════════════════════════
	-- REFERENCES
	--═══════════════════════════════════════════════════════════════════════════

	local UI
	local TopHolder
	local TopBtns
	local FrameTitle
	local Panels = {}
	local Buttons = {}

	local function setupReferences()
		UI = PlayerGui:WaitForChild("UI")

		TopHolder = UI:FindFirstChild("topHolder")
		if not TopHolder then
			warn("[TopBarController] TopHolder not found")
			return false
		end

		FrameTitle = TopHolder:FindFirstChild("frameTitle")

		TopBtns = UI:FindFirstChild("topBtns")
		if not TopBtns then
			warn("[TopBarController] topBtns not found")
			return false
		end

		Panels.settings = TopHolder:FindFirstChild("SettingsHolder")
		Panels.serverlist = TopHolder:FindFirstChild("ServerListHolder")
		Panels.noti = TopHolder:FindFirstChild("NotificationHolder")

		local btnFrames = {
			settings = TopBtns:FindFirstChild("settings"),
			serverlist = TopBtns:FindFirstChild("serverlist"),
			noti = TopBtns:FindFirstChild("noti"),
		}

		for name, frame in pairs(btnFrames) do
			if frame then
				local btn = frame:FindFirstChild("btn")
				if btn and (btn:IsA("ImageButton") or btn:IsA("TextButton")) then
					Buttons[name] = btn
					State.buttonOriginalSizes[btn] = btn.Size
				end
			end
		end

		return true
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- TRANSPARENCY HELPERS
	--═══════════════════════════════════════════════════════════════════════════

	local function setDescendantsTransparency(parent, transparency)
		if not parent then return end

		for _, child in ipairs(parent:GetDescendants()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				child.TextTransparency = transparency
				local stroke = child:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Transparency = transparency
				end
			elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
				child.ImageTransparency = transparency
			end
		end
	end

	local function fadeDescendantsTo(parent, targetTrans, tweenInfo)
		if not parent then return end

		for _, child in ipairs(parent:GetDescendants()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				TweenService:Create(child, tweenInfo, {TextTransparency = targetTrans}):Play()
				local stroke = child:FindFirstChildOfClass("UIStroke")
				if stroke then
					TweenService:Create(stroke, tweenInfo, {Transparency = targetTrans}):Play()
				end
			elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
				TweenService:Create(child, tweenInfo, {ImageTransparency = targetTrans}):Play()
			end
		end
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- PANEL TITLE
	--═══════════════════════════════════════════════════════════════════════════

	local PANEL_TITLES = {
		settings = "SETTINGS",
		serverlist = "SERVER LIST",
		noti = "NOTIFICATIONS",
	}

	local function updateFrameTitle(panelName)
		if FrameTitle then
			FrameTitle.Text = PANEL_TITLES[panelName] or ""
		end
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- PANEL VISIBILITY
	--═══════════════════════════════════════════════════════════════════════════

	local function getMainFrame(panel)
		if not panel then return nil end
		return panel:FindFirstChild("mainFrame") or panel:FindFirstChild("MainFrame") or panel
	end

	local function hidePanelInstant(panelName)
		local panel = Panels[panelName]
		if not panel then return end

		local mainFrame = getMainFrame(panel)
		setDescendantsTransparency(mainFrame, 1)
		panel.Visible = false
	end

	local function hidePanelAnimated(panelName, callback)
		local panel = Panels[panelName]
		if not panel then 
			if callback then callback() end
			return 
		end

		local mainFrame = getMainFrame(panel)
		fadeDescendantsTo(mainFrame, 1, TweenConfig.panelFadeOut)

		task.delay(TweenConfig.panelFadeOut.Time, function()
			if State.currentPanel ~= panelName then
				panel.Visible = false
			end
			if callback then callback() end
		end)
	end

	local function showPanelAnimated(panelName)
		local panel = Panels[panelName]
		if not panel then return end

		local mainFrame = getMainFrame(panel)

		-- Start fully transparent
		setDescendantsTransparency(mainFrame, 1)

		-- Make visible
		panel.Visible = true

		-- Update title
		updateFrameTitle(panelName)

		-- Fade in
		fadeDescendantsTo(mainFrame, 0, TweenConfig.panelFadeIn)
	end
	


	--═══════════════════════════════════════════════════════════════════════════
	-- PANEL SWITCHING (SMOOTH TRANSITIONS)
	--═══════════════════════════════════════════════════════════════════════════

	local function openPanel(panelName)
		if State.isAnimating then return end
		if State.currentPanel == panelName then return end

		State.isAnimating = true

		-- Show TopHolder
		TopHolder.Visible = true

		-- If switching from another panel, hide it INSTANTLY (no overlap)
		if State.currentPanel then
			hidePanelInstant(State.currentPanel)
		end

		-- Play sound and show new panel
		playSound("open")
		State.currentPanel = panelName
		showPanelAnimated(panelName)

		-- Animation complete
		task.delay(TweenConfig.panelFadeIn.Time, function()
			State.isAnimating = false
		end)
	end

	local function closeCurrentPanel()
		if State.isAnimating then return end
		if not State.currentPanel then return end

		State.isAnimating = true
		playSound("close")

		local panelToClose = State.currentPanel
		State.currentPanel = nil

		hidePanelAnimated(panelToClose, function()
			-- Hide TopHolder after animation completes
			if State.currentPanel == nil then
				TopHolder.Visible = false
			end
			State.isAnimating = false
		end)
	end

	local function togglePanel(panelName)
		if State.currentPanel == panelName then
			closeCurrentPanel()
		else
			openPanel(panelName)
		end
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- BUTTON EFFECTS
	--═══════════════════════════════════════════════════════════════════════════

	local function setupButtonEffects(btnName, button)
		if not button then return end

		local originalSize = State.buttonOriginalSizes[button] or button.Size

		local hoverSize = UDim2.new(
			originalSize.X.Scale * 1.05,
			originalSize.X.Offset,
			originalSize.Y.Scale * 1.05,
			originalSize.Y.Offset
		)
		local pressSize = UDim2.new(
			originalSize.X.Scale * 0.95,
			originalSize.X.Offset,
			originalSize.Y.Scale * 0.95,
			originalSize.Y.Offset
		)

		local isHovering = false

		local enterConn = button.MouseEnter:Connect(function()
			isHovering = true
			playSound("hover")
			TweenService:Create(button, TweenConfig.buttonHover, {Size = hoverSize}):Play()
		end)
		table.insert(State.connections, enterConn)

		local leaveConn = button.MouseLeave:Connect(function()
			isHovering = false
			TweenService:Create(button, TweenConfig.buttonUnhover, {Size = originalSize}):Play()
		end)
		table.insert(State.connections, leaveConn)

		local downConn = button.MouseButton1Down:Connect(function()
			TweenService:Create(button, TweenConfig.buttonPress, {Size = pressSize}):Play()
		end)
		table.insert(State.connections, downConn)

		local upConn = button.MouseButton1Up:Connect(function()
			local targetSize = isHovering and hoverSize or originalSize
			TweenService:Create(button, TweenConfig.buttonRelease, {Size = targetSize}):Play()
		end)
		table.insert(State.connections, upConn)

		local clickConn = button.Activated:Connect(function()
			playSound("click")
			togglePanel(btnName)
		end)
		table.insert(State.connections, clickConn)
	end
	
	local function closePanelBtn()
		TopHolder.closeBtn.Activated:Connect(function()
			closeCurrentPanel()
		end)
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- INPUT
	--═══════════════════════════════════════════════════════════════════════════

	local function setupInput()
		local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.Escape then
				closeCurrentPanel()
			end
		end)
		table.insert(State.connections, inputConn)
	end
	

	--═══════════════════════════════════════════════════════════════════════════
	-- INITIAL STATE
	--═══════════════════════════════════════════════════════════════════════════

	local function setInitialState()
		TopHolder.Visible = false

		for panelName, panel in pairs(Panels) do
			if panel then
				panel.Visible = false
				local mainFrame = getMainFrame(panel)
				setDescendantsTransparency(mainFrame, 1)
			end
		end
	end

	--═══════════════════════════════════════════════════════════════════════════
	-- PUBLIC API
	--═══════════════════════════════════════════════════════════════════════════

	function TopbarController:Init()
		if not setupReferences() then 
			warn("[TopBarController] Failed to setup references")
			return 
		end

		setInitialState()
		setupInput()
		closePanelBtn()

		for btnName, button in pairs(Buttons) do
			setupButtonEffects(btnName, button)
		end
	end

	function TopbarController:Open(panelName)
		openPanel(panelName)
	end

	function TopbarController:Close()
		closeCurrentPanel()
	end

	function TopbarController:Toggle(panelName)
		togglePanel(panelName)
	end

	function TopbarController:GetCurrentPanel()
		return State.currentPanel
	end

	function TopbarController:IsOpen()
		return State.currentPanel ~= nil
	end

	function TopbarController:Cleanup()
		for _, conn in ipairs(State.connections) do
			conn:Disconnect()
		end
		State.connections = {}
		for _, sound in pairs(Sounds) do
			sound:Destroy()
		end
	end

	return TopbarController
end