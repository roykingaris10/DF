-- NotificationController
-- Location: Client > ClientModules > NotificationController

return function(Client)
	local NotificationController = {}

	local player = Client.player
	local Network = Client.Network
	local TweenService = game:GetService("TweenService")
	local HttpService = game:GetService("HttpService")
	local SoundService = game:GetService("SoundService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local PlayerGui = player:WaitForChild("PlayerGui")
	local UI = PlayerGui:WaitForChild("UI")
	local Kits = ReplicatedStorage:WaitForChild("Kits")

	-- UI References
	local topBtns = UI:WaitForChild("topBtns")
	local notiButton = topBtns:WaitForChild("noti")
	local notiBtn = notiButton:WaitForChild("btn")
	local notiRed = notiButton:WaitForChild("notiRed")
	local notiNum = notiButton:WaitForChild("notiNum")
	local redPulse = notiButton:FindFirstChild("redPulse")

	local topHolder = UI:WaitForChild("topHolder")
	local popupHolder = topHolder:WaitForChild("popupHolder")
	local popUpFrame = popupHolder:WaitForChild("popUpFrame")
	local popupTitle = popUpFrame:WaitForChild("title")
	local popupImage = popUpFrame:FindFirstChild("image")
	local popupType = popUpFrame:WaitForChild("popupType")
	local popupInputText = popUpFrame:WaitForChild("inputText")
	local acceptDecline = popUpFrame:WaitForChild("acceptDecline")
	local acceptBtn = acceptDecline:WaitForChild("acceptBtn")
	local declineBtn = acceptDecline:WaitForChild("declineBtn")
	local popupCloseBtn = popUpFrame:FindFirstChild("close")

	local NotificationHolder = topHolder:WaitForChild("NotificationHolder")
	local notiScroll = NotificationHolder:WaitForChild("notiScroll")
	local categoriesHolder = NotificationHolder:FindFirstChild("categoriesHolder")
	local categoriesContainer = categoriesHolder and categoriesHolder:FindFirstChild("categories")
	local clearContainer = categoriesHolder and categoriesHolder:FindFirstChild("clear")

	local toastLabel = UI:FindFirstChild("rejectPrompt")

	-- Template from ReplicatedStorage
	local notiTemplate = Kits.UI:WaitForChild("notiHolder")

	-- Empty state text - find anywhere under NotificationHolder
	local NoneText = NotificationHolder:FindFirstChild("NoneText", true)

	local Sounds = {
		notification = Instance.new("Sound"),
		click = Instance.new("Sound"),
		open = Instance.new("Sound"),
		hover = Instance.new("Sound"),
	}

	Sounds.notification.SoundId = "rbxassetid://83219280251618"
	Sounds.notification.Volume = 0.5
	Sounds.notification.Parent = SoundService

	Sounds.click.SoundId = "rbxassetid://103866342467024"
	Sounds.click.Volume = 0.3
	Sounds.click.Parent = SoundService

	Sounds.open.SoundId = "rbxassetid://10128766965"
	Sounds.open.Volume = 0.4
	Sounds.open.Parent = SoundService

	Sounds.hover.SoundId = "rbxassetid://14566136152"
	Sounds.hover.Volume = 0.15
	Sounds.hover.Parent = SoundService

	local function playSound(soundName)
		local sound = Sounds[soundName]
		if sound then
			sound:Stop()
			sound:Play()
		end
	end

	local CATEGORIES = {
		Combat = {
			color = Color3.fromRGB(220, 60, 60),
			icon = "rbxassetid://74350600789323",
			priority = 1,
		},
		Progress = {
			color = Color3.fromRGB(255, 200, 50),
			icon = "rbxassetid://74350600789323",
			priority = 2,
		},
		Social = {
			color = Color3.fromRGB(80, 170, 255),
			icon = "rbxassetid://74350600789323",
			priority = 3,
		},
		World = {
			color = Color3.fromRGB(100, 220, 130),
			icon = "rbxassetid://74350600789323",
			priority = 4,
		},
	}

	local notifications = {}
	local notificationOrder = {}
	local notificationFrames = {}
	local frameConnections = {}
	local notifByKey = {}
	local currentFilter = "All"
	local currentPopupNotificationId = nil
	local connections = {}

	-- ═══════════════════════════════════════════════════════════
	-- UTILITY FUNCTIONS
	-- ═══════════════════════════════════════════════════════════

	local function generateId()
		return HttpService:GenerateGUID(false)
	end

	local function getNotificationCount()
		local count = 0
		for _ in pairs(notifications) do
			count = count + 1
		end
		return count
	end

	local function getUnreadCount()
		local count = 0
		for _, notif in pairs(notifications) do
			if not notif.read then
				count = count + 1
			end
		end
		return count
	end

	local clearTextLabels = {}

	local function updateClearLabel()
		local count = getNotificationCount()
		for _, label in ipairs(clearTextLabels) do
			if label and label.Parent then
				label.Text = string.format("CLEAR ALL (%d)", count)
			end
		end
	end

	local function updateEmptyState()
		local hasNotifications = getNotificationCount() > 0
		if NoneText then NoneText.Visible = not hasNotifications end
		notiScroll.Visible = hasNotifications
		updateClearLabel()
	end

	local function showToast(message, isSuccess)
		if not toastLabel then return end

		toastLabel.Text = message
		toastLabel.TextColor3 = isSuccess and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		toastLabel.Visible = true

		task.delay(3, function()
			if toastLabel.Text == message then
				toastLabel.Visible = false
			end
		end)
	end

	local function updateBadge()
		local count = getUnreadCount()

		if count > 0 then
			notiNum.Text = count > 99 and "99+" or tostring(count)
			notiNum.Visible = true
			notiRed.Visible = true
		else
			notiNum.Visible = false
			notiRed.Visible = false
		end
	end

	local function pulseRedBadge()
		if not redPulse then return end

		redPulse.Visible = true
		redPulse.Size = UDim2.new(1, 0, 1, 0)

		if redPulse:IsA("ImageLabel") then
			redPulse.ImageTransparency = 0
		elseif redPulse:IsA("Frame") then
			redPulse.BackgroundTransparency = 0
		end

		local pulseTween = TweenService:Create(redPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.new(1.6, 0, 1.6, 0),
		})

		local fadeTween
		if redPulse:IsA("ImageLabel") then
			fadeTween = TweenService:Create(redPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				ImageTransparency = 1
			})
		else
			fadeTween = TweenService:Create(redPulse, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1
			})
		end

		pulseTween:Play()
		fadeTween:Play()

		fadeTween.Completed:Once(function()
			redPulse.Visible = false
		end)
	end

	-- ═══════════════════════════════════════════════════════════
	-- POPUP FUNCTIONS
	-- ═══════════════════════════════════════════════════════════

	local function isPopupOpen()
		return popupHolder.Visible and currentPopupNotificationId ~= nil
	end

	local function isPopupShowingNotification(notifId)
		return isPopupOpen() and currentPopupNotificationId == notifId
	end

	local function showPopup(notif)
		currentPopupNotificationId = notif.id

		popupTitle.Text = notif.title:upper()
		popupType.Text = notif.category:upper()
		popupType.TextColor3 = CATEGORIES[notif.category].color

		if popupInputText then
			popupInputText.Text = notif.message or ""
		end

		if popupImage then
			local icon = notif.icon or CATEGORIES[notif.category].icon
			popupImage.Image = icon
			popupImage.ImageColor3 = CATEGORIES[notif.category].color
		end

		if notif.actionable then
			acceptDecline.Visible = true
			acceptBtn.Text = notif.acceptText or "Accept"
			declineBtn.Text = notif.declineText or "Decline"
		else
			acceptDecline.Visible = false
		end

		playSound("open")
		popupHolder.Visible = true
	end

	local function hidePopup()
		popupHolder.Visible = false
		currentPopupNotificationId = nil
	end

	local function onNotificationClicked(notifId)
		playSound("click")

		if isPopupShowingNotification(notifId) then
			hidePopup()
			return
		end

		local notif = notifications[notifId]
		if notif then
			NotificationController:MarkAsRead(notifId)
			showPopup(notif)
		end
	end

	-- ═══════════════════════════════════════════════════════════
	-- HOVER EFFECT
	-- ═══════════════════════════════════════════════════════════

	local function setupHoverEffect(frame, notifId)
		local originalBgTransparency = frame.BackgroundTransparency
		local isHovering = false

		local enterConn = frame.MouseEnter:Connect(function()
			if isHovering then return end
			isHovering = true
			playSound("hover")

			if frame.BackgroundTransparency < 1 then
				TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = math.max(0, originalBgTransparency - 0.15)
				}):Play()
			end
		end)

		local leaveConn = frame.MouseLeave:Connect(function()
			isHovering = false

			if frame.BackgroundTransparency < 1 then
				TweenService:Create(frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					BackgroundTransparency = originalBgTransparency
				}):Play()
			end
		end)

		if not frameConnections[notifId] then
			frameConnections[notifId] = {}
		end
		table.insert(frameConnections[notifId], enterConn)
		table.insert(frameConnections[notifId], leaveConn)
	end

	-- ═══════════════════════════════════════════════════════════
	-- NOTIFICATION FRAME CREATION
	-- ═══════════════════════════════════════════════════════════

	local function createNotificationFrame(notif)
		local frame = notiTemplate:Clone()
		frame.Name = "Notification_" .. notif.id
		frame.Visible = true
		frame.LayoutOrder = -notif.timestamp

		local notiInfo = frame:FindFirstChild("notiInfo")
		local notiName = frame:FindFirstChild("notiName")

		if notiName and (notiName:IsA("TextLabel") or notiName:IsA("TextButton")) then
			notiName.Text = notif.title:upper()
		end

		if notiInfo then
			local typeLabel = notiInfo:FindFirstChild("type")

			if typeLabel and (typeLabel:IsA("TextLabel") or typeLabel:IsA("TextButton")) then
				typeLabel.Text = notif.category:upper()
				typeLabel.TextColor3 = CATEGORIES[notif.category].color
			end
		end

		frameConnections[notif.id] = {}

		local clickTarget = nil
		if notiInfo and (notiInfo:IsA("ImageButton") or notiInfo:IsA("TextButton")) then
			clickTarget = notiInfo
		else
			clickTarget = frame:FindFirstChildWhichIsA("ImageButton") or frame:FindFirstChildWhichIsA("TextButton")
		end

		if not clickTarget then
			local view = frame:FindFirstChild("View")
			if view and (view:IsA("ImageButton") or view:IsA("TextButton")) then
				clickTarget = view
			end
		end

		if clickTarget then
			local clickConn = clickTarget.Activated:Connect(function()
				onNotificationClicked(notif.id)
			end)
			table.insert(frameConnections[notif.id], clickConn)
			setupHoverEffect(clickTarget, notif.id)
		end

		frame.Parent = notiScroll
		notificationFrames[notif.id] = frame

		return frame
	end

	local function removeNotificationFrame(id)
		if frameConnections[id] then
			for _, conn in ipairs(frameConnections[id]) do
				conn:Disconnect()
			end
			frameConnections[id] = nil
		end

		local frame = notificationFrames[id]
		if frame and frame.Parent then
			frame:Destroy()
		end
		notificationFrames[id] = nil
	end

	local function refreshNotificationList()
		for id, conns in pairs(frameConnections) do
			for _, conn in ipairs(conns) do
				conn:Disconnect()
			end
		end
		frameConnections = {}

		for _, frame in pairs(notificationFrames) do
			if frame and frame.Parent then
				frame:Destroy()
			end
		end
		notificationFrames = {}

		for _, id in ipairs(notificationOrder) do
			local notif = notifications[id]
			if notif and (currentFilter == "All" or notif.category == currentFilter) then
				createNotificationFrame(notif)
			end
		end

		updateEmptyState()
	end

	-- ═══════════════════════════════════════════════════════════
	-- ACCEPT / DECLINE HANDLERS
	-- ═══════════════════════════════════════════════════════════

	local function handleAccept()
		if not currentPopupNotificationId then return end

		local notif = notifications[currentPopupNotificationId]
		if not notif then
			hidePopup()
			return
		end

		local onAcceptCallback = notif.onAccept
		local notifData = notif.data
		local notifId = notif.id

		playSound("click")
		hidePopup()
		NotificationController:RemoveNotification(notifId)

		if onAcceptCallback then
			task.spawn(function()
				onAcceptCallback(notifData)
			end)
		end
	end

	local function handleDecline()
		if not currentPopupNotificationId then return end

		local notif = notifications[currentPopupNotificationId]
		if not notif then
			hidePopup()
			return
		end

		local onDeclineCallback = notif.onDecline
		local notifData = notif.data
		local notifId = notif.id

		playSound("click")
		hidePopup()
		NotificationController:RemoveNotification(notifId)

		if onDeclineCallback then
			task.spawn(function()
				onDeclineCallback(notifData)
			end)
		end
	end

	-- ═══════════════════════════════════════════════════════════
	-- PUBLIC API
	-- ═══════════════════════════════════════════════════════════

	local function applyOptionsToNotif(notif, category, title, options)
		notif.category = category
		notif.title = title
		notif.message = options.message or notif.message or ""
		notif.icon = options.icon or notif.icon
		notif.actionable = options.actionable or false
		notif.acceptText = options.acceptText
		notif.declineText = options.declineText
		notif.data = options.data or notif.data or {}
		notif.onAccept = options.onAccept
		notif.onDecline = options.onDecline
	end

	local function refreshFrameForNotif(notif)
		local frame = notificationFrames[notif.id]
		if not frame then return end
		local notiName = frame:FindFirstChild("notiName")
		if notiName and (notiName:IsA("TextLabel") or notiName:IsA("TextButton")) then
			notiName.Text = notif.title:upper()
		end
		local notiInfo = frame:FindFirstChild("notiInfo")
		if notiInfo then
			local typeLabel = notiInfo:FindFirstChild("type")
			if typeLabel and (typeLabel:IsA("TextLabel") or typeLabel:IsA("TextButton")) then
				typeLabel.Text = notif.category:upper()
				typeLabel.TextColor3 = CATEGORIES[notif.category].color
			end
		end
	end

	local function refreshOpenPopupIfMatches(notif)
		if not isPopupShowingNotification(notif.id) then return end
		popupTitle.Text = notif.title:upper()
		popupType.Text = notif.category:upper()
		popupType.TextColor3 = CATEGORIES[notif.category].color
		if popupInputText then
			popupInputText.Text = notif.message or ""
		end
		if popupImage then
			local icon = notif.icon or CATEGORIES[notif.category].icon
			popupImage.Image = icon
			popupImage.ImageColor3 = CATEGORIES[notif.category].color
		end
	end

	function NotificationController:AddNotification(category, title, options)
		options = options or {}

		if not CATEGORIES[category] then
			warn("[NotificationController] Invalid category:", category, "- defaulting to World")
			category = "World"
		end

		if options.key then
			local existingId = notifByKey[options.key]
			if existingId and notifications[existingId] then
				local notif = notifications[existingId]
				applyOptionsToNotif(notif, category, title, options)
				notif.read = false
				notif.timestamp = os.time()
				refreshFrameForNotif(notif)
				refreshOpenPopupIfMatches(notif)
				updateBadge()
				pulseRedBadge()
				return existingId
			end
		end

		local id = generateId()
		local notif = {
			id = id,
			key = options.key,
			category = category,
			title = title,
			message = options.message or "",
			icon = options.icon,
			actionable = options.actionable or false,
			acceptText = options.acceptText,
			declineText = options.declineText,
			data = options.data or {},
			onAccept = options.onAccept,
			onDecline = options.onDecline,
			timestamp = os.time(),
			read = false,
		}

		notifications[id] = notif
		if options.key then notifByKey[options.key] = id end
		table.insert(notificationOrder, 1, id)

		if currentFilter == "All" or currentFilter == category then
			createNotificationFrame(notif)
		end

		playSound("notification")
		updateBadge()
		pulseRedBadge()
		updateEmptyState()

		if options.expiresIn and options.expiresIn > 0 then
			task.delay(options.expiresIn, function()
				if notifications[id] then
					if isPopupShowingNotification(id) then
						hidePopup()
					end
					NotificationController:RemoveNotification(id)
				end
			end)
		end

		return id
	end

	function NotificationController:RemoveNotification(id)
		local notif = notifications[id]
		if not notif then return end

		if isPopupShowingNotification(id) then
			hidePopup()
		end

		if notif.key and notifByKey[notif.key] == id then
			notifByKey[notif.key] = nil
		end

		notifications[id] = nil
		removeNotificationFrame(id)

		for i, orderId in ipairs(notificationOrder) do
			if orderId == id then
				table.remove(notificationOrder, i)
				break
			end
		end

		updateBadge()
		updateEmptyState()
	end

	function NotificationController:MarkAsRead(id)
		local notif = notifications[id]
		if not notif then return end

		notif.read = true
		updateBadge()
	end

	function NotificationController:MarkAllAsRead()
		for id in pairs(notifications) do
			notifications[id].read = true
		end
		refreshNotificationList()
		updateBadge()
	end

	function NotificationController:ClearAll()
		hidePopup()
		for id in pairs(notifications) do
			removeNotificationFrame(id)
		end
		notifications = {}
		notificationOrder = {}
		notifByKey = {}
		updateBadge()
		updateEmptyState()
	end

	function NotificationController:ClearCategory(category)
		local toRemove = {}
		for id, notif in pairs(notifications) do
			if notif.category == category then
				table.insert(toRemove, id)
			end
		end
		for _, id in ipairs(toRemove) do
			NotificationController:RemoveNotification(id)
		end
	end

	function NotificationController:SetFilter(category)
		currentFilter = category
		refreshNotificationList()
	end

	function NotificationController:ShowPopup(id)
		onNotificationClicked(id)
	end

	function NotificationController:HidePopup()
		hidePopup()
	end

	function NotificationController:GetUnreadCount()
		return getUnreadCount()
	end

	function NotificationController:GetNotificationCount()
		return getNotificationCount()
	end

	function NotificationController:ShowToast(message, isSuccess)
		showToast(message, isSuccess)
	end

	-- ═══════════════════════════════════════════════════════════
	-- CONVENIENCE METHODS
	-- ═══════════════════════════════════════════════════════════

	function NotificationController:AddPartyInvite(inviterName, inviterUserId)
		return self:AddNotification("Social", "Party Invite", {
			message = inviterName .. " has invited you to join their party!",
			actionable = true,
			acceptText = "Join",
			declineText = "Decline",
			data = {
				inviterName = inviterName,
				inviterUserId = inviterUserId,
			},
			onAccept = function(data)
				Network:post("PartyInviteResponse", data.inviterName, true)
				showToast("Joining " .. data.inviterName .. "'s party...", true)
			end,
			onDecline = function(data)
				Network:post("PartyInviteResponse", data.inviterName, false)
				showToast("Declined party invite", false)
			end,
			expiresIn = 30,
		})
	end

	function NotificationController:AddCrewInvite(inviterName)
		return self:AddNotification("Social", "Crew Invite", {
			message = inviterName .. " has invited you to join their crew!",
			actionable = true,
			acceptText = "Join Crew",
			declineText = "Decline",
			data = {
				inviterName = inviterName,
			},
			onAccept = function(data)
				Network:post("CrewInviteResponse", data.inviterName, true)
				showToast("Joining " .. data.inviterName .. "'s crew...", true)
			end,
			onDecline = function(data)
				Network:post("CrewInviteResponse", data.inviterName, false)
				showToast("Declined crew invite", false)
			end,
			expiresIn = 60,
		})
	end

	function NotificationController:AddQuestUpdate(questName, message, isComplete, questId)
		local title = isComplete and "Quest Complete!" or "Quest Update"
		return self:AddNotification("Progress", title, {
			message = questName .. ": " .. message,
			actionable = false,
			key = questId and ("quest:" .. tostring(questId)) or nil,
		})
	end

	function NotificationController:AddLevelUp(newLevel)
		return self:AddNotification("Progress", "Level Up!", {
			message = "You've reached level " .. newLevel .. "!",
			actionable = false,
		})
	end

	function NotificationController:AddBountyIncrease(amount, newTotal)
		return self:AddNotification("Combat", "Bounty Increased!", {
			message = "+" .. amount .. " bounty! Total: " .. newTotal,
			actionable = false,
		})
	end

	function NotificationController:AddRegionDiscovered(regionName)
		return self:AddNotification("World", "Region Discovered", {
			message = "You've discovered " .. regionName .. "!",
			actionable = false,
		})
	end

	function NotificationController:AddServerEvent(eventName, message)
		return self:AddNotification("World", eventName, {
			message = message,
			actionable = false,
		})
	end

	local function softenStrokes(root)
		for _, descendant in ipairs(root:GetDescendants()) do
			if descendant:IsA("UIStroke") then
				if descendant.Thickness > 1 then
					descendant.Thickness = 1
				end
				descendant.Transparency = math.max(descendant.Transparency, 0.35)
			end
		end
	end

	local function findClearAllButton(root)
		for _, descendant in ipairs(root:GetDescendants()) do
			if descendant:IsA("GuiButton") then
				local lower = string.lower(descendant.Name)
				if lower:find("clear") then
					return descendant
				end
			end
		end
		return nil
	end

	local function ensureCloseButton()
		local existing = NotificationHolder:FindFirstChild("CloseBtn")
		if existing and existing:IsA("GuiButton") then
			return existing
		end

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "CloseBtn"
		closeBtn.AnchorPoint = Vector2.new(1, 0)
		closeBtn.Position = UDim2.new(1, -8, 0, 8)
		closeBtn.Size = UDim2.fromOffset(28, 28)
		closeBtn.BackgroundTransparency = 0.4
		closeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		closeBtn.AutoButtonColor = true
		closeBtn.Text = "X"
		closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		closeBtn.TextScaled = true
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.ZIndex = 10

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = closeBtn

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 4)
		padding.PaddingBottom = UDim.new(0, 4)
		padding.PaddingLeft = UDim.new(0, 4)
		padding.PaddingRight = UDim.new(0, 4)
		padding.Parent = closeBtn

		closeBtn.Parent = NotificationHolder
		return closeBtn
	end

	local function wireClickable(instance, handler)
		if instance:IsA("GuiButton") then
			table.insert(connections, instance.Activated:Connect(handler))
		else
			table.insert(connections, instance.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					handler()
				end
			end))
		end
	end

	local function wireClearContainer(container)
		if not container then return end

		for _, descendant in ipairs(container:GetDescendants()) do
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
				table.insert(clearTextLabels, descendant)
			end
		end
		if container:IsA("TextLabel") or container:IsA("TextButton") then
			table.insert(clearTextLabels, container)
		end
		updateClearLabel()

		wireClickable(container, function()
			playSound("click")
			NotificationController:ClearAll()
		end)
	end

	local function wireCategoryFilters(categoriesParent)
		if not categoriesParent then return end

		local function applyFilter(name)
			currentFilter = name
			refreshNotificationList()
		end

		for _, child in ipairs(categoriesParent:GetChildren()) do
			if child:IsA("GuiObject") then
				local lower = string.lower(child.Name)
				local matched = nil
				if lower:find("combat") then matched = "Combat"
				elseif lower:find("progress") or lower:find("quest") then matched = "Progress"
				elseif lower:find("social") then matched = "Social"
				elseif lower:find("world") then matched = "World"
				elseif lower:find("all") then matched = "All"
				end
				if matched then
					wireClickable(child, function()
						playSound("click")
						applyFilter(matched)
					end)
				end
			end
		end
	end

	function NotificationController:Init()
		popupHolder.Visible = false
		notiRed.Visible = false
		notiNum.Visible = false

		softenStrokes(NotificationHolder)
		softenStrokes(popupHolder)

		updateEmptyState()

		wireClearContainer(clearContainer)
		wireCategoryFilters(categoriesContainer)

		if popupCloseBtn then
			wireClickable(popupCloseBtn, function()
				playSound("click")
				hidePopup()
			end)
		end

		local closeBtn = ensureCloseButton()
		closeBtn.Visible = NotificationHolder.Visible
		table.insert(connections, closeBtn.Activated:Connect(function()
			playSound("click")
			NotificationHolder.Visible = false
			closeBtn.Visible = false
		end))
		table.insert(connections, NotificationHolder:GetPropertyChangedSignal("Visible"):Connect(function()
			closeBtn.Visible = NotificationHolder.Visible
		end))

		if notiBtn and (notiBtn:IsA("GuiButton")) then
			table.insert(connections, notiBtn.Activated:Connect(function()
				playSound("click")
				NotificationHolder.Visible = not NotificationHolder.Visible
				if NotificationHolder.Visible then
					NotificationController:MarkAllAsRead()
				end
			end))
		end

		table.insert(connections, acceptBtn.Activated:Connect(handleAccept))
		table.insert(connections, declineBtn.Activated:Connect(handleDecline))

		table.insert(connections, popupHolder.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local mousePos = input.Position
				local framePos = popUpFrame.AbsolutePosition
				local frameSize = popUpFrame.AbsoluteSize

				local isOutside = mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X
					or mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y

				if isOutside then
					playSound("click")
					hidePopup()
				end
			end
		end))

		updateBadge()

		print("[NotificationController] Initialized")
	end

	function NotificationController:Cleanup()
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		connections = {}

		for id, conns in pairs(frameConnections) do
			for _, conn in ipairs(conns) do
				conn:Disconnect()
			end
		end
		frameConnections = {}

		for _, frame in pairs(notificationFrames) do
			if frame and frame.Parent then
				frame:Destroy()
			end
		end
		notificationFrames = {}

		for _, sound in pairs(Sounds) do
			sound:Destroy()
		end
	end

	return NotificationController
end