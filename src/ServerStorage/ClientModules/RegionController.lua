return function(Client)
	local player = Client.player
	local TweenService = game:GetService("TweenService")
	local SoundService = game:GetService("SoundService")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local RegionConfig = require(ReplicatedStorage.Kits.Nodes.Data.RegionConfig)
	local AudioDirector = require(ReplicatedStorage.Kits.Audio.AudioDirector)
	local PlayerGui = player:WaitForChild("PlayerGui")

	local RegionController = {
		currentRegion = nil,
		currentRegionType = nil,
		currentConfig = nil,

		-- Chatter (stays here - it's ambient SFX, not music)
		chatterConnection = nil,

		enterUIVisible = false,
		leaveUIVisible = false,
		hideEnterTask = nil,
		hideLeaveTask = nil,

		typewriterConnection = nil,
		dotConnection = nil,
		wheelConnection = nil,
		flipbookConnection = nil,

		wheelSpeedDegPerSec = 90,
		flipbookFrameRate = 12,
		showCounter = 0,

		glitchBox = nil,
		leaveGui = nil,
	}

	local function safeCancel(thread)
		if thread then
			pcall(function() task.cancel(thread) end)
		end
	end

	local function getUI()
		local gui = PlayerGui:FindFirstChild("Region")
		if not gui then return nil end

		local regionFrame = gui:FindFirstChild("RegionFrame")
		if not regionFrame then return nil end

		local textFrame = regionFrame:FindFirstChild("TextFrame")
		local fade = regionFrame:FindFirstChild("FADE")
		local wheel = regionFrame:FindFirstChild("Wheel")
		local fishFlip = regionFrame:FindFirstChild("FishFlip")

		local enteringText = textFrame and textFrame:FindFirstChild("EnteringText")
		local regionText = textFrame and textFrame:FindFirstChild("RegionText")
		local sloganText = textFrame and textFrame:FindFirstChild("SloganText")

		return {
			gui = gui,
			regionFrame = regionFrame,
			textFrame = textFrame,
			fade = fade,
			wheel = wheel,
			fishFlip = fishFlip,
			enteringText = enteringText,
			regionText = regionText,
			sloganText = sloganText,
		}
	end

	local function getLeaveUI()
		local gui = RegionController.leaveGui
		if not gui or not gui.Parent then return nil end

		local holder = gui:FindFirstChild("LeaveHolder")
		if not holder then return nil end

		return {
			holder = holder,
			leavingLabel = holder:FindFirstChild("LeavingLabel"),
			townName = holder:FindFirstChild("TownName"),
		}
	end

	local function createLeaveUI()
		if RegionController.leaveGui and RegionController.leaveGui.Parent then
			return getLeaveUI()
		end

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "RegionLeaveUI"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.DisplayOrder = 99
		screenGui.Parent = PlayerGui

		local holder = Instance.new("Frame")
		holder.Name = "LeaveHolder"
		holder.AnchorPoint = Vector2.new(0, 1)
		holder.Position = UDim2.new(0.05, 0, 0.92, 0)
		holder.Size = UDim2.new(0.3, 0, 0.05, 0)
		holder.BackgroundTransparency = 1
		holder.Parent = screenGui

		local leavingLabel = Instance.new("TextLabel")
		leavingLabel.Name = "LeavingLabel"
		leavingLabel.Position = UDim2.new(0, 0, 0, 0)
		leavingLabel.Size = UDim2.new(1, 0, 0.4, 0)
		leavingLabel.BackgroundTransparency = 1
		leavingLabel.Font = Enum.Font.Merriweather
		leavingLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		leavingLabel.TextXAlignment = Enum.TextXAlignment.Left
		leavingLabel.TextScaled = true
		leavingLabel.TextTransparency = 1
		leavingLabel.Text = "LEAVING"
		leavingLabel.Parent = holder

		local leavingStroke = Instance.new("UIStroke")
		leavingStroke.Thickness = 1
		leavingStroke.Color = Color3.fromRGB(0, 0, 0)
		leavingStroke.Transparency = 1
		leavingStroke.Parent = leavingLabel

		local townName = Instance.new("TextLabel")
		townName.Name = "TownName"
		townName.Position = UDim2.new(0, 0, 0.45, 0)
		townName.Size = UDim2.new(1, 0, 0.55, 0)
		townName.BackgroundTransparency = 1
		townName.Font = Enum.Font.Merriweather
		townName.TextColor3 = Color3.fromRGB(220, 220, 220)
		townName.TextXAlignment = Enum.TextXAlignment.Left
		townName.TextScaled = true
		townName.TextTransparency = 1
		townName.Text = ""
		townName.Parent = holder

		local townStroke = Instance.new("UIStroke")
		townStroke.Thickness = 1
		townStroke.Color = Color3.fromRGB(0, 0, 0)
		townStroke.Transparency = 1
		townStroke.Parent = townName

		RegionController.leaveGui = screenGui

		return {
			holder = holder,
			leavingLabel = leavingLabel,
			townName = townName,
		}
	end

	local function destroyGlitchBox()
		if RegionController.glitchBox then
			RegionController.glitchBox:Destroy()
			RegionController.glitchBox = nil
		end
	end

	local function createGlitchBox(parent)
		destroyGlitchBox()

		local box = Instance.new("Frame")
		box.Name = "GlitchBox"
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.new(0, 0, 0.5, 0)
		box.Size = UDim2.new(0, 10, 0, 10)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 0
		box.ZIndex = 10
		box.Parent = parent

		RegionController.glitchBox = box
		return box
	end

	local function stopWheel()
		if RegionController.wheelConnection then
			RegionController.wheelConnection:Disconnect()
			RegionController.wheelConnection = nil
		end
	end

	local function startWheel(wheel)
		stopWheel()
		if not wheel then return end

		RegionController.wheelConnection = RunService.Heartbeat:Connect(function(dt)
			if not wheel or not wheel.Parent then
				stopWheel()
				return
			end
			wheel.Rotation = (wheel.Rotation + (RegionController.wheelSpeedDegPerSec * dt)) % 360
		end)
	end

	local function reverseWheel(wheel)
		stopWheel()
		if not wheel then return end

		RegionController.wheelConnection = RunService.Heartbeat:Connect(function(dt)
			if not wheel or not wheel.Parent then
				stopWheel()
				return
			end
			wheel.Rotation = (wheel.Rotation - (RegionController.wheelSpeedDegPerSec * dt)) % 360
		end)
	end

	local function stopFlipbook()
		if RegionController.flipbookConnection then
			RegionController.flipbookConnection:Disconnect()
			RegionController.flipbookConnection = nil
		end
	end

	local function hideAllFlipbookFrames(fishFlip)
		if not fishFlip then return end
		for i = 1, 8 do
			local frame = fishFlip:FindFirstChild(tostring(i))
			if frame then
				frame.Visible = false
			end
		end
	end

	local function startFlipbook(fishFlip)
		stopFlipbook()
		if not fishFlip then return end

		local frames = {}
		for i = 1, 8 do
			local frame = fishFlip:FindFirstChild(tostring(i))
			if frame then
				frame.Visible = false
				table.insert(frames, frame)
			end
		end

		if #frames == 0 then return end

		local currentFrame = 1
		local lastFrameTime = tick()

		frames[1].Visible = true

		RegionController.flipbookConnection = RunService.Heartbeat:Connect(function()
			if not fishFlip or not fishFlip.Parent then
				stopFlipbook()
				return
			end

			local now = tick()
			if now - lastFrameTime >= (1 / RegionController.flipbookFrameRate) then
				if frames[currentFrame] then
					frames[currentFrame].Visible = false
				end

				currentFrame = currentFrame + 1
				if currentFrame > #frames then
					currentFrame = 1
				end

				if frames[currentFrame] then
					frames[currentFrame].Visible = true
				end

				lastFrameTime = now
			end
		end)
	end

	local function setFlipbookTransparency(fishFlip, transparency)
		if not fishFlip then return end
		for i = 1, 8 do
			local frame = fishFlip:FindFirstChild(tostring(i))
			if frame and frame:IsA("ImageLabel") then
				frame.ImageTransparency = transparency
			end
		end
	end

	local function tweenFlipbookTransparency(fishFlip, targetTransparency, duration)
		if not fishFlip then return end
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		for i = 1, 8 do
			local frame = fishFlip:FindFirstChild(tostring(i))
			if frame and frame:IsA("ImageLabel") then
				TweenService:Create(frame, tweenInfo, {ImageTransparency = targetTransparency}):Play()
			end
		end
	end

	local function stopTypewriter()
		if RegionController.typewriterConnection then
			RegionController.typewriterConnection:Disconnect()
			RegionController.typewriterConnection = nil
		end
	end

	local function stopDotting()
		if RegionController.dotConnection then
			RegionController.dotConnection:Disconnect()
			RegionController.dotConnection = nil
		end
	end

	local function typewriterEffect(label, targetText, charDelay, onComplete)
		stopTypewriter()
		destroyGlitchBox()

		if not label then
			if onComplete then onComplete() end
			return
		end

		local glitchBox = createGlitchBox(label)

		charDelay = charDelay or 0.04
		local length = #targetText
		local currentIndex = 0
		local lastTime = tick()
		local phase = 0

		label.Text = ""

		RegionController.typewriterConnection = RunService.Heartbeat:Connect(function()
			local now = tick()
			local elapsed = now - lastTime

			if currentIndex < length then
				if phase == 0 then
					local progress = (currentIndex + 1) / length
					glitchBox.Position = UDim2.new(math.min(progress * 0.9, 0.9), 0, 0.5, 0)
					glitchBox.BackgroundTransparency = 0
					phase = 1
					lastTime = now
				elseif phase == 1 and elapsed >= 0.02 then
					glitchBox.BackgroundTransparency = 0.5
					phase = 2
					lastTime = now
				elseif phase == 2 and elapsed >= 0.02 then
					currentIndex = currentIndex + 1
					label.Text = string.sub(targetText, 1, currentIndex)
					glitchBox.BackgroundTransparency = 1
					phase = 0
					lastTime = now + charDelay
				end
			else
				label.Text = targetText
				stopTypewriter()
				destroyGlitchBox()
				if onComplete then onComplete() end
			end
		end)
	end

	local function dottingEffect(label, baseText, duration)
		stopDotting()
		if not label then return end

		local startTime = tick()
		local lastDotCount = -1

		RegionController.dotConnection = RunService.Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			if elapsed > duration then
				stopDotting()
				return
			end

			local dotCount = math.floor((elapsed * 3) % 4)
			if dotCount ~= lastDotCount then
				lastDotCount = dotCount
				label.Text = baseText .. string.rep(".", dotCount)
			end
		end)
	end

	local function resetEnterUI()
		local ui = getUI()
		if not ui then return end

		if ui.textFrame then ui.textFrame.Visible = false end
		if ui.fade then
			ui.fade.Visible = false
			ui.fade.ImageTransparency = 1
		end
		if ui.wheel then
			ui.wheel.Visible = false
			ui.wheel.ImageTransparency = 1
		end
		if ui.fishFlip then
			ui.fishFlip.Visible = false
			hideAllFlipbookFrames(ui.fishFlip)
			setFlipbookTransparency(ui.fishFlip, 1)
		end
		if ui.enteringText then
			ui.enteringText.Text = "ENTERING"
			ui.enteringText.TextTransparency = 1
			local stroke = ui.enteringText:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = 1 end
		end
		if ui.regionText then
			ui.regionText.Text = ""
			ui.regionText.TextTransparency = 1
			local stroke = ui.regionText:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = 1 end
		end
		if ui.sloganText then
			ui.sloganText.Text = ""
			ui.sloganText.TextTransparency = 1
			local stroke = ui.sloganText:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = 1 end
		end
	end

	local function hideEnterUI(instant)
		stopTypewriter()
		destroyGlitchBox()
		safeCancel(RegionController.hideEnterTask)
		RegionController.hideEnterTask = nil
		RegionController.enterUIVisible = false

		local ui = getUI()
		if not ui then return end

		if instant then
			if ui.textFrame then ui.textFrame.Visible = false end
			if ui.wheel then ui.wheel.Visible = false end
			if ui.fade then ui.fade.Visible = false end
			if ui.fishFlip then
				ui.fishFlip.Visible = false
				hideAllFlipbookFrames(ui.fishFlip)
			end
			if ui.enteringText then ui.enteringText.TextTransparency = 1 end
			if ui.regionText then ui.regionText.TextTransparency = 1 end
			if ui.sloganText then ui.sloganText.TextTransparency = 1 end
			stopWheel()
			stopFlipbook()
			return
		end

		local tweenFast = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		local tweenMed = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

		if ui.sloganText then
			TweenService:Create(ui.sloganText, tweenFast, {TextTransparency = 1}):Play()
			local stroke = ui.sloganText:FindFirstChildOfClass("UIStroke")
			if stroke then TweenService:Create(stroke, tweenFast, {Transparency = 1}):Play() end
		end

		task.delay(0.15, function()
			local ui2 = getUI()
			if ui2 and ui2.regionText then
				TweenService:Create(ui2.regionText, tweenMed, {TextTransparency = 1}):Play()
				local stroke = ui2.regionText:FindFirstChildOfClass("UIStroke")
				if stroke then TweenService:Create(stroke, tweenMed, {Transparency = 1}):Play() end
			end
		end)

		task.delay(0.3, function()
			local ui2 = getUI()
			if ui2 and ui2.enteringText then
				TweenService:Create(ui2.enteringText, tweenFast, {TextTransparency = 1}):Play()
				local stroke = ui2.enteringText:FindFirstChildOfClass("UIStroke")
				if stroke then TweenService:Create(stroke, tweenFast, {Transparency = 1}):Play() end
			end
		end)

		task.delay(0.4, function()
			local ui2 = getUI()
			if ui2 and ui2.fade then
				TweenService:Create(ui2.fade, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					ImageTransparency = 1
				}):Play()
			end
		end)

		task.delay(0.2, function()
			local ui2 = getUI()
			if ui2 then
				if ui2.wheel then
					reverseWheel(ui2.wheel)
					TweenService:Create(ui2.wheel, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
						ImageTransparency = 1
					}):Play()
				end
				if ui2.fishFlip then
					tweenFlipbookTransparency(ui2.fishFlip, 1, 0.4)
				end
			end

			task.delay(0.5, function()
				stopWheel()
				stopFlipbook()
			end)
		end)

		task.delay(1.0, function()
			if RegionController.enterUIVisible then return end
			local ui2 = getUI()
			if ui2 then
				if ui2.textFrame then ui2.textFrame.Visible = false end
				if ui2.wheel then ui2.wheel.Visible = false end
				if ui2.fade then ui2.fade.Visible = false end
				if ui2.fishFlip then
					ui2.fishFlip.Visible = false
					hideAllFlipbookFrames(ui2.fishFlip)
				end
			end
		end)
	end

	local function hideLeaveUI(instant)
		stopDotting()
		safeCancel(RegionController.hideLeaveTask)
		RegionController.hideLeaveTask = nil
		RegionController.leaveUIVisible = false

		local ui = getLeaveUI()
		if not ui then return end

		local duration = instant and 0 or 0.3
		local tweenOut = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

		if ui.leavingLabel then
			TweenService:Create(ui.leavingLabel, tweenOut, {TextTransparency = 1}):Play()
			local stroke = ui.leavingLabel:FindFirstChildOfClass("UIStroke")
			if stroke then TweenService:Create(stroke, tweenOut, {Transparency = 1}):Play() end
		end

		if ui.townName then
			TweenService:Create(ui.townName, tweenOut, {TextTransparency = 1}):Play()
			local stroke = ui.townName:FindFirstChildOfClass("UIStroke")
			if stroke then TweenService:Create(stroke, tweenOut, {Transparency = 1}):Play() end
		end
	end

	local function showEnterUI(regionName, regionType, config)
		RegionController.showCounter = RegionController.showCounter + 1
		local myCounter = RegionController.showCounter

		hideLeaveUI(true)
		hideEnterUI(true)

		local ui = getUI()
		if not ui then
			warn("[RegionController] UI not found")
			return
		end

		resetEnterUI()
		RegionController.enterUIVisible = true

		local displayName = string.upper(config.DisplayName or regionName)
		local subtitleText = string.upper(config.Subtitle or "")

		if ui.textFrame then ui.textFrame.Visible = true end

		if ui.fishFlip then
			ui.fishFlip.Visible = true
			setFlipbookTransparency(ui.fishFlip, 1)
			tweenFlipbookTransparency(ui.fishFlip, 0, 0.5)
			startFlipbook(ui.fishFlip)
		end

		if ui.wheel then
			ui.wheel.Visible = true
			ui.wheel.ImageTransparency = 1
			TweenService:Create(ui.wheel, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				ImageTransparency = 0
			}):Play()
			startWheel(ui.wheel)
		end

		if ui.fade then
			ui.fade.Visible = true
			ui.fade.ImageTransparency = 1
			TweenService:Create(ui.fade, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageTransparency = 0
			}):Play()
		end

		if ui.enteringText then
			ui.enteringText.TextTransparency = 1
			TweenService:Create(ui.enteringText, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				TextTransparency = 0.2
			}):Play()
			local stroke = ui.enteringText:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = 1
				TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0.5}):Play()
			end
		end

		if ui.regionText then
			ui.regionText.Text = ""
			ui.regionText.TextTransparency = 0
			local stroke = ui.regionText:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = 0.3 end
		end

		task.delay(0.3, function()
			if RegionController.showCounter ~= myCounter then return end
			if not RegionController.enterUIVisible then return end

			local ui2 = getUI()
			if not ui2 or not ui2.regionText then return end

			typewriterEffect(ui2.regionText, displayName, 0.04, function()
				if RegionController.showCounter ~= myCounter then return end
				if not RegionController.enterUIVisible then return end

				if subtitleText ~= "" then
					task.delay(0.15, function()
						if RegionController.showCounter ~= myCounter then return end
						if not RegionController.enterUIVisible then return end

						local ui3 = getUI()
						if not ui3 or not ui3.sloganText then return end

						ui3.sloganText.Text = subtitleText
						TweenService:Create(ui3.sloganText, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
							TextTransparency = 0.2
						}):Play()
						local stroke = ui3.sloganText:FindFirstChildOfClass("UIStroke")
						if stroke then
							TweenService:Create(stroke, TweenInfo.new(0.4), {Transparency = 0.5}):Play()
						end
					end)
				end
			end)
		end)

		RegionController.hideEnterTask = task.delay(5, function()
			if RegionController.showCounter ~= myCounter then return end
			if RegionController.enterUIVisible then
				hideEnterUI(false)
			end
			RegionController.hideEnterTask = nil
		end)
	end

	local function showLeaveUI(regionName, config)
		RegionController.showCounter = RegionController.showCounter + 1

		hideEnterUI(true)
		hideLeaveUI(true)

		local ui = getLeaveUI()
		if not ui then
			ui = createLeaveUI()
		end
		if not ui then return end

		local displayName = string.upper(config and config.DisplayName or regionName)

		RegionController.leaveUIVisible = true

		if ui.leavingLabel then
			ui.leavingLabel.Text = "LEAVING"
			ui.leavingLabel.TextTransparency = 1
			local stroke = ui.leavingLabel:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = 1 end

			TweenService:Create(ui.leavingLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				TextTransparency = 0.3
			}):Play()
			if stroke then TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.7}):Play() end

			dottingEffect(ui.leavingLabel, "LEAVING", 3)
		end

		if ui.townName then
			ui.townName.Text = displayName
			ui.townName.TextTransparency = 1
			local stroke = ui.townName:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = 1 end

			TweenService:Create(ui.townName, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				TextTransparency = 0
			}):Play()
			if stroke then TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play() end
		end

		RegionController.hideLeaveTask = task.delay(3, function()
			hideLeaveUI(false)
			RegionController.hideLeaveTask = nil
		end)
	end

	local Debris = game:GetService("Debris")

	local function playEnterSFX(config)
		if not config or not config.EnterSFX then return end
		if config.EnterSFX == "rbxassetid://" or config.EnterSFX == "" then return end

		local sfx = Instance.new("Sound")
		sfx.Name = "RegionEnterSFX"
		sfx.SoundId = config.EnterSFX
		sfx.Volume = 0.5
		sfx.Parent = SoundService
		sfx:Play()
		sfx.Ended:Connect(function()
			sfx:Destroy()
		end)
		Debris:AddItem(sfx, 15)
	end

	-- Chatter stays here (ambient SFX, not music)
	local function stopChatter()
		if RegionController.chatterConnection then
			pcall(function() task.cancel(RegionController.chatterConnection) end)
			RegionController.chatterConnection = nil
		end

		local chatterFolder = SoundService:FindFirstChild("RegionChatter")
		if chatterFolder then
			for _, sound in pairs(chatterFolder:GetChildren()) do
				sound:Destroy()
			end
		end
	end

	local function startChatter(config)
		stopChatter()

		if not config or not config.Chatter or not config.ChatterSounds or #config.ChatterSounds == 0 then
			return
		end

		local validSounds = {}
		for _, soundId in pairs(config.ChatterSounds) do
			if soundId and soundId ~= "" and soundId ~= "rbxassetid://" then
				table.insert(validSounds, soundId)
			end
		end
		if #validSounds == 0 then return end

		local chatterFolder = SoundService:FindFirstChild("RegionChatter")
		if not chatterFolder then
			chatterFolder = Instance.new("Folder")
			chatterFolder.Name = "RegionChatter"
			chatterFolder.Parent = SoundService
		end

		local startedRegion = RegionController.currentRegion

		RegionController.chatterConnection = task.spawn(function()
			while RegionController.currentRegion == startedRegion do
				task.wait(math.random(3, 8))
				if RegionController.currentRegion ~= startedRegion then break end

				local randomSound = validSounds[math.random(1, #validSounds)]
				local chatter = Instance.new("Sound")
				chatter.Name = "RegionChatterSound"
				chatter.SoundId = randomSound
				chatter.Volume = math.random(20, 40) / 100
				chatter.Parent = chatterFolder
				chatter:Play()
				chatter.Ended:Connect(function()
					chatter:Destroy()
				end)
				Debris:AddItem(chatter, 30)
			end
		end)
	end

	local function onRegionEnter(regionName, regionType, config)
		RegionController.currentRegion = regionName
		RegionController.currentRegionType = regionType
		RegionController.currentConfig = config

		-- UI & SFX
		playEnterSFX(config)
		showEnterUI(regionName, regionType, config)
		startChatter(config)

		-- MUSIC: Tell AudioDirector about the new region
		local timeState = player:GetAttribute("TimeState") or "Day"
		AudioDirector:SetRegion(config, timeState)

		if config.ClimateZone then
			player:SetAttribute("ClimateZone", config.ClimateZone)
		end
	end

	local function onRegionLeave(oldRegionName, oldConfig)
		RegionController.currentRegion = nil
		RegionController.currentRegionType = nil
		RegionController.currentConfig = nil

		showLeaveUI(oldRegionName, oldConfig)
		stopChatter()

		-- MUSIC: Clear region from AudioDirector
		AudioDirector:ClearRegion()

		player:SetAttribute("ClimateZone", nil)
	end

	local function applyRegionFromAttributes()
		local regionName = player:GetAttribute("CurrentRegion")
		local regionType = player:GetAttribute("CurrentRegionType")

		if not regionName or not regionType then
			if RegionController.currentRegion then
				local oldRegion = RegionController.currentRegion
				local oldConfig = RegionController.currentConfig
				onRegionLeave(oldRegion, oldConfig)
			end
			return
		end

		if regionName == RegionController.currentRegion and regionType == RegionController.currentRegionType then
			return
		end

		if RegionController.currentRegion then
			local oldRegion = RegionController.currentRegion
			local oldConfig = RegionController.currentConfig
			onRegionLeave(oldRegion, oldConfig)
			task.wait(0.2)
		end

		local config = RegionConfig:GetRegion(regionType, regionName)
		if config then
			onRegionEnter(regionName, regionType, config)
		end
	end

	function RegionController:Init()
		local gui = PlayerGui:WaitForChild("Region", 10)
		if not gui then
			warn("[RegionController] Region ScreenGui not found")
			return
		end

		createLeaveUI()

		local ui = getUI()
		if ui then
			if ui.textFrame then ui.textFrame.Visible = false end
			if ui.fade then
				ui.fade.Visible = false
				ui.fade.ImageTransparency = 1
			end
			if ui.wheel then ui.wheel.Visible = false end
			if ui.fishFlip then
				ui.fishFlip.Visible = false
				hideAllFlipbookFrames(ui.fishFlip)
			end
		end

		-- Initialize AudioDirector
		AudioDirector:Init()

		applyRegionFromAttributes()
		player:GetAttributeChangedSignal("CurrentRegion"):Connect(applyRegionFromAttributes)
		player:GetAttributeChangedSignal("CurrentRegionType"):Connect(applyRegionFromAttributes)
	end

	function RegionController:Respawn()
		stopTypewriter()
		stopDotting()
		stopWheel()
		stopFlipbook()
		destroyGlitchBox()

		safeCancel(RegionController.hideEnterTask)
		safeCancel(RegionController.hideLeaveTask)

		RegionController.hideEnterTask = nil
		RegionController.hideLeaveTask = nil
		RegionController.currentRegion = nil
		RegionController.currentRegionType = nil
		RegionController.currentConfig = nil
		RegionController.enterUIVisible = false
		RegionController.leaveUIVisible = false

		stopChatter()
		hideLeaveUI(true)

		local ui = getUI()
		if ui then
			if ui.textFrame then ui.textFrame.Visible = false end
			if ui.fade then
				ui.fade.Visible = false
				ui.fade.ImageTransparency = 1
			end
			if ui.wheel then ui.wheel.Visible = false end
			if ui.fishFlip then
				ui.fishFlip.Visible = false
				hideAllFlipbookFrames(ui.fishFlip)
			end
		end

		applyRegionFromAttributes()
	end

	player.CharacterAdded:Connect(function()
		RegionController:Respawn()
	end)

	function RegionController:GetCurrentRegion()
		return RegionController.currentRegion, RegionController.currentRegionType
	end

	return RegionController
end