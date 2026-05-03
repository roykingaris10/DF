return function(Client)
	local MenuClient = {}
	local player = Client.player
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local SoundService = game:GetService("SoundService")
	local ContentProvider = game:GetService("ContentProvider")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Lighting = game:GetService("Lighting")
	local PlayerGui = player:WaitForChild("PlayerGui")
	local isOpen = false
	local isAnimating = false
	local connections = {}
	local hoverConnections = {}
	local activeTweens = {}

	local closeCurrentScreen
	local openScreen
	local toggleScreen


	local MenuBlurTemplate = ReplicatedStorage:WaitForChild("Kits"):WaitForChild("UI"):WaitForChild("MenuBlur")
	local activeBlur = nil

	local function fadeInBlur()
		if activeBlur then
			activeBlur:Destroy()
		end

		activeBlur = MenuBlurTemplate:Clone()
		activeBlur.Size = 0
		activeBlur.Parent = Lighting

		local blurTween = TweenService:Create(activeBlur, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = MenuBlurTemplate.Size
		})
		blurTween:Play()
		table.insert(activeTweens, blurTween)
	end

	local function fadeOutBlur()
		if not activeBlur then return end

		local blur = activeBlur
		local blurTween = TweenService:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Size = 0
		})
		blurTween:Play()
		table.insert(activeTweens, blurTween)

		blurTween.Completed:Connect(function()
			if blur then
				blur:Destroy()
			end
		end)

		activeBlur = nil
	end

	local hoverSound = Instance.new("Sound")
	hoverSound.SoundId = "rbxassetid://103866342467024"
	hoverSound.Volume = 0.3
	hoverSound.Parent = SoundService

	local clickSound = Instance.new("Sound")
	clickSound.SoundId = "rbxassetid://10128766965"
	clickSound.Volume = 0.5
	clickSound.Parent = SoundService

	ContentProvider:PreloadAsync({hoverSound, clickSound})

	local function playHoverSound()
		hoverSound:Stop()
		hoverSound:Play()
	end

	local function playClickSound()
		clickSound:Stop()
		clickSound:Play()
	end


	local TweenConfig = {
		fadeIn = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		fadeOut = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),

		lineIn = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		lineFadeOut = TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In),

		hoverIn = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		hoverOut = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In),

		divExpand = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		divCollapse = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In),

		press = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		release = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),

		flashFade = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	}

	local STAGGER_DELAY = 0.05
	local CLOSE_STAGGER_DELAY = 0.035
	local LINE_DELAY = 0.1


	local UI
	local MenuHolder
	local MenuFrame
	local line
	local holderData = {}

	local holderNames = {
		"profileHolder",
		"invHolder",
		"treeHolder",
		"progHolder",
		"crewHolder",
	}

	local function getFrameName(holderName)
		return holderName:gsub("Holder", "Frame")
	end

	local function setupReferences()
		UI = PlayerGui:WaitForChild("UI")
		MenuHolder = UI:WaitForChild("MenuHolder")
		MenuFrame = MenuHolder:WaitForChild("MenuFrame")
		line = MenuHolder:FindFirstChild("line")

		holderData = {}

		for _, holderName in ipairs(holderNames) do
			local holder = MenuFrame:FindFirstChild(holderName)
			if holder then
				local frameName = getFrameName(holderName)
				local frame = holder:FindFirstChild(frameName)
				local btn = holder:FindFirstChild("btn")
				local click = btn and btn:FindFirstChild("click")

				local data = {
					holder = holder,
					frame = frame,
					btn = btn,
					click = click,
					clickOriginalColor = click and click.ImageColor3 or Color3.new(0, 0, 0),
					imageLabel = holder:FindFirstChild("ImageLabel"),
					white = holder:FindFirstChild("white"),
					title = frame and frame:FindFirstChild("title"),
					desc = frame and frame:FindFirstChild("desc"),
					div = frame and frame:FindFirstChild("div"),
					isHovered = false,
					originalDivSize = nil,
				}

				if data.div then
					data.originalDivSize = data.div.Size
				end

				table.insert(holderData, data)
			end
		end
	end


	local function cancelAllTweens()
		for _, tween in ipairs(activeTweens) do
			if tween then
				tween:Cancel()
			end
		end
		activeTweens = {}
	end

	local function playTween(obj, info, props)
		if not obj then return nil end
		local tween = TweenService:Create(obj, info, props)
		tween:Play()
		table.insert(activeTweens, tween)
		return tween
	end

	local function setInitialState()
		MenuHolder.Visible = false

		if line then
			line.BackgroundTransparency = 1
			if line:IsA("ImageLabel") then
				line.ImageTransparency = 1
			end
			line.Size = UDim2.new(1, 0, 0, 0)
		end

		for _, data in ipairs(holderData) do
			if data.btn then
				data.btn.ImageTransparency = 1
			end

			if data.click then
				data.click.ImageTransparency = 1
				data.click.ImageColor3 = data.clickOriginalColor
			end

			if data.imageLabel then
				data.imageLabel.ImageTransparency = 1
			end

			if data.white then
				data.white.BackgroundTransparency = 1
				if data.white:IsA("ImageLabel") then
					data.white.ImageTransparency = 1
				end
			end

			if data.title then
				data.title.TextTransparency = 1
			end
			if data.desc then
				data.desc.TextTransparency = 1
			end

			if data.div and data.originalDivSize then
				data.div.BackgroundTransparency = 1
				data.div.Size = UDim2.new(0, 0, data.originalDivSize.Y.Scale, data.originalDivSize.Y.Offset)
			end

			data.isHovered = false
		end
	end

	local function openMenu()
		if isAnimating or isOpen then return end

		isAnimating = true
		isOpen = true

		cancelAllTweens()
		MenuHolder.Visible = true

		fadeInBlur()

		if line then
			line.Size = UDim2.new(1, 0, 0, 0)
			if line:IsA("ImageLabel") then
				line.ImageTransparency = 1
			else
				line.BackgroundTransparency = 1
			end

			task.delay(LINE_DELAY, function()
				if not isOpen then return end
				if line:IsA("ImageLabel") then
					playTween(line, TweenConfig.lineIn, {
						ImageTransparency = 0,
						Size = UDim2.new(1, 0, 1.018, 0)
					})
				else
					playTween(line, TweenConfig.lineIn, {
						BackgroundTransparency = 0,
						Size = UDim2.new(1, 0, 1.018, 0)
					})
				end
			end)
		end

		for i, data in ipairs(holderData) do
			task.delay((i - 1) * STAGGER_DELAY, function()
				if not isOpen then return end

				if data.btn then
					data.btn.ImageTransparency = 1
					playTween(data.btn, TweenConfig.fadeIn, {ImageTransparency = 0})
				end

				if data.imageLabel then
					task.delay(0.08, function()
						if not isOpen then return end
						data.imageLabel.ImageTransparency = 1
						playTween(data.imageLabel, TweenConfig.fadeIn, {ImageTransparency = 0})
					end)
				end
			end)
		end

		local totalTime = (#holderData * STAGGER_DELAY) + 0.4
		task.delay(totalTime, function()
			if isOpen then
				isAnimating = false
			end
		end)
	end

	local function closeMenu()
		if isAnimating or not isOpen then return end
		isAnimating = true
		isOpen = false

		cancelAllTweens()

		fadeOutBlur()

		-- Line just fades out, no size change during fade
		if line then
			task.delay(LINE_DELAY * 0.5, function()
				if isOpen then return end

				local lineFadeTween
				if line:IsA("ImageLabel") then
					lineFadeTween = playTween(line, TweenConfig.lineFadeOut, {
						ImageTransparency = 1
					})
				else
					lineFadeTween = playTween(line, TweenConfig.lineFadeOut, {
						BackgroundTransparency = 1
					})
				end

				-- Reset size after fade completes
				if lineFadeTween then
					lineFadeTween.Completed:Connect(function()
						line.Size = UDim2.new(1, 0, 0, 0)
					end)
				end
			end)
		end

		for i = #holderData, 1, -1 do
			local data = holderData[i]
			local delay = (#holderData - i) * CLOSE_STAGGER_DELAY

			task.delay(delay, function()
				if isOpen then return end

				if data.btn then
					playTween(data.btn, TweenConfig.fadeOut, {ImageTransparency = 1})
				end

				if data.click then
					data.click.ImageColor3 = data.clickOriginalColor
					playTween(data.click, TweenConfig.fadeOut, {ImageTransparency = 1})
				end

				if data.imageLabel then
					playTween(data.imageLabel, TweenConfig.fadeOut, {ImageTransparency = 1})
				end

				if data.white then
					if data.white:IsA("ImageLabel") then
						playTween(data.white, TweenConfig.fadeOut, {ImageTransparency = 1})
					else
						playTween(data.white, TweenConfig.fadeOut, {BackgroundTransparency = 1})
					end
				end

				if data.title then
					playTween(data.title, TweenConfig.fadeOut, {TextTransparency = 1})
				end

				if data.desc then
					playTween(data.desc, TweenConfig.fadeOut, {TextTransparency = 1})
				end

				if data.div and data.originalDivSize then
					playTween(data.div, TweenConfig.divCollapse, {
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 0, data.originalDivSize.Y.Scale, data.originalDivSize.Y.Offset)
					})
				end

				data.isHovered = false
			end)
		end

		local totalTime = (#holderData * CLOSE_STAGGER_DELAY) + 0.5
		task.delay(totalTime, function()
			if not isOpen then
				MenuHolder.Visible = false
				isAnimating = false
			end
		end)
	end

	local function onHoverEnter(data)
		if not isOpen or isAnimating then return end
		if data.isHovered then return end
		data.isHovered = true

		playHoverSound()

		if data.click then
			playTween(data.click, TweenConfig.hoverIn, {ImageTransparency = 0.85})
		end

		if data.white then
			if data.white:IsA("ImageLabel") then
				playTween(data.white, TweenConfig.hoverIn, {ImageTransparency = 0})
			else
				playTween(data.white, TweenConfig.hoverIn, {BackgroundTransparency = 0})
			end
		end

		if data.title then
			playTween(data.title, TweenConfig.hoverIn, {TextTransparency = 0})
		end

		if data.desc then
			task.delay(0.05, function()
				if data.isHovered and isOpen then
					playTween(data.desc, TweenConfig.hoverIn, {TextTransparency = 0.2})
				end
			end)
		end

		if data.div and data.originalDivSize then
			playTween(data.div, TweenConfig.hoverIn, {BackgroundTransparency = 0})
			playTween(data.div, TweenConfig.divExpand, {
				Size = UDim2.new(1.26, 0, data.originalDivSize.Y.Scale, data.originalDivSize.Y.Offset)
			})
		end
	end

	local function onHoverLeave(data)
		if not data.isHovered then return end
		data.isHovered = false

		if data.click then
			playTween(data.click, TweenConfig.hoverOut, {ImageTransparency = 1})
		end

		if data.white then
			if data.white:IsA("ImageLabel") then
				playTween(data.white, TweenConfig.hoverOut, {ImageTransparency = 1})
			else
				playTween(data.white, TweenConfig.hoverOut, {BackgroundTransparency = 1})
			end
		end

		if data.title then
			playTween(data.title, TweenConfig.hoverOut, {TextTransparency = 1})
		end

		if data.desc then
			playTween(data.desc, TweenConfig.hoverOut, {TextTransparency = 1})
		end

		if data.div and data.originalDivSize then
			playTween(data.div, TweenConfig.divCollapse, {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 0, data.originalDivSize.Y.Scale, data.originalDivSize.Y.Offset)
			})
		end
	end

	local openSound = Instance.new("Sound")
	openSound.SoundId = "rbxassetid://10128766965"
	openSound.Volume = 0.45
	openSound.Parent = SoundService

	local function playOpenSound()
		openSound:Stop()
		openSound:Play()
	end

	local profileAncestors = {}

	local function openProfileFrame()
		if not UI then return end

		local ProfileFrame = UI:FindFirstChild("ProfileFrame", true)
		if not ProfileFrame then
			warn("[MenuClient] ProfileFrame not found anywhere under UI")
			return
		end

		profileAncestors = {}
		local parent = ProfileFrame.Parent
		while parent and parent ~= UI do
			if parent:IsA("GuiObject") then
				if not parent.Visible then
					table.insert(profileAncestors, parent)
				end
				parent.Visible = true
			end
			parent = parent.Parent
		end

		ProfileFrame.Visible = true
		playOpenSound()

		if Client.ProfileClient and Client.ProfileClient.OpenProfile then
			Client.ProfileClient:OpenProfile()
		end
	end

	local function closeProfileFrame()
		if not UI then return end
		local ProfileFrame = UI:FindFirstChild("ProfileFrame", true)
		if Client.ProfileClient and Client.ProfileClient.CloseProfile then
			Client.ProfileClient:CloseProfile()
		end
		if ProfileFrame then ProfileFrame.Visible = false end

		for _, ancestor in ipairs(profileAncestors) do
			if ancestor and ancestor.Parent then
				ancestor.Visible = false
			end
		end
		profileAncestors = {}
	end

	local function openQuestLogFrame()
		if not UI then return end
		local QuestLogFrame = UI:FindFirstChild("QuestLogFrame")
		if not QuestLogFrame then
			warn("[MenuClient] UI.QuestLogFrame not found")
			return
		end

		QuestLogFrame.Visible = true
		playOpenSound()
	end

	local function closeQuestLogFrame()
		if not UI then return end
		local QuestLogFrame = UI:FindFirstChild("QuestLogFrame")
		if not QuestLogFrame then return end
		QuestLogFrame.Visible = false
	end

	local function openInventoryFrame()
		if Client.UISetup and Client.UISetup.OpenCoreMenu then
			Client.UISetup:OpenCoreMenu()
		end
		playOpenSound()
	end

	local function closeInventoryFrame()
		if Client.UISetup and Client.UISetup.CloseCoreMenu then
			Client.UISetup:CloseCoreMenu()
		end
	end

	local screens = {
		profile   = { open = openProfileFrame,   close = closeProfileFrame },
		questlog  = { open = openQuestLogFrame,  close = closeQuestLogFrame },
		inventory = { open = openInventoryFrame, close = closeInventoryFrame },
	}

	local currentScreen = nil

	closeCurrentScreen = function()
		if not currentScreen then return end
		local s = screens[currentScreen]
		currentScreen = nil
		if s and s.close then
			s.close()
		end
	end

	openScreen = function(name)
		if currentScreen == name then return end
		if currentScreen then
			local prev = screens[currentScreen]
			if prev and prev.close then prev.close() end
		end
		local s = screens[name]
		if not s or not s.open then return end
		currentScreen = name
		s.open()
	end

	toggleScreen = function(name)
		if currentScreen == name then
			closeCurrentScreen()
		else
			openScreen(name)
		end
	end

	local function onButtonClick(data)
		if not isOpen then return end

		playClickSound()

		if data.click then
			data.click.ImageColor3 = Color3.new(0, 0, 0)
			data.click.ImageTransparency = 0.5

			task.delay(0.08, function()
				local targetTrans = data.isHovered and 0.85 or 1
				playTween(data.click, TweenConfig.flashFade, {
					ImageTransparency = targetTrans,
					ImageColor3 = data.clickOriginalColor
				})
			end)
		end

		if data.btn then
			local originalSize = data.btn.Size
			playTween(data.btn, TweenConfig.press, {
				Size = UDim2.new(
					originalSize.X.Scale * 0.95,
					originalSize.X.Offset,
					originalSize.Y.Scale * 0.95,
					originalSize.Y.Offset
				)
			})

			task.delay(0.08, function()
				playTween(data.btn, TweenConfig.release, {
					Size = originalSize
				})
			end)
		end

		local holderName = data.holder and data.holder.Name

		task.delay(0.15, function()
			closeMenu()
		end)

		if holderName == "profileHolder" then
			task.delay(0.22, function() openScreen("profile") end)
		elseif holderName == "progHolder" then
			task.delay(0.22, function() openScreen("questlog") end)
		elseif holderName == "invHolder" then
			task.delay(0.22, function() openScreen("inventory") end)
		end

		print("[Menu] Clicked:", holderName)
	end

	local function setupHoverEffects()
		for _, conn in ipairs(hoverConnections) do
			conn:Disconnect()
		end
		hoverConnections = {}

		for _, data in ipairs(holderData) do
			if data.btn then
				local enterConn = data.btn.MouseEnter:Connect(function()
					onHoverEnter(data)
				end)
				table.insert(hoverConnections, enterConn)

				local leaveConn = data.btn.MouseLeave:Connect(function()
					onHoverLeave(data)
				end)
				table.insert(hoverConnections, leaveConn)

				local clickConn = data.btn.Activated:Connect(function()
					onButtonClick(data)
				end)
				table.insert(hoverConnections, clickConn)
			end

			if data.holder then
				local holderEnter = data.holder.MouseEnter:Connect(function()
					onHoverEnter(data)
				end)
				table.insert(hoverConnections, holderEnter)

				local holderLeave = data.holder.MouseLeave:Connect(function()
					onHoverLeave(data)
				end)
				table.insert(hoverConnections, holderLeave)
			end
		end
	end

	local function toggleMenu()
		if isOpen then
			closeMenu()
		else
			openMenu()
		end
	end

	local function setupInput()
		local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.M then
				toggleMenu()
			elseif input.KeyCode == Enum.KeyCode.Escape then
				if currentScreen then
					closeCurrentScreen()
				elseif isOpen then
					closeMenu()
				end
			end
		end)
		table.insert(connections, inputConn)
	end

	local function cleanup()
		cancelAllTweens()

		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		for _, conn in ipairs(hoverConnections) do
			conn:Disconnect()
		end

		if activeBlur then
			activeBlur:Destroy()
			activeBlur = nil
		end

		hoverSound:Destroy()
		clickSound:Destroy()

		connections = {}
		hoverConnections = {}
		holderData = {}
	end

	function MenuClient:Init()
		setupReferences()
		setInitialState()
		setupHoverEffects()
		setupInput()

		local ancestryConn
		ancestryConn = PlayerGui.UI.AncestryChanged:Connect(function(_, parent)
			if not parent then
				cleanup()
				if ancestryConn then
					ancestryConn:Disconnect()
				end
			end
		end)
	end

	function MenuClient:Open()
		openMenu()
	end

	function MenuClient:Close()
		closeMenu()
	end

	function MenuClient:Toggle()
		toggleMenu()
	end

	function MenuClient:OpenScreen(name)
		openScreen(name)
	end

	function MenuClient:CloseScreen()
		closeCurrentScreen()
	end

	function MenuClient:ToggleScreen(name)
		toggleScreen(name)
	end

	function MenuClient:GetCurrentScreen()
		return currentScreen
	end

	function MenuClient:IsOpen()
		return isOpen
	end

	function MenuClient:IsAnimating()
		return isAnimating
	end

	return MenuClient
end