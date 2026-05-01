return function(Client)
	local player = Client.player
	local Network = Client.Network
	local TweenService = game:GetService('TweenService')
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local SoundService = game:GetService("SoundService")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	local PlayerGui = player:WaitForChild("PlayerGui")

	local DialogueHandler = {
		inDialogue = false,
		mouseClicked = false,
		distanceCheckConnection = nil,
		interactState = "closed",
		activeTweens = {},
		lastStateChange = 0,
		debounceTime = 0.15
	}

	local ITALIC_COLOR = "#D4B8FF"
	local function applyMarkup(text)
		if type(text) ~= "string" then return text end
		return (text:gsub("%*([^%*]+)%*", string.format('<i><font color="%s">%%1</font></i>', ITALIC_COLOR)))
	end

	local lineSound = Instance.new("Sound")
	lineSound.SoundId = "rbxassetid://9114393683"
	lineSound.Volume = 0.35
	lineSound.PlaybackSpeed = 1
	lineSound.Parent = SoundService

	local function playLineSound()
		lineSound.PlaybackSpeed = 0.95 + math.random() * 0.1
		lineSound:Stop()
		lineSound:Play()
	end

	local function ensureContinueHint(dialogueUI)
		local hint = dialogueUI:FindFirstChild("ClickToContinueHint")
		if hint then return hint end

		hint = Instance.new("TextLabel")
		hint.Name = "ClickToContinueHint"
		hint.AnchorPoint = Vector2.new(0.5, 1)
		hint.Position = UDim2.new(0.5, 0, 0.92, 0)
		hint.Size = UDim2.fromScale(0.18, 0.035)
		hint.BackgroundTransparency = 1
		hint.Font = Enum.Font.Gotham
		hint.RichText = true
		hint.TextScaled = true
		hint.TextColor3 = Color3.fromRGB(245, 245, 245)
		hint.TextTransparency = 0.45
		hint.Text = "<i>click to continue</i>"
		hint.ZIndex = 20
		hint.Visible = false
		hint.Parent = dialogueUI
		return hint
	end

	local FactionController = require(Nodes.Gameplay.FactionController)(Client)

	local function resetChoices(choiceHolder)
		for _, button in pairs(choiceHolder:GetChildren()) do
			if button:IsA('TextButton') then
				button:Destroy()
			end
		end
	end

	local function getEcollectFrame()
		return PlayerGui:WaitForChild('HUD').HUDHolder.ecollectFrame
	end

	local function canChangeState()
		return (tick() - DialogueHandler.lastStateChange) >= DialogueHandler.debounceTime
	end

	local function cancelAllTweens()
		for _, tween in pairs(DialogueHandler.activeTweens) do
			if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
				tween:Cancel()
			end
		end
		DialogueHandler.activeTweens = {}
	end

	local function createTween(instance, tweenInfo, properties)
		local tween = TweenService:Create(instance, tweenInfo, properties)
		table.insert(DialogueHandler.activeTweens, tween)
		return tween
	end

	local function interactopen()
		if DialogueHandler.interactState == "open" or DialogueHandler.interactState == "opening" then 
			return 
		end

		if not canChangeState() then return end

		cancelAllTweens()
		DialogueHandler.interactState = "opening"
		DialogueHandler.lastStateChange = tick()

		local InteractFrame = getEcollectFrame()
		local wheel = InteractFrame.wheel

		wheel.Size = UDim2.new(0, 0, 0, 0)
		wheel.Rotation = 0
		wheel.Visible = true

		InteractFrame.boxframe.box.Position = UDim2.new(-0.6, 0, 0, 0)
		InteractFrame.boxframe.box.Visible = true

		InteractFrame.E.TextTransparency = 1
		InteractFrame.collect.TextTransparency = 1
		InteractFrame.E.Visible = true
		InteractFrame.collect.Visible = true

		local wheelSizeTween = createTween(wheel, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
			Size = UDim2.new(0.293, 0, 1.168, 0)
		})
		local wheelRotTween = createTween(wheel, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {
			Rotation = 1080
		})

		wheelSizeTween:Play()
		wheelRotTween:Play()

		wheelSizeTween.Completed:Connect(function(playbackState)
			if playbackState ~= Enum.PlaybackState.Completed then return end
			if DialogueHandler.interactState ~= "opening" then return end

			local boxTween = createTween(InteractFrame.boxframe.box, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 0)
			})
			local eTween = createTween(InteractFrame.E, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.05), {
				TextTransparency = 0
			})
			local collectTween = createTween(InteractFrame.collect, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.05), {
				TextTransparency = 0
			})

			boxTween:Play()
			eTween:Play()
			collectTween:Play()

			boxTween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed and DialogueHandler.interactState == "opening" then
					DialogueHandler.interactState = "open"
				end
			end)
		end)
	end

	local function interactclose()
		if DialogueHandler.interactState == "closed" or DialogueHandler.interactState == "closing" then 
			return 
		end

		if not canChangeState() then return end

		cancelAllTweens()
		DialogueHandler.interactState = "closing"
		DialogueHandler.lastStateChange = tick()

		local InteractFrame = getEcollectFrame()
		local wheel = InteractFrame.wheel

		local eTween = createTween(InteractFrame.E, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
			TextTransparency = 1
		})
		local collectTween = createTween(InteractFrame.collect, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
			TextTransparency = 1
		})

		eTween:Play()
		collectTween:Play()

		collectTween.Completed:Connect(function(playbackState)
			if playbackState ~= Enum.PlaybackState.Completed then return end
			if DialogueHandler.interactState ~= "closing" then return end

			local boxTween = createTween(InteractFrame.boxframe.box, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Position = UDim2.new(0, 0, 0, 0)
			})

			boxTween:Play()

			boxTween.Completed:Connect(function(state)
				if state ~= Enum.PlaybackState.Completed then return end
				if DialogueHandler.interactState ~= "closing" then return end

				InteractFrame.boxframe.box.Visible = false
				InteractFrame.E.Visible = false
				InteractFrame.collect.Visible = false

				local wheelSizeTween = createTween(wheel, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
					Size = UDim2.new(0, 0, 0, 0)
				})
				local wheelRotTween = createTween(wheel, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
					Rotation = 0
				})

				wheelSizeTween:Play()
				wheelRotTween:Play()

				wheelSizeTween.Completed:Connect(function(finalState)
					if finalState == Enum.PlaybackState.Completed and DialogueHandler.interactState == "closing" then
						wheel.Visible = false
						InteractFrame.boxframe.box.Position = UDim2.new(-0.6, 0, 0, 0)
						DialogueHandler.interactState = "closed"
					end
				end)
			end)
		end)
	end

	local function interactforceclose()
		cancelAllTweens()
		DialogueHandler.interactState = "closed"
		DialogueHandler.lastStateChange = tick()

		local InteractFrame = getEcollectFrame()
		InteractFrame.wheel.Visible = false
		InteractFrame.wheel.Size = UDim2.new(0, 0, 0, 0)
		InteractFrame.wheel.Rotation = 0
		InteractFrame.boxframe.box.Visible = false
		InteractFrame.boxframe.box.Position = UDim2.new(-0.6, 0, 0, 0)
		InteractFrame.E.Visible = false
		InteractFrame.E.TextTransparency = 1
		InteractFrame.collect.Visible = false
		InteractFrame.collect.TextTransparency = 1
	end

	local function showDialogue(UI, dialogueUI)
		DialogueHandler.inDialogue = true

		interactforceclose()

		pcall(function()
			local hudHolder = UI:FindFirstChild("HUDHolder")
			if hudHolder then hudHolder.Visible = false end

			local toolbar = PlayerGui:FindFirstChild("HUD").ToolboxFrame
			if toolbar.Visible then toolbar.Visible = false end
		end)

		local dialogueFolder = UI:FindFirstChild("DialogueFolder")
		if dialogueFolder then
			local dialogueBox = dialogueFolder:FindFirstChild("DialogueBox")
			if dialogueBox then dialogueBox.Visible = true end
		end
		dialogueUI.Visible = true
		if Client.CompassController then
			Client.CompassController.Close()
		end
	end

	local function hideDialogue(UI, dialogueUI)
		local dialogueFolder = UI:FindFirstChild("DialogueFolder")

		if dialogueFolder then
			local dialogueBox = dialogueFolder:FindFirstChild("DialogueBox")
			if dialogueBox then dialogueBox.Visible = false end
		end

		resetChoices(dialogueUI.ChoiceHolder)

		pcall(function()
			local hudHolder = UI:FindFirstChild("HUDHolder")
			if hudHolder then hudHolder.Visible = true end

			local toolbar = PlayerGui:FindFirstChild("HUD").ToolboxFrame
			if toolbar then toolbar.Visible = true end
		end)

		dialogueUI.Visible = false
		DialogueHandler.inDialogue = false
		
		if Client.CompassController then
			Client.CompassController.Open()
		end

		pcall(function()
			if Client.CrewClient then
				PlayerGui.UI.CrewFrame.Visible = false
			end
		end)

		if DialogueHandler.distanceCheckConnection then
			DialogueHandler.distanceCheckConnection:Disconnect()
			DialogueHandler.distanceCheckConnection = nil
		end
	end

	local function createChoiceButton(choiceHolder, choiceNum, choiceText)
		local button = Instance.new('TextButton')
		button.Name = "Choice" .. choiceNum
		button.FontFace = Font.new("rbxasset://fonts/families/AccanthisADFStd.json")
		button.Text = choiceText:upper()
		button.TextTransparency = 1
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 14
		button.TextScaled = true
		button.AnchorPoint = Vector2.new(0.95, 0.5)
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		button.BackgroundTransparency = 1
		button.Position = UDim2.fromScale(0.635, 0.5)
		button.Size = UDim2.fromScale(0.4, 0.7)
		button.ZIndex = 4
		button.Parent = choiceHolder

		TweenService:Create(button, TweenInfo.new(0.5), {TextTransparency = 0.2}):Play()

		return button
	end

	local function evalCondition(condition)
		if condition == nil then return true end
		if type(condition) == "function" then
			local ok, result = pcall(condition, player, Client)
			if not ok then return false end
			return result and true or false
		end
		if type(condition) == "boolean" then return condition end
		return true
	end

	local function isPlayerTooFar(npcHRP, maxDistance)
		local character = player.Character
		if not character then return true end

		local playerHRP = character:FindFirstChild("HumanoidRootPart")
		if not playerHRP then return true end

		local distance = (npcHRP.Position - playerHRP.Position).Magnitude
		return distance > maxDistance
	end

	local function handleFactionAction(action)
		if action == "Marine" then
			local success, result = FactionController.JoinFaction("Marine")
			if success then
				print("[DialogueHandler] Joined Marine faction")
			else
				warn("[DialogueHandler] Failed to join Marine:", result)
			end
			return success

		elseif action == "Pirate" then
			local success, result = FactionController.JoinFaction("Pirate")
			if success then
				print("[DialogueHandler] Joined Pirate faction")
			else
				warn("[DialogueHandler] Failed to join Pirate:", result)
			end
			return success

		elseif action == "Revolutionary" then
			local success, result = FactionController.JoinFaction("Revolutionary")
			if success then
				print("[DialogueHandler] Joined Revolutionary faction")
			else
				warn("[DialogueHandler] Failed to join Revolutionary:", result)
			end
			return success

		elseif action == "Civilian" then
			local success, result = FactionController.LeaveFaction()
			if success then
				print("[DialogueHandler] Left faction, now Civilian")
			else
				warn("[DialogueHandler] Failed to leave faction:", result)
			end
			return success
		end

		return false
	end

	local function runNodeActions(node, NPC)
		if not node then return end

		if node.AcceptedQuest then
			Network:get('DialogueAction', 'AcceptQuest', { questName = node.AcceptedQuest })
		end
		if node.TurnInQuest then
			Network:get('DialogueAction', 'TurnInQuest', { questName = node.TurnInQuest })
		end
		if node.AbandonQuest then
			Network:get('DialogueAction', 'AbandonQuest', { questName = node.AbandonQuest })
		end

		if node.Action then
			local action = node.Action
			if action == "Marine" or action == "Pirate" or action == "Revolutionary" or action == "Civilian" then
				handleFactionAction(action)
			elseif action == "CrewCreator" then
				local currentFaction = FactionController.GetState().FactionId
				if currentFaction ~= "Pirate" then
					warn("[DialogueHandler] Only Pirates can create crews")
				elseif player:GetAttribute("Crew") and player:GetAttribute("Crew") ~= "None" then
					warn("[DialogueHandler] Already in a crew")
				else
					Network:get('DialogueAction', 'CrewCreator', {})
					if Client.CrewClient then
						Client.CrewClient:Setup()
					end
				end
			end
		end
	end

	local function setupNPCDialogue(NPC)
		local hrp = NPC:WaitForChild('HumanoidRootPart')
		local prompt = hrp:WaitForChild('NPCPrompt')
		local highlight = NPC:FindFirstChild('Highlight')

		prompt.PromptShown:Connect(function()
			if DialogueHandler.inDialogue then return end

			if highlight then
				TweenService:Create(highlight, TweenInfo.new(0.5), {OutlineTransparency = 0}):Play()
			end

			interactopen()
		end)

		prompt.PromptHidden:Connect(function()
			if highlight then
				TweenService:Create(highlight, TweenInfo.new(0.5), {OutlineTransparency = 1}):Play()
			end

			if not DialogueHandler.inDialogue then
				interactclose()
			end
		end)

		prompt.Triggered:Connect(function()
			if DialogueHandler.inDialogue then return end

			DialogueHandler.inDialogue = true

			local UI = PlayerGui.HUD
			local dialogueUI = UI.DialogueFolder.Dialogue
			local dialogueBox = UI.DialogueFolder.DialogueBox

			local success, dialogueInfo, shopInfo = Network:get('Dialogue', NPC)

			if not success then
				warn(("[DialogueHandler] %s: %s"):format(NPC.Name, tostring(dialogueInfo)))
				DialogueHandler.inDialogue = false
				return
			end

			if type(dialogueInfo) ~= "table" or not dialogueInfo.Default then
				warn(("[DialogueHandler] %s returned no usable dialogue (no Default node)"):format(NPC.Name))
				DialogueHandler.inDialogue = false
				return
			end

			local dialogueVersion = 'Default'
			local dialogueCurrent = 1
			local dialogueLength = 1
			local maxDistance = prompt.MaxActivationDistance

			dialogueBox.NPCName.Text = (`~ {NPC.Name} ~`)
			dialogueBox.Textbox.npcText.Text = ""

			local continueHint = ensureContinueHint(dialogueUI)
			continueHint.Visible = false

			local npcText = dialogueBox.Textbox.npcText
			npcText.RichText = true

			showDialogue(UI, dialogueUI)

			repeat
				dialogueBox.NPCName.Text = (`~ {NPC.Name} ~`)
				dialogueBox.Textbox.npcText.Text = ""

				local currentDialogue = dialogueInfo[dialogueVersion]
				if not currentDialogue then break end

				runNodeActions(currentDialogue, NPC)

				for lineNum, lineText in ipairs(currentDialogue.Text) do
					DialogueHandler.mouseClicked = false
					npcText.TextTransparency = 1
					npcText.Text = applyMarkup(lineText)
					playLineSound()
					TweenService:Create(npcText, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()

					if lineNum == #currentDialogue.Text and currentDialogue.Choices then
						task.wait(0.3)
						break
					end

					task.wait(0.2)

					continueHint.Visible = true
					continueHint.TextTransparency = 1
					TweenService:Create(continueHint, TweenInfo.new(0.4), { TextTransparency = 0.45 }):Play()

					repeat
						task.wait()
					until DialogueHandler.mouseClicked or isPlayerTooFar(hrp, maxDistance)

					continueHint.Visible = false

					if not DialogueHandler.mouseClicked then
						hideDialogue(UI, dialogueUI)
						return
					end
				end

				resetChoices(dialogueUI.ChoiceHolder)
				continueHint.Visible = false

				if currentDialogue.Choices then
					local choiceConnections = {}
					local choiceSelected = nil

					local filteredChoices = {}
					for i, choiceText in ipairs(currentDialogue.Choices) do
						local condition = currentDialogue.ChoiceConditions and currentDialogue.ChoiceConditions[i]
						if evalCondition(condition) then
							table.insert(filteredChoices, { index = i, text = choiceText })
						end
					end

					if #filteredChoices == 0 then
						hideDialogue(UI, dialogueUI)
						return
					end

					for _, entry in ipairs(filteredChoices) do
						local button = createChoiceButton(dialogueUI.ChoiceHolder, entry.index, entry.text)

						local conn = button.MouseButton1Click:Connect(function()
							for _, c in ipairs(choiceConnections) do
								c:Disconnect()
							end
							choiceSelected = entry.index
						end)
						table.insert(choiceConnections, conn)
					end

					dialogueUI.ChoiceHolder.Visible = true

					repeat
						task.wait()
					until choiceSelected or isPlayerTooFar(hrp, maxDistance)

					if not choiceSelected then
						hideDialogue(UI, dialogueUI)
						return
					end

					dialogueUI.ChoiceHolder.Visible = false

					if dialogueVersion == 'Default' then
						dialogueVersion = tostring(choiceSelected)
					else
						dialogueVersion = dialogueVersion .. tostring(choiceSelected):upper()
					end

					local nextDialogue = dialogueInfo[dialogueVersion]
					if not nextDialogue then break end

					if nextDialogue.ShopInventory then
						if Client.ShopHandler and shopInfo then
							local shopUI = PlayerGui.UI.ShopUI.ShopHolder
							Client.ShopHandler.openShop(shopUI, NPC, shopInfo)

							repeat
								task.wait(0.2)
							until not Client.ShopHandler.shopOpened or isPlayerTooFar(hrp, maxDistance)

							if Client.ShopHandler.shopOpened then
								Client.ShopHandler.closeShop()
							end

							hideDialogue(UI, dialogueUI)
							return
						end
					end

					dialogueLength = dialogueLength + 1
				end

				dialogueCurrent = dialogueCurrent + 1
			until dialogueCurrent > dialogueLength

			hideDialogue(UI, dialogueUI)
		end)
	end

	function DialogueHandler:Setup()
		for _, NPC in pairs(workspace:WaitForChild("NPCDialogue"):GetChildren()) do
			setupNPCDialogue(NPC)
		end

		workspace.NPCDialogue.ChildAdded:Connect(setupNPCDialogue)
	end

	function DialogueHandler:Init()
		DialogueHandler:Setup()

		game:GetService('UserInputService').InputBegan:Connect(function(input, gameProcessed)
			if not DialogueHandler.inDialogue then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				DialogueHandler.mouseClicked = true
			end
		end)
	end

	function DialogueHandler.Respawn()
		interactforceclose()
		DialogueHandler.inDialogue = false
		DialogueHandler.mouseClicked = false

		if DialogueHandler.distanceCheckConnection then
			DialogueHandler.distanceCheckConnection:Disconnect()
			DialogueHandler.distanceCheckConnection = nil
		end
	end

	DialogueHandler.FactionController = FactionController

	return DialogueHandler
end