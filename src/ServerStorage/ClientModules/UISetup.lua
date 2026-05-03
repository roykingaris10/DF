return function(Client)
	local UISetup = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local CharacterCustomizationInfo = Client.CharacterCustomizationInfo
	local RaceChances = Client.RaceChances
	local TweenService = game:GetService('TweenService')
	local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
	local MarketplaceService = game:GetService("MarketplaceService")
	local RunService = game:GetService("RunService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local BoatTween = require(Nodes.Utility.BoatTween)
	local EnhancedTypewriter = require(Nodes.Utility.EnhancedTypewriter)
	local CombatPhrases = require(Nodes.Data.CombatTagPhrases)
	local GameSettings = require(Nodes.Data.GameSettings)
	local PlayerGui = player:WaitForChild('PlayerGui')
	local UI = PlayerGui:WaitForChild("UI")
	
	local AudioDirector = require(ReplicatedStorage.Kits.Audio.AudioDirector)
	local CrewController = require(Nodes.Gameplay.CrewController)(Client)
	

	function UISetup:SetupTopInfo()
		local UITop = PlayerGui:WaitForChild("UITopbar")
		local InfoFrame = UITop.InfoFrame
		
		local FullName = player.StatFolder.UserFolder:GetAttribute("FirstName").." ".. (player.StatFolder.UserFolder:GetAttribute("MiddleName").." " or " ")..player.StatFolder.UserFolder:GetAttribute("LastName")
		InfoFrame.Info1.SlotName.Text = (FullName):upper()
		
		InfoFrame.Info1.PlayerNameID.Text =	(player.Name.." | "..player.UserId):upper()
		
		task.spawn(function()
			repeat 
				task.wait(0.1)
			until workspace:GetAttribute("RegionInfo")
			
			InfoFrame.Info2.ServerRegion.Text = (workspace:GetAttribute("RegionInfo")):upper()
		end)
		
		task.spawn(function()
			repeat
				local totalSecs = workspace.DistributedGameTime

				local mins = math.floor(totalSecs / 60)
				local hrs = math.floor(totalSecs / (60*60))
				local days = math.floor(totalSecs / (60*60*24))

				mins -= (hrs * 60)
				hrs -= (days * 24)

				InfoFrame.Info2.ServerAge.Text = (`Uptime:{days}d {hrs}h {mins}m `):upper()
				task.wait(60)
			until false
		end)
		
	end
	
--[[	function UISetup:SetupFaceViewport()
		local viewport = PlayerGui.HUD.PartyHolder.partyFrame.partyInfo.inner.playerView
		if not viewport then 
			warn("[UISetup] parentView not found")
			return 
		end

		local jogoChar = workspace:FindFirstChild("Jogo")
		if not jogoChar then
			warn("[UISetup] Jogo not found in workspace")
			return
		end

		local head = jogoChar:FindFirstChild("Head")
		if not head then
			warn("[UISetup] Head not found in Jogo")
			return
		end

		for _, child in ipairs(viewport:GetChildren()) do
			if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Camera") or child:IsA("Accessory") then
				child:Destroy()
			end
		end

		local headModel = Instance.new("Model")
		headModel.Name = "HeadModel"
		headModel.Parent = viewport

		local headClone = head:Clone()
		headClone.Anchored = true
		headClone.CanCollide = false
		headClone.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0)

		for _, child in ipairs(headClone:GetChildren()) do
			if child:IsA("Weld") or child:IsA("Motor6D") then
				child:Destroy()
			end
		end

		headClone.Parent = headModel
		headModel.PrimaryPart = headClone

		for _, accessory in ipairs(jogoChar:GetChildren()) do
			if accessory:IsA("Accessory") then
				local handle = accessory:FindFirstChild("Handle")
				if handle then
					local isHeadAccessory = false

					for _, att in ipairs(handle:GetChildren()) do
						if att:IsA("Attachment") then
							local name = att.Name:lower()
							if name:find("hat") or name:find("hair") or name:find("face") or name:find("head") then
								isHeadAccessory = true
								break
							end
						end
					end

					if not isHeadAccessory then
						local originalPos = handle.Position
						local headPos = head.Position
						if (originalPos - headPos).Magnitude < 2 then
							isHeadAccessory = true
						end
					end

					if isHeadAccessory then
						local handleClone = handle:Clone()
						handleClone.Anchored = true
						handleClone.CanCollide = false

						for _, w in ipairs(handleClone:GetChildren()) do
							if w:IsA("Weld") or w:IsA("Motor6D") then
								w:Destroy()
							end
						end

						local offset = head.CFrame:ToObjectSpace(handle.CFrame)
						handleClone.CFrame = headClone.CFrame * offset
						handleClone.Parent = headModel
					end
				end
			end
		end

		local camera = Instance.new("Camera")
		camera.FieldOfView = 50
		camera.CFrame = CFrame.new(Vector3.new(0, 0, 3), Vector3.zero)
		camera.Parent = viewport
		viewport.CurrentCamera = camera

		print("[UISetup] Face viewport setup complete")
	end]]
	
	function UISetup:CDTest()
		local CooldownHolder = PlayerGui.HUD.PartyHolder.partyFrame.partyInfo.CDHolder
		local F1 = CooldownHolder.Frame1.ImageLabel
		local F2 = CooldownHolder.Frame2.ImageLabel
		local Percentage = CooldownHolder.Percentage
		local F1Gradient = F1.UIGradient
		local F2Gradient = F2.UIGradient
		local isCooldownActive = true
		local startTime = tick()
		local duration = 100
		local lastMissingPartType = nil

		local function updateGradientStyle()
			local missingType = Percentage.MissingPartType.Value
			if missingType == lastMissingPartType then return end
			lastMissingPartType = missingType
			if missingType == "Color" then
				local gradientColor = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Percentage.ColorOfMissingPart.Value),
					ColorSequenceKeypoint.new(0.5, Percentage.ColorOfMissingPart.Value),
					ColorSequenceKeypoint.new(0.501, Percentage.ColorOfPercentPart.Value),
					ColorSequenceKeypoint.new(1, Percentage.ColorOfPercentPart.Value)
				})
				F1Gradient.Color = gradientColor
				F2Gradient.Color = gradientColor
				F1Gradient.Transparency = NumberSequence.new(0)
				F2Gradient.Transparency = NumberSequence.new(0)
			elseif missingType == "Trans" then
				local gradientTransparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, Percentage.TransOfMissingPart.Value),
					NumberSequenceKeypoint.new(0.5, Percentage.TransOfMissingPart.Value),
					NumberSequenceKeypoint.new(0.501, Percentage.TransOfPercentPart.Value),
					NumberSequenceKeypoint.new(1, Percentage.TransOfPercentPart.Value)
				})
				F1Gradient.Transparency = gradientTransparency
				F2Gradient.Transparency = gradientTransparency
				F1Gradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
				F2Gradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
			elseif missingType == "TransAndColor" then
				local gradientTransparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, Percentage.TransOfMissingPart.Value),
					NumberSequenceKeypoint.new(0.5, Percentage.TransOfMissingPart.Value),
					NumberSequenceKeypoint.new(0.501, Percentage.TransOfPercentPart.Value),
					NumberSequenceKeypoint.new(1, Percentage.TransOfPercentPart.Value)
				})
				local gradientColor = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Percentage.ColorOfMissingPart.Value),
					ColorSequenceKeypoint.new(0.5, Percentage.ColorOfMissingPart.Value),
					ColorSequenceKeypoint.new(0.501, Percentage.ColorOfPercentPart.Value),
					ColorSequenceKeypoint.new(1, Percentage.ColorOfPercentPart.Value)
				})
				F1Gradient.Transparency = gradientTransparency
				F2Gradient.Transparency = gradientTransparency
				F1Gradient.Color = gradientColor
				F2Gradient.Color = gradientColor
			else
				Percentage.MissingPartType.Value = "Trans"
			end
		end

		F1Gradient.Rotation = 180
		F2Gradient.Rotation = 360
		updateGradientStyle()

		local frameCount = 0
		local CDConnection

		CDConnection = RunService.Heartbeat:Connect(function()
			if not isCooldownActive then return end
			frameCount += 1
			if frameCount % 2 ~= 0 then return end

			local elapsedTime = tick() - startTime
			local remaining = math.clamp(360 - ((elapsedTime / duration) * 360), 0, 360)

			if remaining >= 180 then
				F2Gradient.Rotation = remaining
				F1Gradient.Rotation = 180
			else
				F2Gradient.Rotation = 180
				F1Gradient.Rotation = remaining
			end

			updateGradientStyle()

			if elapsedTime >= duration then
				isCooldownActive = false
				Percentage.Value = 0
				if CDConnection then
					CDConnection:Disconnect()
					CDConnection = nil
				end
				CooldownHolder:Destroy()
			end
		end)
	end
	
	function UISetup:SetupHUD()
		local HUDUI = PlayerGui:WaitForChild("HUD")
		local UI = PlayerGui:WaitForChild("UI")
		local HUDHolder = HUDUI.HUDHolder
		
		local function UpdateHealth()
			if not player.Character or not player.Character:GetAttribute("Health") then return end
			local HealthBack = HUDHolder.HealthBack
			local HealthMain = HealthBack.HealthMain
			local Red = HealthBack.HealthRed
			local Health, MaxHealth = player.Character:GetAttribute("Health"), player.Character:GetAttribute("MaxHealth")
			local Size = UDim2.fromScale(Health/MaxHealth, 1)

			TweenService:Create(HealthMain, TweenInfo.new(0.1, Enum.EasingStyle.Quart),{Size = Size}):Play()
			
			local healthEffect = TweenService:Create(Red, TweenInfo.new(.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, .01), 
				{Size = Size,
					BackgroundColor3 = Color3.fromRGB(255, 0, 55),
				})

			healthEffect:Play()
			task.wait(0.45)
		
			local healthReturn = TweenService:Create(Red, TweenInfo.new(.1, Enum.EasingStyle.Exponential), 
				{BackgroundColor3 = Color3.fromRGB(255, 134, 134),
				})

			healthReturn:Play()		
		end
		
		local function TweenInsert(UI)
			UI.Visible = true
			local FirstTween = TweenService:Create(UI, TweenInfo.new(.3, 
				Enum.EasingStyle.Quart, 
				Enum.EasingDirection.Out, 0, false, 0),
				{ImageTransparency = 0}) FirstTween:Play()
			FirstTween.Completed:Connect(function()
				TweenService:Create(UI, TweenInfo.new(.6, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
			end)
		end
		
		local function setupBeliAnimation()
			local TweenService = game:GetService("TweenService")
			local RunService = game:GetService("RunService")
			local Debris = game:GetService("Debris")

			local BeliFrame = PlayerGui:WaitForChild("HUD"):WaitForChild("Beli")
			local ValueLabel = BeliFrame:WaitForChild("Value")

			local isAnimating = false
			local currentConnection = nil

			local originalColor = ValueLabel.TextColor3
			local originalSize = ValueLabel.TextSize

			local function formatNumber(num)
				local formatted = tostring(math.floor(num))
				local k
				while true do  
					formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
					if k == 0 then break end
				end
				return formatted
			end

			local function flashEffect(isGain)
				local flashColor = isGain and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)

				ValueLabel.TextColor3 = flashColor

				TweenService:Create(ValueLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					TextSize = originalSize * 1.25
				}):Play()

				task.delay(0.15, function()
					TweenService:Create(ValueLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						TextColor3 = originalColor,
						TextSize = originalSize
					}):Play()
				end)
			end

			local function shakeEffect(intensity)
				local originalPosition = ValueLabel.Position
				local shakeCount = 6

				for i = 1, shakeCount do
					local offsetX = math.random(-intensity, intensity)
					local offsetY = math.random(-intensity, intensity)

					task.delay(i * 0.03, function()
						if i == shakeCount then
							TweenService:Create(ValueLabel, TweenInfo.new(0.1), {
								Position = originalPosition
							}):Play()
						else
							ValueLabel.Position = originalPosition + UDim2.new(0, offsetX, 0, offsetY)
						end
					end)
				end
			end

			local function animateBeli(startValue, endValue)
				if currentConnection then
					currentConnection:Disconnect()
					currentConnection = nil
				end

				isAnimating = true

				local difference = math.abs(endValue - startValue)
				local isGain = endValue > startValue

				local duration = math.clamp(difference / 2000, 0.8, 2.5)
				local startTime = tick()

				flashEffect(isGain)

				if not isGain and difference > 1000 then
					shakeEffect(math.clamp(difference / 500, 2, 6))
				end

				-- local tickSound = Instance.new("Sound")
				-- tickSound.SoundId = "rbxassetid://YOUR_SOUND_ID"
				-- tickSound.Parent = BeliFrame
				-- tickSound:Play()
				-- Debris:AddItem(tickSound, 3)

				local lastValue = startValue

				currentConnection = RunService.Heartbeat:Connect(function()
					local elapsed = tick() - startTime
					local progress = math.min(elapsed / duration, 1)

					local eased = 1 - math.pow(1 - progress, 4)

					local currentValue = math.floor(startValue + (endValue - startValue) * eased)

					if currentValue ~= lastValue then
						ValueLabel.Text = formatNumber(currentValue)
						lastValue = currentValue

						if progress < 0.7 then
							local pulseScale = 1 + (0.05 * (1 - progress))
							ValueLabel.TextSize = originalSize * pulseScale
						end
					end

					if progress >= 0.7 then
						local sizeProgress = (progress - 0.7) / 0.3
						ValueLabel.TextSize = originalSize * (1 + 0.05 * (1 - sizeProgress))
					end

					if progress >= 1 then
						currentConnection:Disconnect()
						currentConnection = nil
						ValueLabel.Text = formatNumber(endValue)
						ValueLabel.TextSize = originalSize
						ValueLabel.TextColor3 = originalColor
						isAnimating = false
					end
				end)
			end

			local function updateDisplay()
				local beli = player.StatFolder.UserFolder:GetAttribute("Beli")
				ValueLabel.Text = formatNumber(beli)
			end
			
			--[[local function playerName()
				local FullName = player.StatFolder.UserFolder:GetAttribute("FirstName").." ".. (player.StatFolder.UserFolder:GetAttribute("MiddleName").." " or " ")..player.StatFolder.UserFolder:GetAttribute("LastName")
				UI.PlayerNameFrame.value.Text = FullName:upper()
				UI.PlayerNameFrame.Visible = true
			end
			
			playerName()]]

			Network:bindEvent("BeliUpdate", function(oldBeli, newBeli, cost)
				animateBeli(oldBeli, newBeli)
			end)

			player.StatFolder.UserFolder:GetAttributeChangedSignal("Beli"):Connect(function()
				if not isAnimating then
					updateDisplay()
				end
			end)

			updateDisplay()
		end
		
		local function UpdatePosture()
			
			local PostureAttach = Client.Entity.Character.HumanoidRootPart.PostureAttach
			local BillUI = PostureAttach.BillboardGui
			
			if not player.Character or not player.Character:GetAttribute("Posture") then return end
			local postureBar = BillUI.PostureFrame.postBack.postBar
			local postFlash = BillUI.PostureFrame.postFlash
			local Posture, MaxPosture = player.Character:GetAttribute("Posture"), player.Character:GetAttribute("MaxPosture")
			local Size = UDim2.fromScale(1, Posture/MaxPosture)
			TweenService:Create(postureBar, TweenInfo.new(0.3),{Size = Size}):Play()
			TweenService:Create(postFlash, TweenInfo.new(0.15, Enum.EasingStyle.Circular, Enum.EasingDirection.Out, 0, true, 0), {ImageTransparency = 0}):Play()
			
		end
		
		local function UpdateWill()
			
			local willBorder = PlayerGui:WaitForChild("HUD").HUDHolder.willBorder
			if not player.Character or not player.Character:GetAttribute("Will") then return end

			local willBar = HUDHolder.willBack.willBar
			local Will, MaxWill = player.Character:GetAttribute("Will"), player.Character:GetAttribute("MaxWill")
			local Size = UDim2.fromScale(Will/MaxWill, 1)

			if Will >= MaxWill then
				TweenInsert(willBorder)
			end

			local willColor = player:GetAttribute("WillColor")

			if willColor then
				willBar.BackgroundColor3 = willColor
			end

			TweenService:Create(willBar, TweenInfo.new(0.3), {Size = Size}):Play()
		end
		

		

		local function UpdateStamina()
			if not player.Character or not player.Character:GetAttribute("Stamina") then return end
			local staminaBar = HUDHolder.staminaBack.staminaBar
			local Stamina, MaxStamina = player.Character:GetAttribute("Stamina"), player.Character:GetAttribute("MaxStamina")
			local Size = UDim2.fromScale(Stamina/MaxStamina, 1)

			TweenService:Create(staminaBar, TweenInfo.new(0.3),{Size = Size}):Play()
		--	staminaBar.Text = tostring(math.floor(Stamina)).."%"
		end
 
 
		local MAX_HUNGER = 100
		local HUNGER_PER_ICON = 10  -- Each icon represents 10 hunger
		local TOTAL_ICONS = 10     
		local HALF_HUNGER = 5 
		
		local function UpdateHunger()
			if not player.Character or not player.Character:GetAttribute("Hunger") then return end

			local hungHolder  = HUDHolder.hungHolder
			local Hunger, MaxHunger = player.Character:GetAttribute("Hunger"), player.Character:GetAttribute("MaxHunger")
			local hungerPercent = Hunger / MaxHunger

			local FoodIcons = {}
			for i = 1, TOTAL_ICONS do
				local foodFrame = hungHolder:FindFirstChild("food" .. tostring(i))
				if foodFrame then
					local icon = foodFrame:FindFirstChild(tostring(i))
					if icon then
						FoodIcons[i] = icon
					end
				end
			end
			
			local function ConvertHungerToIconStates(hunger)
				hunger = math.clamp(hunger, 0, MAX_HUNGER)

				local fullIcons = math.floor(hunger / 10)
				local remainingHunger = hunger % 10 
				local hasHalfIcon = false
				if remainingHunger >= 5 then
					hasHalfIcon = true
				end

				return {
					fullIcons = fullIcons,
					hasHalfIcon = hasHalfIcon,
					emptyIcons = TOTAL_ICONS - fullIcons - (hasHalfIcon and 1 or 0)
				}
			end
			
			local function UpdateFoodIcon(iconIndex, iconState)
				local icon = FoodIcons[iconIndex]
				if not icon then return end

				local gradient = icon:FindFirstChild("UIGradient")

				if iconState == "full" then-- Full icon
					icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
					icon.ImageTransparency = 0
					if gradient then
						gradient.Enabled = false
					end

				elseif iconState == "half" then-- Half icon
					icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
					icon.ImageTransparency = 0

					if gradient then
						gradient.Enabled = true
					end

				else -- "empty"
					icon.ImageColor3 = Color3.fromRGB(0, 0, 0)

					if gradient then
						gradient.Enabled = false
					end
				end
			end

			-- Main function to update all icons
			local function UpdateHungerBar()
				local currentHunger = math.clamp(Hunger, 0, MaxHunger)

				-- Get icon breakdown
				local iconStates = ConvertHungerToIconStates(currentHunger)

				-- Debug output
				--[[
				print(string.format("Hunger: %d -> Full: %d, Half: %s, Empty: %d", 
					currentHunger, 
					iconStates.fullIcons, 
					tostring(iconStates.hasHalfIcon), 
					iconStates.emptyIcons
					))
]]
			
				local currentIcon = TOTAL_ICONS

				for i = 1, iconStates.emptyIcons do
					if currentIcon >= 1 then
						UpdateFoodIcon(currentIcon, "empty")
						currentIcon = currentIcon - 1
					end
				end
				
				if iconStates.hasHalfIcon and currentIcon >= 1 then
					UpdateFoodIcon(currentIcon, "half")
					currentIcon = currentIcon - 1
				end

				for i = 1, iconStates.fullIcons do
					if currentIcon >= 1 then
						UpdateFoodIcon(currentIcon, "full")
						currentIcon = currentIcon - 1
					end
				end
			end
			UpdateHungerBar()
		end
		
		local function triggerCombatUIEffect(CombatFrame)
			CombatFrame.glasses.UIGradient.Offset = Vector2.new(-0.1,0)
			
			local gradtween = TweenService:Create(CombatFrame.glasses.UIGradient,TweenInfo.new(0.5),{Offset = Vector2.new(0.1,0)})
			gradtween:Play()
		end
		
		local combathover = false
		local CombatTagged = false
		local CountdownActive = false
		local LastEffectTime = 0
		local EffectCooldown = 3 -- Seconds between effects
		local EffectChance = 0.15 -- 15% chance each check
		local function UpdateCombatTag()
			if not player.Character or not player.Character:GetAttribute("InCombatTick") then return end
			local currentTick = tick()
			local currentTag = player.Character:GetAttribute("InCombatTick") or 0
			local CombatFrame = UI.InCombatFrame
			local combatMusic = ReplicatedStorage.Kits.Sounds.Combat:FindFirstChild("CombatMusic")
			
			local timeSinceTag = currentTick - currentTag
			local timeRemaining = math.max(0, GameSettings.InCombatDuration - timeSinceTag)

			-- Check if in combat
			local isInCombat = timeSinceTag < GameSettings.InCombatDuration and timeSinceTag > 0

			if not CombatTagged and isInCombat then
				CombatTagged = true
				CombatFrame.combatText.Text = CombatPhrases[math.random(1, #CombatPhrases)]
				CombatFrame.Visible = true
				
				local musicClone = combatMusic:Clone()

				-- When combat starts
				musicClone.Parent = game:GetService("SoundService")
				musicClone.Volume = 1
				AudioDirector:StartCombat(false)
				--musicClone:Play()
				
				coroutine.wrap(function()
					while CombatTagged and player.Character do
						local currentTime = tick()
						currentTag = player.Character:GetAttribute("InCombatTick") or 0
						local newTimeSinceTag = currentTime - currentTag

						if currentTime - LastEffectTime > EffectCooldown and math.random() < EffectChance then
							triggerCombatUIEffect(CombatFrame)
							LastEffectTime = currentTime
						end

						if newTimeSinceTag >= GameSettings.InCombatDuration then
							break
						end

						task.wait(0.1)
					end

					-- EXITING COMBAT
					if CombatTagged then
						CombatTagged = false

						CombatFrame.Visible = false
						UI.InCombatFrame.timer.Visible = false
						local count = 10
						while count >= 10 do
							musicClone.Volume -= 0.5
							task.wait(0.1)
							count -= 1
							if count <= 0 then
								AudioDirector:EndCombat()
								musicClone:Destroy()
							end
						end
					end
				end)()
			
			--	repeat task.wait(0.1)  until currentTick - currentTag > GameSettings.InCombatDuration
				
			--	CombatFrame.Visible = false
			elseif CombatTagged and not isInCombat then
				CombatTagged = false
				CombatFrame.Visible = false
				UI.InCombatFrame.timer.Visible = false
			end
		end
		
	--	local function UpdateBeli()
	--		local beliFrame = HUDUI.Beli
	--		beliFrame.Value.Text = tostring(player.StatFolder.UserFolder:GetAttribute("Beli"))
	--	end
		
		UpdateHealth()
		UpdateWill()
		UpdateStamina()
		UpdatePosture()
		UpdateHunger()
		UpdateCombatTag()
		setupBeliAnimation()
		--UpdateBeli()

		local statSignals = {}
		local function bindStatSignals(char)
			for _, conn in ipairs(statSignals) do conn:Disconnect() end
			table.clear(statSignals)
			if not char then return end
			table.insert(statSignals, char:GetAttributeChangedSignal("Health"):Connect(UpdateHealth))
			table.insert(statSignals, char:GetAttributeChangedSignal("Will"):Connect(UpdateWill))
			table.insert(statSignals, char:GetAttributeChangedSignal("Stamina"):Connect(UpdateStamina))
			table.insert(statSignals, char:GetAttributeChangedSignal("Posture"):Connect(UpdatePosture))
			table.insert(statSignals, char:GetAttributeChangedSignal("Hunger"):Connect(UpdateHunger))
			table.insert(statSignals, char:GetAttributeChangedSignal("InCombatTick"):Connect(UpdateCombatTag))
			UpdateHealth()
			UpdateWill()
			UpdateStamina()
			UpdatePosture()
			UpdateHunger()
			UpdateCombatTag()
		end

		bindStatSignals(player.Character)
		player.CharacterAdded:Connect(bindStatSignals)
	--	player.StatFolder.UserFolder:GetAttributeChangedSignal("Beli"):Connect(UpdateBeli)
		
		local PostureConn 
		PostureConn = RunService.Heartbeat:Connect(function()
			if not player.Character or not player.character.Parent then
				PostureConn:Disconnect()
			end

			local posture = player.Character:GetAttribute("Posture") or 0

			local isBlocking = player.Character:GetAttribute("Blocking") or false
	
			local PostureAttach = Client.Entity.Character.HumanoidRootPart.PostureAttach
			local BillUI = PostureAttach.BillboardGui
			if posture ~= 0 or isBlocking then
				BillUI.Enabled = true
			else
				BillUI.Enabled = false
			end
		end)
		
		local combathover = false
		UI.InCombatFrame.MouseEnter:Connect(function()
			if not CombatTagged then return end
			combathover = true
			UI.InCombatFrame.timer.Visible = true
			coroutine.wrap(function()
				while combathover and CombatTagged and player.Character do
					local currentTick = tick()
					local currentTag = player.Character:GetAttribute("InCombatTick")

					if currentTag then
						local timeSinceTag = currentTick - currentTag
						local secLeft = math.max(0, GameSettings.InCombatDuration - timeSinceTag)

						-- Format with 1 decimal place for smoother countdown
						UI.InCombatFrame.timer.Text = string.format("%.1fs", secLeft):upper()

						-- Color coding based on time left
						if secLeft < 3 then
							UI.InCombatFrame.timer.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
						elseif secLeft < 8 then
							UI.InCombatFrame.timer.TextColor3 = Color3.fromRGB(255, 150, 50) -- Orange
						else
							UI.InCombatFrame.timer.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
						end
					end

					task.wait(0.1) -- Update every 0.1 seconds
				end

				-- Hide timer when done
				UI.InCombatFrame.timer.Visible = false
			end)()
		end)
		
		UI.InCombatFrame.MouseLeave:Connect(function()
			combathover = false
		end)
		
	end
	
	local opencore = false
	local coreTweens = {}
	function UISetup:ToggleCoreMenu()
		local UI = PlayerGui:WaitForChild("UI")
		local HUDUI = PlayerGui:WaitForChild("HUD")
		local MainTab = UI.MainTab
		local HUDHolder = HUDUI.HUDHolder

		if opencore then
			MainTab.BackgroundTransparency = 1
			MainTab.InventoryFrame.Visible = false
			MainTab.Charbox.Visible = false
			MainTab.accessFrame.Visible = false
			MainTab.access2Frame.Visible = false
			HUDHolder.Visible = true
			Client.InventoryClient:VisibleToolbar(false)
			opencore = false
		else
			MainTab.BackgroundTransparency = 0.4
			MainTab.InventoryFrame.Visible = true
			MainTab.Charbox.Visible = true
			MainTab.accessFrame.Visible = true
			MainTab.access2Frame.Visible = true
			HUDHolder.Visible = false
			Client.InventoryClient:VisibleToolbar(true)
			opencore = true
		end
	end
	
	local pingDisplay = UI:WaitForChild("pingDisplay")

	local pingText = player.PlayerGui.UITopbar.InfoFrame.PingFPS.Ping

	local function updatePingDisplay()
		local counter = 1
		spawn(function()
			while wait(.1) do
				pcall(function()
					if counter % 10	== 0 then
						counter = 0
						local initialTick = tick()
						Network:get('Ping')
						local ping = math.floor((tick() - initialTick) * 1000)
						pingText.Text = (ping)
							if ping < 70 then
							TweenService:Create(pingText, TweenInfo.new(1), {TextColor3 = Color3.new(0.333333, 1, 0.498039)}):Play()
							elseif ping > 110 then
							TweenService:Create(pingText, TweenInfo.new(1), {TextColor3 = Color3.new(1, 0, 0)}):Play()
							elseif ping > 80 then
							TweenService:Create(pingText, TweenInfo.new(1), {TextColor3 = Color3.new(1, 0.666667, 0)}):Play()

							end
					end
				end)
				counter += 1
			end
		end)

	end
	
	local function FPS()
		local FrameElements = {}
		local lastTick, initTick
		initTick = tick()
		local lowFPSStart
		local minFPS = 10
		local maxTimeLowFps = 2
		game:GetService("RunService").Heartbeat:Connect(function()
			lastTick = tick()
			for Index = #FrameElements, 1, -1 do FrameElements[Index + 1] = (FrameElements[Index] >= lastTick - 1) and FrameElements[Index] or nil end
			FrameElements[1] = lastTick
			local CurrentFPS = (tick() - initTick >= 1 and #FrameElements) or (#FrameElements / (tick() - initTick))
			pcall(function() player.PlayerGui.UITopbar.InfoFrame.PingFPS.FPS.Text = (math.min(math.floor(CurrentFPS), 60)) end)
		end)
	end

	updatePingDisplay()
	FPS()

	function UISetup:Init()
		
		
		local Character = player.Character
		local RootPart = Character.HumanoidRootPart
		local Sound = RootPart:WaitForChild("Running", 10)

		Sound.Volume = 0
		
		local HUDUI = PlayerGui:WaitForChild("HUD")
		local UI = PlayerGui:WaitForChild("UI")
		local HUDHolder = HUDUI.HUDHolder
		HUDHolder.Visible = true
		UISetup:SetupTopInfo()
		--UISetup:SetupFaceViewport()
		UISetup:SetupHUD()
		--UISetup:CDTest()
		Client.ProfileClient:SetupProfile()
	end
	
	
	return UISetup end

	


