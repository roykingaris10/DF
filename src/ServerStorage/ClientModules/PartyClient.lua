return function(Client)
	local PartyClient = {}

	local player = Client.player
	local Network = Client.Network
	local TweenService = game:GetService("TweenService")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ContextActionService = game:GetService("ContextActionService")

	local PlayerGui = player:WaitForChild("PlayerGui")
	local Kits = ReplicatedStorage:WaitForChild("Kits")

	local PartyState = {
		inParty = false,
		partyId = nil,
		members = {},
		leaderId = nil,
		isLeader = false,
	}

	local activeInvite = nil
	local partyMarkers = {}
	local partyInfoFrames = {}
	local healthConnections = {}
	local connections = {}

	local UI
	local HUD
	local PartyHolder
	local InvitePrompt

	local function clearPartyMarkers()
		for userId, marker in pairs(partyMarkers) do
			if marker and marker.Parent then
				marker:Destroy()
			end
		end
		partyMarkers = {}
	end

	local function clearHealthConnections()
		for userId, conn in pairs(healthConnections) do
			if conn then
				conn:Disconnect()
			end
		end
		healthConnections = {}
	end

	local function clearPartyInfoFrames()
		clearHealthConnections()
		for userId, frame in pairs(partyInfoFrames) do
			if frame and frame.Parent then
				frame:Destroy()
			end
		end
		partyInfoFrames = {}
	end

	local function createPartyMarker(targetPlayer, color)
		if targetPlayer == player then return end

		local character = targetPlayer.Character
		if not character then return end

		local head = character:FindFirstChild("Head")
		if not head then return end

		if partyMarkers[targetPlayer.UserId] then
			partyMarkers[targetPlayer.UserId]:Destroy()
		end

		local markerTemplate = Kits.UI:FindFirstChild("PartyMarkerGui")
		local newMarker

		if markerTemplate then
			newMarker = markerTemplate:Clone()

			local markerFrame = newMarker:FindFirstChild("PartyMarker")
			if markerFrame then
				local innerMarker = markerFrame:FindFirstChild("marker")
				if innerMarker then
					innerMarker.ImageColor3 = color
				end
			end
		else
			newMarker = Instance.new("BillboardGui")
			newMarker.Name = "PartyMarkerGui"
			newMarker.Size = UDim2.new(0, 50, 0, 50)
			newMarker.StudsOffset = Vector3.new(0, 3, 0)
			newMarker.AlwaysOnTop = true
			newMarker.MaxDistance = 200

			local markerFrame = Instance.new("Frame")
			markerFrame.Name = "PartyMarker"
			markerFrame.Size = UDim2.new(1, 0, 1, 0)
			markerFrame.BackgroundTransparency = 1
			markerFrame.Parent = newMarker

			local marker = Instance.new("ImageLabel")
			marker.Name = "marker"
			marker.Size = UDim2.new(0, 16, 0, 16)
			marker.Position = UDim2.new(0.5, -8, 0.5, -8)
			marker.ImageColor3 = color
			marker.BackgroundTransparency = 1
			marker.Parent = markerFrame

			local distance = Instance.new("TextLabel")
			distance.Name = "distance"
			distance.Size = UDim2.new(0, 60, 0, 20)
			distance.Position = UDim2.new(0.5, -30, 1, 5)
			distance.BackgroundTransparency = 1
			distance.TextColor3 = Color3.new(1, 1, 1)
			distance.TextStrokeTransparency = 0.5
			distance.Font = Enum.Font.GothamBold
			distance.TextSize = 12
			distance.Text = ""
			distance.Parent = markerFrame
		end

		newMarker.Parent = head
		newMarker.Adornee = head

		partyMarkers[targetPlayer.UserId] = newMarker

		return newMarker
	end

	local function updatePartyMarkers()
		for _, memberData in ipairs(PartyState.members) do
			local targetPlayer = Players:GetPlayerByUserId(memberData.userId)
			if targetPlayer and targetPlayer ~= player then
				local marker = partyMarkers[memberData.userId]

				if not marker or not marker.Parent then
					createPartyMarker(targetPlayer, memberData.color)
					marker = partyMarkers[memberData.userId]
				end

				if marker then
					local markerFrame = marker:FindFirstChild("PartyMarker")
					if markerFrame then
						-- Update color
						local innerMarker = markerFrame:FindFirstChild("marker")
						if innerMarker then
							innerMarker.ImageColor3 = memberData.color
						end

						-- Update distance
						local distanceLabel = markerFrame:FindFirstChild("distance")
						if distanceLabel and player.Character and targetPlayer.Character then
							local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
							local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

							if playerRoot and targetRoot then
								local dist = (playerRoot.Position - targetRoot.Position).Magnitude
								distanceLabel.Text = math.floor(dist) .. "m"
							end
						end
					end
				end
			end
		end

		-- Remove markers for players no longer in party
		for userId, marker in pairs(partyMarkers) do
			local stillInParty = false
			for _, memberData in ipairs(PartyState.members) do
				if memberData.userId == userId then
					stillInParty = true
					break
				end
			end

			if not stillInParty then
				if marker and marker.Parent then
					marker:Destroy()
				end
				partyMarkers[userId] = nil
			end
		end
	end

	local function setupMemberViewport(viewport, targetPlayer)
		if not viewport then 
			warn("[PartyClient] Viewport is nil")
			return 
		end
		if not targetPlayer then 
			warn("[PartyClient] Target player is nil")
			return 
		end

		local character = targetPlayer.Character
		if not character then 
			warn("[PartyClient] Character not found for " .. targetPlayer.Name)
			return 
		end

		local head = character:FindFirstChild("Head")
		if not head then 
			warn("[PartyClient] Head not found for " .. targetPlayer.Name)
			return 
		end

		-- Clear existing viewport content
		for _, child in ipairs(viewport:GetChildren()) do
			if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Camera") or child:IsA("Accessory") then
				child:Destroy()
			end
		end

		local headModel = Instance.new("Model")
		headModel.Name = "HeadModel"
		headModel.Parent = viewport

		-- Clone head exactly as in the working code
		local headClone = head:Clone()
		headClone.Anchored = true
		headClone.CanCollide = false
		headClone.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0)

		-- Remove only welds/motors
		for _, child in ipairs(headClone:GetChildren()) do
			if child:IsA("Weld") or child:IsA("Motor6D") then
				child:Destroy()
			end
		end

		headClone.Parent = headModel
		headModel.PrimaryPart = headClone

		-- Clone all head accessories exactly as in working code
		for _, accessory in ipairs(character:GetChildren()) do
			if accessory:IsA("Accessory") then
				local handle = accessory:FindFirstChild("Handle")
				if handle then
					local isHeadAccessory = false

					-- Check attachments for head-related names
					for _, att in ipairs(handle:GetChildren()) do
						if att:IsA("Attachment") then
							local name = att.Name:lower()
							if name:find("hat") or name:find("hair") or name:find("face") or name:find("head") then
								isHeadAccessory = true
								break
							end
						end
					end

					-- Fallback: check distance from head
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

		-- Setup camera
		local camera = Instance.new("Camera")
		camera.FieldOfView = 50
		camera.CFrame = CFrame.new(Vector3.new(0, 0, 3), Vector3.zero)
		camera.Parent = viewport
		viewport.CurrentCamera = camera

		print("[PartyClient] Viewport setup complete for " .. targetPlayer.Name)
	end

	local function setupRadialHealthBar(frame, targetPlayer)
		local CDHolder = frame:FindFirstChild("CDHolder")
		if not CDHolder then return end

		local F1 = CDHolder:FindFirstChild("Frame1")
		local F2 = CDHolder:FindFirstChild("Frame2")
		if not F1 or not F2 then return end

		local F1Image = F1:FindFirstChild("ImageLabel")
		local F2Image = F2:FindFirstChild("ImageLabel")
		if not F1Image or not F2Image then return end

		local F1Gradient = F1Image:FindFirstChild("UIGradient")
		local F2Gradient = F2Image:FindFirstChild("UIGradient")
		if not F1Gradient or not F2Gradient then return end

		local Percentage = CDHolder:FindFirstChild("Percentage")

		-- Initial setup - SWAPPED from before
		F1Gradient.Rotation = 360
		F2Gradient.Rotation = 180

		local function updateGradientStyle()
			if not Percentage then return end
			local missingType = Percentage:FindFirstChild("MissingPartType") and Percentage.MissingPartType.Value or "Trans"

			if missingType == "Color" then
				local colorOfMissing = Percentage:FindFirstChild("ColorOfMissingPart") and Percentage.ColorOfMissingPart.Value or Color3.new(0.3, 0.3, 0.3)
				local colorOfPercent = Percentage:FindFirstChild("ColorOfPercentPart") and Percentage.ColorOfPercentPart.Value or Color3.new(0, 1, 0)

				local gradientColor = ColorSequence.new({
					ColorSequenceKeypoint.new(0, colorOfMissing),
					ColorSequenceKeypoint.new(0.5, colorOfMissing),
					ColorSequenceKeypoint.new(0.501, colorOfPercent),
					ColorSequenceKeypoint.new(1, colorOfPercent)
				})
				F1Gradient.Color = gradientColor
				F2Gradient.Color = gradientColor
				F1Gradient.Transparency = NumberSequence.new(0)
				F2Gradient.Transparency = NumberSequence.new(0)
			elseif missingType == "Trans" then
				local transOfMissing = Percentage:FindFirstChild("TransOfMissingPart") and Percentage.TransOfMissingPart.Value or 1
				local transOfPercent = Percentage:FindFirstChild("TransOfPercentPart") and Percentage.TransOfPercentPart.Value or 0

				local gradientTransparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, transOfMissing),
					NumberSequenceKeypoint.new(0.5, transOfMissing),
					NumberSequenceKeypoint.new(0.501, transOfPercent),
					NumberSequenceKeypoint.new(1, transOfPercent)
				})
				F1Gradient.Transparency = gradientTransparency
				F2Gradient.Transparency = gradientTransparency
				F1Gradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
				F2Gradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
			end
		end

		updateGradientStyle()

		local function updateHealthBar()
			local character = targetPlayer.Character
			if not character then return end

			local health = character:GetAttribute("Health") or 100
			local maxHealth = character:GetAttribute("MaxHealth") or 100

			local healthPercent = math.clamp(health / maxHealth, 0, 1)
			local remaining = healthPercent * 360

			-- Use +180 offset to start from top and drain clockwise
			if remaining >= 180 then
				F2Gradient.Rotation = remaining + 180
				F1Gradient.Rotation = 360
			else
				F2Gradient.Rotation = 360
				F1Gradient.Rotation = remaining + 180
			end
		end

		-- Initial update
		updateHealthBar()

		-- Connect to health changes
		local character = targetPlayer.Character
		if character then
			local conn = character:GetAttributeChangedSignal("Health"):Connect(updateHealthBar)
			healthConnections[targetPlayer.UserId] = conn
		end

		-- Handle character respawn
		local charAddedConn
		charAddedConn = targetPlayer.CharacterAdded:Connect(function(newChar)
			task.wait(0.5)
			updateHealthBar()

			-- Reconnect health listener
			if healthConnections[targetPlayer.UserId] then
				healthConnections[targetPlayer.UserId]:Disconnect()
			end
			healthConnections[targetPlayer.UserId] = newChar:GetAttributeChangedSignal("Health"):Connect(updateHealthBar)
		end)
		table.insert(connections, charAddedConn)
	end

	local function getPlayerFullName(targetPlayer)
		local statFolder = targetPlayer:FindFirstChild("StatFolder")
		if not statFolder then return targetPlayer.DisplayName end

		local userFolder = statFolder:FindFirstChild("UserFolder")
		if not userFolder then return targetPlayer.DisplayName end

		local firstName = userFolder:GetAttribute("FirstName") or ""
		local middleName = userFolder:GetAttribute("MiddleName") or ""
		local lastName = userFolder:GetAttribute("LastName") or ""

		local fullName = firstName
		if middleName ~= "" then
			fullName = fullName .. " " .. middleName
		end
		if lastName ~= "" then
			fullName = fullName .. " " .. lastName
		end

		if fullName == "" then
			return targetPlayer.DisplayName
		end

		return fullName
	end

	local function getPlayerLevel(targetPlayer)
		local statFolder = targetPlayer:FindFirstChild("StatFolder")
		if not statFolder then return 1 end

		local userFolder = statFolder:FindFirstChild("UserFolder")
		if not userFolder then return 1 end

		return userFolder:GetAttribute("Level") or 1
	end

	local function createPartyInfoFrame(memberData, index)
		local partyInfoTemplate = Kits.UI:FindFirstChild("partyInfo")
		if not partyInfoTemplate then
			warn("[PartyClient] partyInfo template not found in Kits.UI")
			return nil
		end

		local partyFrame = PartyHolder:FindFirstChild("partyFrame")
		if not partyFrame then
			warn("[PartyClient] partyFrame not found in PartyHolder")
			return nil
		end

		local targetPlayer = Players:GetPlayerByUserId(memberData.userId)
		if not targetPlayer then 
			warn("[PartyClient] Player not found for userId: " .. tostring(memberData.userId))
			return nil 
		end

		-- Wait for character if not loaded
		local character = targetPlayer.Character
		if not character then
			warn("[PartyClient] Waiting for character of " .. targetPlayer.Name)
			character = targetPlayer.CharacterAdded:Wait()
			task.wait(0.5)
		end

		local newFrame = partyInfoTemplate:Clone()
		newFrame.Name = "partyInfo_" .. memberData.userId
		newFrame.LayoutOrder = index
		newFrame.Visible = true
		newFrame.Parent = partyFrame

		local colour = newFrame:FindFirstChild("colour")
		if colour then
			colour.ImageColor3 = memberData.color
		end

		local info = newFrame:FindFirstChild("info")
		if info then
			local playerFolder = info:FindFirstChild("player")
			if playerFolder then
				local playerName = playerFolder:FindFirstChild("playerName")
				local playerLevel = playerFolder:FindFirstChild("playerLevel")

				if playerName then
					local fullName = getPlayerFullName(targetPlayer)
					local displayText = fullName
					if memberData.isLeader then
						displayText = "★ " .. displayText
					end
					playerName.Text = displayText:upper()
				end

				if playerLevel then
					local level = getPlayerLevel(targetPlayer)
					playerLevel.Text = "Lv. " .. tostring(level)
				end
			end
		end

		local inner = newFrame:FindFirstChild("inner")
		if inner then
			local playerView = inner:FindFirstChild("playerView")
			if playerView then
				task.spawn(function()
					task.wait(0.3)
					setupMemberViewport(playerView, targetPlayer)
				end)
			end
		end

		-- Setup radial health bar
		task.spawn(function()
			task.wait(0.5)
			setupRadialHealthBar(newFrame, targetPlayer)
		end)

		partyInfoFrames[memberData.userId] = newFrame

		print("[PartyClient] Created partyInfo frame for " .. targetPlayer.Name)

		return newFrame
	end

	local function updatePartyUI()
		if not PartyHolder then return end

		local partyFrame = PartyHolder:FindFirstChild("partyFrame")
		if not partyFrame then return end

		local commands = PartyHolder:FindFirstChild("Commands")

		-- Filter out self from members for UI display
		local otherMembers = {}
		for _, memberData in ipairs(PartyState.members) do
			if memberData.userId ~= player.UserId then
				table.insert(otherMembers, memberData)
			end
		end

		local hasOtherMembers = #otherMembers > 0

		-- Always show PartyHolder if in party (for Commands)
		-- But only show partyFrame content if there are other members
		if PartyState.inParty then
			PartyHolder.Visible = true
			if commands then
				commands.Visible = true
			end
		else
			PartyHolder.Visible = false
			clearPartyMarkers()
			clearPartyInfoFrames()
			return
		end

		if not hasOtherMembers then
			clearPartyMarkers()
			clearPartyInfoFrames()
			return
		end

		local currentUserIds = {}
		for _, memberData in ipairs(otherMembers) do
			currentUserIds[memberData.userId] = true
		end

		-- Remove frames for members no longer in party
		for userId, frame in pairs(partyInfoFrames) do
			if not currentUserIds[userId] then
				if frame and frame.Parent then
					frame:Destroy()
				end
				partyInfoFrames[userId] = nil

				if healthConnections[userId] then
					healthConnections[userId]:Disconnect()
					healthConnections[userId] = nil
				end
			end
		end

		-- Create or update frames for each member (excluding self)
		for i, memberData in ipairs(otherMembers) do
			local targetPlayer = Players:GetPlayerByUserId(memberData.userId)
			if not targetPlayer then 
				continue 
			end

			local existingFrame = partyInfoFrames[memberData.userId]

			if existingFrame and existingFrame.Parent then
				-- Update existing frame
				existingFrame.LayoutOrder = i

				local colour = existingFrame:FindFirstChild("colour")
				if colour then
					colour.ImageColor3 = memberData.color
				end

				local info = existingFrame:FindFirstChild("info")
				if info then
					local playerFolder = info:FindFirstChild("player")
					if playerFolder then
						local playerName = playerFolder:FindFirstChild("playerName")
						if playerName then
							local fullName = getPlayerFullName(targetPlayer)
							local displayText = fullName
							if memberData.isLeader then
								displayText = "★ " .. displayText
							end
							playerName.Text = displayText:upper()
						end

						local playerLevel = playerFolder:FindFirstChild("playerLevel")
						if playerLevel then
							local level = getPlayerLevel(targetPlayer)
							playerLevel.Text = "Lv. " .. tostring(level)
						end
					end
				end
			else
				-- Create new frame
				task.spawn(function()
					createPartyInfoFrame(memberData, i)
				end)
			end
		end

		updatePartyMarkers()
	end

	function PartyClient:SetupInviteUI()
		local partyFrame = PartyHolder:FindFirstChild("partyFrame")
		if not partyFrame then return end

		local commands = PartyHolder:FindFirstChild("Commands")
		if not commands then return end

		local inviteBox = commands:FindFirstChild("InviteBox")
		local inviteButton = commands:FindFirstChild("Invite")
		local leaveButton = commands:FindFirstChild("Leave")

		local currentMatch = nil

		local function findMatch(text)
			if text == "" then return nil end
			local lowerText = text:lower()
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player then
					if plr.Name:lower():sub(1, #text) == lowerText or 
						plr.DisplayName:lower():sub(1, #text) == lowerText then
						return plr.Name
					end
				end
			end
			return nil
		end

		if inviteBox then
			table.insert(connections, inviteBox:GetPropertyChangedSignal("Text"):Connect(function()
				currentMatch = findMatch(inviteBox.Text)
			end))
		end

		local function onTabComplete(actionName, inputState)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end

			if inviteBox and inviteBox:IsFocused() and currentMatch then
				inviteBox.Text = currentMatch
				inviteBox.CursorPosition = #inviteBox.Text + 1
				return Enum.ContextActionResult.Sink
			end

			return Enum.ContextActionResult.Pass
		end

		ContextActionService:BindAction("PartyInviteTabComplete", onTabComplete, false, Enum.KeyCode.Tab)

		if inviteButton then
			table.insert(connections, inviteButton.Activated:Connect(function()
				if not inviteBox then return end

				local targetName = inviteBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
				if targetName == "" then
					PartyClient:ShowNotification("Enter a player name", false)
					return
				end

				-- Check if trying to invite self before sending to server
				if targetName:lower() == player.Name:lower() or targetName:lower() == player.DisplayName:lower() then
					PartyClient:ShowNotification("You cannot invite yourself", false)
					inviteBox.Text = ""
					return
				end

				Network:post("PartyInvite", targetName)
				inviteBox.Text = ""
			end))
		end

		if leaveButton then
			table.insert(connections, leaveButton.Activated:Connect(function()
				Network:post("PartyLeave")
			end))
		end
	end

	function PartyClient:SetupInvitePrompt()
		InvitePrompt = UI:FindFirstChild("InvitePrompt")
		if not InvitePrompt then
			warn("[PartyClient] InvitePrompt not found in UI")
			return
		end

		local acceptButton = InvitePrompt:FindFirstChild("acceptButton")
		local declineButton = InvitePrompt:FindFirstChild("declineButton")

		if acceptButton then
			table.insert(connections, acceptButton.Activated:Connect(function()
				if activeInvite then
					Network:post("PartyInviteResponse", activeInvite.inviterName, true)
					activeInvite = nil
					InvitePrompt.Visible = false
				end
			end))
		end

		if declineButton then
			table.insert(connections, declineButton.Activated:Connect(function()
				if activeInvite then
					Network:post("PartyInviteResponse", activeInvite.inviterName, false)
					activeInvite = nil
					InvitePrompt.Visible = false
				end
			end))
		end
	end

	function PartyClient:ShowInvitePrompt(inviterName, inviterUserId)
		if not InvitePrompt then 
			warn("[PartyClient] Cannot show invite - InvitePrompt not found")
			return 
		end

		activeInvite = {
			inviterName = inviterName,
			inviterUserId = inviterUserId,
		}

		local inviteText = InvitePrompt:FindFirstChild("inviteText")
		if inviteText then
			inviteText.Text = inviterName .. " has invited you to their party"
		end

		InvitePrompt.Visible = true

		task.delay(30, function()
			if activeInvite and activeInvite.inviterName == inviterName then
				activeInvite = nil
				InvitePrompt.Visible = false
			end
		end)
	end

	function PartyClient:ShowNotification(message, isSuccess)
		local notificationFrame = UI:FindFirstChild("rejectPrompt")
		if not notificationFrame then 
			warn("[PartyClient] " .. message)
			return 
		end

		notificationFrame.Text = message
		notificationFrame.TextColor3 = isSuccess and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		notificationFrame.Visible = true

		task.delay(3, function()
			if notificationFrame.Text == message then
				notificationFrame.Visible = false
			end
		end)
	end

	function PartyClient:BindNetworkEvents()
		Network:bindEvent("PartyUpdated", function(partyData)
			print("[PartyClient] PartyUpdated received with " .. #partyData.members .. " members")
			PartyState.inParty = true
			PartyState.partyId = partyData.partyId
			PartyState.members = partyData.members
			PartyState.leaderId = partyData.leaderId
			PartyState.isLeader = partyData.leaderId == player.UserId
			updatePartyUI()
		end)

		-- CHANGED: Use NotificationController instead of direct prompt
		Network:bindEvent("PartyInviteReceived", function(inviterName, inviterUserId)
			-- Try to use NotificationController if available
			local NotificationController = Client.NotificationController
			if NotificationController then
				NotificationController:AddPartyInvite(inviterName, inviterUserId)
			else
				-- Fallback to old system
				PartyClient:ShowInvitePrompt(inviterName, inviterUserId)
			end
		end)

		Network:bindEvent("PartyInviteResult", function(targetName, accepted, reason)
			if accepted then
				PartyClient:ShowNotification(targetName .. " joined the party!", true)
			else
				local msg = targetName .. " "
				if reason == "expired" then
					msg = msg .. "didn't respond in time"
				elseif reason == "declined" then
					msg = msg .. "declined your invite"
				elseif reason == "party_full" then
					msg = "Party is full"
				else
					msg = msg .. "couldn't join"
				end
				PartyClient:ShowNotification(msg, false)
			end
		end)

		Network:bindEvent("PartyInviteError", function(errorMessage)
			PartyClient:ShowNotification(errorMessage, false)
		end)

		Network:bindEvent("RemovedFromParty", function()
			PartyState.inParty = false
			PartyState.partyId = nil
			PartyState.members = {}
			PartyState.leaderId = nil
			PartyState.isLeader = false
			updatePartyUI()
			PartyClient:ShowNotification("You left the party", false)
		end)

		Network:bindEvent("PartyMemberJoined", function(memberName)
			PartyClient:ShowNotification(memberName .. " joined the party", true)
		end)

		Network:bindEvent("PartyMemberLeft", function(memberName)
			PartyClient:ShowNotification(memberName .. " left the party", false)
		end)

		Network:bindEvent("PartyLeaderChanged", function(newLeaderName)
			PartyState.isLeader = (newLeaderName == getPlayerFullName(player)) or (newLeaderName == player.Name)
			PartyClient:ShowNotification(newLeaderName .. " is now the party leader", true)
		end)

		Network:bindEvent("PartyNotification", function(message)
			PartyClient:ShowNotification(message, true)
		end)

		Network:bindEvent("PartyDisbanded", function()
			PartyState.inParty = false
			PartyState.partyId = nil
			PartyState.members = {}
			PartyState.leaderId = nil
			PartyState.isLeader = false
			updatePartyUI()
			PartyClient:ShowNotification("Party has been disbanded", false)
		end)
	end

	function PartyClient:StartMarkerUpdate()
		local frameCount = 0
		table.insert(connections, RunService.Heartbeat:Connect(function()
			if not PartyState.inParty then return end

			frameCount += 1
			if frameCount % 6 ~= 0 then return end
			frameCount = 0

			updatePartyMarkers()
		end))
	end

	function PartyClient:GetPartyState()
		local success, state = pcall(function()
			return Network:get("PartyGetState")
		end)

		if success and state and state.inParty then
			PartyState.inParty = true
			PartyState.partyId = state.partyId
			PartyState.members = state.members
			PartyState.leaderId = state.leaderId
			PartyState.isLeader = state.isLeader
			updatePartyUI()
		end
	end

	function PartyClient:CreateParty()
		local success, result = pcall(function()
			return Network:get("PartyCreate")
		end)

		if success and result then
			if result.success then
				PartyClient:ShowNotification("Party created!", true)
			else
				PartyClient:ShowNotification(result.message, false)
			end
			return result
		end

		return { success = false, message = "Failed to create party" }
	end

	function PartyClient:InvitePlayer(targetName)
		Network:post("PartyInvite", targetName)
	end

	function PartyClient:LeaveParty()
		Network:post("PartyLeave")
	end

	function PartyClient:KickPlayer(targetUserId)
		Network:post("PartyKick", targetUserId)
	end

	function PartyClient:TransferLeadership(targetUserId)
		Network:post("PartyTransferLeader", targetUserId)
	end

	function PartyClient:IsInParty()
		return PartyState.inParty
	end

	function PartyClient:IsLeader()
		return PartyState.isLeader
	end

	function PartyClient:GetMembers()
		return PartyState.members
	end

	function PartyClient:Init()
		UI = PlayerGui:WaitForChild("UI")
		HUD = PlayerGui:WaitForChild("HUD")
		PartyHolder = HUD:WaitForChild("PartyHolder")

		PartyClient:BindNetworkEvents()
		PartyClient:SetupInviteUI()
		PartyClient:SetupInvitePrompt()
		PartyClient:StartMarkerUpdate()

		task.delay(2, function()
			PartyClient:GetPartyState()
		end)

		Players.PlayerRemoving:Connect(function(leavingPlayer)
			if partyMarkers[leavingPlayer.UserId] then
				partyMarkers[leavingPlayer.UserId]:Destroy()
				partyMarkers[leavingPlayer.UserId] = nil
			end
			if partyInfoFrames[leavingPlayer.UserId] then
				partyInfoFrames[leavingPlayer.UserId]:Destroy()
				partyInfoFrames[leavingPlayer.UserId] = nil
			end
			if healthConnections[leavingPlayer.UserId] then
				healthConnections[leavingPlayer.UserId]:Disconnect()
				healthConnections[leavingPlayer.UserId] = nil
			end
		end)
	end

	function PartyClient:Cleanup()
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		connections = {}
		clearPartyMarkers()
		clearPartyInfoFrames()
		ContextActionService:UnbindAction("PartyInviteTabComplete")
	end

	return PartyClient
end