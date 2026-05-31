return function(Client)
	local QuestClient = {}
	local player = Client.player
	local Network = Client.Network

	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local SoundService = game:GetService("SoundService")

	local activeQuests = {}
	local completedQuests = {}
	local trackedId = nil
	local selectedId = nil
	local refs = {}

	local completeSound = Instance.new("Sound")
	completeSound.Name = "QuestSFX_Complete"
	completeSound.SoundId = "rbxassetid://118754898939434"
	completeSound.Volume = 0.6
	completeSound.Parent = script

	local function getQuestInfo()
		if Client.QuestInfo then return Client.QuestInfo end
		local maybe = ReplicatedStorage:FindFirstChild("QuestInfo")
		if maybe then
			local ok, info = pcall(require, maybe)
			if ok then return info end
		end
		return {}
	end

	local function questDef(id)
		local info = getQuestInfo()
		return info and info[id]
	end

	local function notifyQuest(message, isComplete, questId)
		if Client.NotificationController and Client.NotificationController.AddQuestUpdate then
			Client.NotificationController:AddQuestUpdate("Quest", message, isComplete or false, questId)
		end
	end

	local function objectiveSummary(quest, progress)
		if not quest or not progress then return "" end
		local stage
		if quest.Stages then
			stage = quest.Stages[progress.Stage]
		else
			stage = { Objectives = quest.Objectives }
		end
		if not stage then return "" end
		local lines = {}
		for _, obj in ipairs(stage.Objectives) do
			local have = (progress.Objectives and progress.Objectives[obj.Id]) or 0
			local need = obj.Count or 1
			table.insert(lines, string.format("%s (%d/%d)", obj.Description or obj.Id, have, need))
		end
		return table.concat(lines, " | ")
	end

	local function rewardLine(reward)
		local t = reward.Type
		if t == "XP" then return string.format("+%d %s XP", reward.Amount or 0, reward.Track or "Combat") end
		if t == "Beli" then return string.format("+%d Beli", reward.Amount or 0) end
		if t == "Bounty" then return string.format("+%d Bounty", reward.Amount or 0) end
		if t == "Item" then return string.format("Item: %s x%d", tostring(reward.ItemId), reward.Amount or 1) end
		if t == "Skill" then return string.format("Skill: %s", tostring(reward.SkillId)) end
		if t == "Reputation" then return string.format("+%d %s rep", reward.Amount or 0, reward.Faction or "?") end
		if t == "Title" then return string.format("Title: %s", tostring(reward.Title)) end
		return "Custom reward"
	end

	local function setTrackerVisible(visible)
		local node = refs.tracker
		if not node then return end
		if node:IsA("ScreenGui") then
			node.Enabled = visible
		else
			node.Visible = visible
		end
	end

	local function bindTracker(playerGui)
		if refs.tracker and refs.tracker.Parent then return true end

		local root = playerGui:FindFirstChild("QuestTracker", true)
		if not root then
			warn("[QuestClient] QuestTracker not found under PlayerGui — skipping tracker")
			return false
		end

		local function find(...)
			for _, name in ipairs({ ... }) do
				local hit = root:FindFirstChild(name, true)
				if hit then return hit end
			end
			return nil
		end

		refs.tracker = root
		refs.trackerTitle = find("QuestTrackerTitle", "QuestNameLabel", "QuestTitle", "Title")
		refs.trackerObjectivesScroll = find("ObjectiveScroll", "ObjectivesScroll", "ObjectiveContainer")
		refs.trackerTimer = find("Timer", "TimerLabel")

		setTrackerVisible(false)
		return true
	end

	local function getKitTemplate(name)
		local kits = ReplicatedStorage:FindFirstChild("Kits")
		local ui = kits and kits:FindFirstChild("UI")
		return ui and ui:FindFirstChild(name) or nil
	end

	local function getRewardFrameTemplate(rewardType)
		local kits = ReplicatedStorage:FindFirstChild("Kits")
		local ui = kits and kits:FindFirstChild("UI")
		local folder = ui and ui:FindFirstChild("rewardsFolder")
		if not folder then return nil end

		local map = {
			XP = "expFrame",
			Beli = "beliFrame",
			Item = "itemFrame",
			Bounty = "bountyFrame",
			Reputation = "repFrame",
			Title = "titleFrame",
			Skill = "skillFrame",
		}
		local frameName = map[rewardType]
		return frameName and folder:FindFirstChild(frameName) or nil
	end

	local function ensureLog(playerGui)
		if refs.log and refs.log.Parent then return end

		local screen = Instance.new("ScreenGui")
		screen.Name = "QuestLog"
		screen.ResetOnSpawn = false
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.Enabled = false
		screen.Parent = playerGui

		local main = Instance.new("Frame")
		main.Name = "MainFrame"
		main.AnchorPoint = Vector2.new(0.5, 0.5)
		main.Position = UDim2.fromScale(0.5, 0.5)
		main.Size = UDim2.fromOffset(720, 480)
		main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		main.BorderSizePixel = 0
		main.Parent = screen
		Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
		local mStroke = Instance.new("UIStroke")
		mStroke.Color = Color3.fromRGB(70, 70, 80)
		mStroke.Thickness = 1
		mStroke.Parent = main

		local header = Instance.new("Frame")
		header.Name = "Header"
		header.Size = UDim2.new(1, 0, 0, 40)
		header.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
		header.BorderSizePixel = 0
		header.Parent = main

		local headerTitle = Instance.new("TextLabel")
		headerTitle.Size = UDim2.new(1, -200, 1, 0)
		headerTitle.Position = UDim2.new(0, 12, 0, 0)
		headerTitle.BackgroundTransparency = 1
		headerTitle.Font = Enum.Font.GothamBold
		headerTitle.TextSize = 18
		headerTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
		headerTitle.TextXAlignment = Enum.TextXAlignment.Left
		headerTitle.Text = "Quests"
		headerTitle.Parent = header

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "Close"
		closeBtn.AnchorPoint = Vector2.new(1, 0.5)
		closeBtn.Position = UDim2.new(1, -8, 0.5, 0)
		closeBtn.Size = UDim2.fromOffset(28, 28)
		closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
		closeBtn.Text = "X"
		closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.TextSize = 14
		closeBtn.BorderSizePixel = 0
		closeBtn.Parent = header
		Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

		local tabs = Instance.new("Frame")
		tabs.Name = "Tabs"
		tabs.Position = UDim2.new(0, 0, 0, 40)
		tabs.Size = UDim2.new(0, 240, 0, 30)
		tabs.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
		tabs.BorderSizePixel = 0
		tabs.Parent = main

		local function makeTab(name, x)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, 100, 1, -2)
			b.Position = UDim2.new(0, x, 0, 1)
			b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
			b.Text = name
			b.TextColor3 = Color3.fromRGB(220, 220, 220)
			b.Font = Enum.Font.GothamMedium
			b.TextSize = 13
			b.BorderSizePixel = 0
			b.Parent = tabs
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
			return b
		end

		local activeTab = makeTab("Active", 8)
		local completedTab = makeTab("Completed", 120)

		local list = Instance.new("ScrollingFrame")
		list.Name = "QuestList"
		list.Position = UDim2.new(0, 0, 0, 70)
		list.Size = UDim2.new(0, 240, 1, -70)
		list.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
		list.BorderSizePixel = 0
		list.ScrollBarThickness = 4
		list.CanvasSize = UDim2.fromScale(0, 0)
		list.AutomaticCanvasSize = Enum.AutomaticSize.Y
		list.Parent = main

		local listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 4)
		listLayout.Parent = list

		local listPadding = Instance.new("UIPadding")
		listPadding.PaddingLeft = UDim.new(0, 8)
		listPadding.PaddingRight = UDim.new(0, 8)
		listPadding.PaddingTop = UDim.new(0, 8)
		listPadding.Parent = list

		local details = Instance.new("Frame")
		details.Name = "Details"
		details.Position = UDim2.new(0, 240, 0, 40)
		details.Size = UDim2.new(1, -240, 1, -40)
		details.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		details.BorderSizePixel = 0
		details.Parent = main

		local dPadding = Instance.new("UIPadding")
		dPadding.PaddingTop = UDim.new(0, 16)
		dPadding.PaddingBottom = UDim.new(0, 16)
		dPadding.PaddingLeft = UDim.new(0, 16)
		dPadding.Parent = details
		local dTitle = Instance.new("TextLabel")
		dTitle.Name = "Title"
		dTitle.Size = UDim2.new(1, 0, 0, 26)
		dTitle.BackgroundTransparency = 1
		dTitle.Font = Enum.Font.GothamBold
		dTitle.TextSize = 18
		dTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
		dTitle.TextXAlignment = Enum.TextXAlignment.Left
		dTitle.Text = "Select a quest"
		dTitle.Parent = details

		local dCategory = Instance.new("TextLabel")
		dCategory.Name = "Category"
		dCategory.Position = UDim2.new(0, 0, 0, 28)
		dCategory.Size = UDim2.new(1, 0, 0, 16)
		dCategory.BackgroundTransparency = 1
		dCategory.Font = Enum.Font.Gotham
		dCategory.TextSize = 11
		dCategory.TextColor3 = Color3.fromRGB(160, 160, 170)
		dCategory.TextXAlignment = Enum.TextXAlignment.Left
		dCategory.Text = ""
		dCategory.Parent = details

		local dDesc = Instance.new("TextLabel")
		dDesc.Name = "Description"
		dDesc.Position = UDim2.new(0, 0, 0, 50)
		dDesc.Size = UDim2.new(1, 0, 0, 60)
		dDesc.BackgroundTransparency = 1
		dDesc.Font = Enum.Font.Gotham
		dDesc.TextSize = 13
		dDesc.TextColor3 = Color3.fromRGB(220, 220, 220)
		dDesc.TextXAlignment = Enum.TextXAlignment.Left
		dDesc.TextYAlignment = Enum.TextYAlignment.Top
		dDesc.TextWrapped = true
		dDesc.Text = ""
		dDesc.Parent = details

		local dObjHeader = Instance.new("TextLabel")
		dObjHeader.Position = UDim2.new(0, 0, 0, 116)
		dObjHeader.Size = UDim2.new(1, 0, 0, 18)
		dObjHeader.BackgroundTransparency = 1
		dObjHeader.Font = Enum.Font.GothamBold
		dObjHeader.TextSize = 13
		dObjHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
		dObjHeader.TextXAlignment = Enum.TextXAlignment.Left
		dObjHeader.Text = "Objectives"
		dObjHeader.Parent = details

		local dObjBody = Instance.new("TextLabel")
		dObjBody.Name = "Objectives"
		dObjBody.Position = UDim2.new(0, 0, 0, 136)
		dObjBody.Size = UDim2.new(1, 0, 0, 100)
		dObjBody.BackgroundTransparency = 1
		dObjBody.Font = Enum.Font.Gotham
		dObjBody.TextSize = 12
		dObjBody.TextColor3 = Color3.fromRGB(220, 220, 220)
		dObjBody.TextXAlignment = Enum.TextXAlignment.Left
		dObjBody.TextYAlignment = Enum.TextYAlignment.Top
		dObjBody.TextWrapped = true
		dObjBody.Text = ""
		dObjBody.Parent = details

		local dRewHeader = Instance.new("TextLabel")
		dRewHeader.Position = UDim2.new(0, 0, 0, 240)
		dRewHeader.Size = UDim2.new(1, 0, 0, 18)
		dRewHeader.BackgroundTransparency = 1
		dRewHeader.Font = Enum.Font.GothamBold
		dRewHeader.TextSize = 13
		dRewHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
		dRewHeader.TextXAlignment = Enum.TextXAlignment.Left
		dRewHeader.Text = "Rewards"
		dRewHeader.Parent = details

		local dRewBody = Instance.new("TextLabel")
		dRewBody.Name = "Rewards"
		dRewBody.Position = UDim2.new(0, 0, 0, 260)
		dRewBody.Size = UDim2.new(1, 0, 0, 90)
		dRewBody.BackgroundTransparency = 1
		dRewBody.Font = Enum.Font.Gotham
		dRewBody.TextSize = 12
		dRewBody.TextColor3 = Color3.fromRGB(220, 220, 220)
		dRewBody.TextXAlignment = Enum.TextXAlignment.Left
		dRewBody.TextYAlignment = Enum.TextYAlignment.Top
		dRewBody.TextWrapped = true
		dRewBody.Text = ""
		dRewBody.Parent = details

		local function makeActionButton(name, x, color)
			local b = Instance.new("TextButton")
			b.Name = name
			b.AnchorPoint = Vector2.new(0, 1)
			b.Position = UDim2.new(0, x, 1, 0)
			b.Size = UDim2.fromOffset(120, 32)
			b.BackgroundColor3 = color
			b.Text = name
			b.TextColor3 = Color3.fromRGB(255, 255, 255)
			b.Font = Enum.Font.GothamBold
			b.TextSize = 13
			b.BorderSizePixel = 0
			b.Parent = details
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
			return b
		end

		local trackBtn = makeActionButton("Track", 0, Color3.fromRGB(80, 130, 200))
		local abandonBtn = makeActionButton("Abandon", 130, Color3.fromRGB(180, 70, 70))

		refs.log = screen
		refs.main = main
		refs.activeTab = activeTab
		refs.completedTab = completedTab
		refs.list = list
		refs.dTitle = dTitle
		refs.dCategory = dCategory
		refs.dDesc = dDesc
		refs.dObjBody = dObjBody
		refs.dRewBody = dRewBody
		refs.trackBtn = trackBtn
		refs.abandonBtn = abandonBtn
		refs.closeBtn = closeBtn
		refs.currentTab = "Active"

		closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)
		activeTab.MouseButton1Click:Connect(function()
			refs.currentTab = "Active"
			QuestClient:Refresh()
		end)
		completedTab.MouseButton1Click:Connect(function()
			refs.currentTab = "Completed"
			QuestClient:Refresh()
		end)
		trackBtn.MouseButton1Click:Connect(function()
			if selectedId then QuestClient:SetTracked(selectedId) end
		end)
		abandonBtn.MouseButton1Click:Connect(function()
			if selectedId and Network and Network.get then
				task.spawn(function() Network:get("Quest_Abandon", selectedId) end)
			end
		end)
	end

	local function saveTracked()
		if not (Network and Network.get) then return end
		task.spawn(function()
			pcall(function()
				Network:get("Quest_SetTracked", trackedId or false)
			end)
		end)
	end

	function QuestClient:SetTracked(questId)
		if trackedId == questId then trackedId = false else trackedId = questId end
		saveTracked()
		QuestClient:RefreshTracker()
		if selectedId then QuestClient:RenderDetails(selectedId) end
	end

	local function timeRemainingText(progress)
		if not progress or not progress.ExpiresAt then return nil end
		local remaining = progress.ExpiresAt - os.time()
		if remaining <= 0 then return "Expired" end
		local m = math.floor(remaining / 60)
		local s = remaining % 60
		if m > 0 then return string.format("Time left: %dm %ds", m, s) end
		return string.format("Time left: %ds", s)
	end

	local CLONE_TAG = "QuestTrackerClone"

	local function clearClones(container)
		if not container then return end
		for _, child in ipairs(container:GetChildren()) do
			if child:GetAttribute(CLONE_TAG) then
				child:Destroy()
			end
		end
	end

	local DONE_COLOR = "rgb(140,140,150)"
	local ACTIVE_COLOR = "rgb(255,255,255)"
	local PENDING_COLOR = "rgb(190,190,200)"

	local function spawnLine(container, template, text, order)
		if not container or not template then return end
		local clone = template:Clone()
		clone:SetAttribute(CLONE_TAG, true)
		clone.LayoutOrder = order
		clone.Visible = true
		clone.RichText = true
		clone.Text = tostring(text or "")
		clone.Parent = container
	end

	local function fillObjectives(quest, progress)
		local container = refs.trackerObjectivesScroll
		if not container then return end
		local template = getKitTemplate("ObjectiveText")
		if not template then return end

		clearClones(container)

		local stages = quest.Stages or { { Objectives = quest.Objectives } }
		local currentStage = progress.Stage or 1
		local readyToTurnIn = currentStage > #stages
		local order = 0

		local function add(text)
			order += 1
			spawnLine(container, template, text, order)
		end

		for stageIdx, stage in ipairs(stages) do
			local stageDone = stageIdx < currentStage or readyToTurnIn
			local stageActive = stageIdx == currentStage and not readyToTurnIn
			local stageTitle = string.upper(stage.Title or ("Stage " .. stageIdx))

			if stageDone then
				add(string.format('%s <font color="%s"><i><b>"%s"</b></i></font>', DONE_PREFIX, DONE_COLOR, stageTitle))
			elseif stageActive then
				add(string.format('%s <font color="%s"><i><b>"%s"</b></i></font>', ACTIVE_PREFIX, ACTIVE_COLOR, stageTitle))
			else
				add(string.format('%s <font color="%s"><i><b>"%s"</b></i></font>', PENDING_PREFIX, PENDING_COLOR, stageTitle))
			end

			if stage.Objectives then
				for _, obj in ipairs(stage.Objectives) do
					local need = obj.Count or 1
					local have
					if stageDone then
						have = need
					elseif stageActive then
						have = (progress.Objectives and progress.Objectives[obj.Id]) or 0
					else
						have = 0
					end
					local desc = string.upper(obj.Description or obj.Id or "?")
					if stageDone or have >= need then
						add(string.format('    %s <font color="%s">%s (%d/%d)</font>', DONE_PREFIX, DONE_COLOR, desc, have, need))
					elseif stageActive then
						add(string.format('    %s <font color="%s"><b>%s (%d/%d)</b></font>', ACTIVE_PREFIX, ACTIVE_COLOR, desc, have, need))
					else
						add(string.format('    %s <font color="%s">%s</font>', PENDING_PREFIX, PENDING_COLOR, desc))
					end
				end
			end
		end

		if readyToTurnIn and quest.TurnInTo then
			add(string.format('%s <font color="%s"><b>%s</b></font>', ACTIVE_PREFIX, ACTIVE_COLOR, string.upper("Turn in to " .. quest.TurnInTo)))
		end
	end

	function QuestClient:RefreshTracker()
		if not refs.tracker then return end

		local hasAny = false
		for _ in pairs(activeQuests) do hasAny = true break end
		if not hasAny then
			trackedId = nil
			setTrackerVisible(false)
			if refs.trackerTitle then refs.trackerTitle.Text = "" end
			clearClones(refs.trackerObjectivesScroll)
			if refs.trackerTimer then refs.trackerTimer.Visible = false end
			return
		end

		if trackedId == false then
			setTrackerVisible(false)
			return
		end

		if trackedId and not activeQuests[trackedId] then
			trackedId = nil
		end

		local id = trackedId
		if not id then
			for k in pairs(activeQuests) do id = k break end
		end
		if not id or not activeQuests[id] then
			setTrackerVisible(false)
			return
		end

		local quest = questDef(id)
		if not quest then setTrackerVisible(false) return end

		local progress = activeQuests[id]
		setTrackerVisible(true)

		if refs.trackerTitle then
			refs.trackerTitle.Text = string.upper(quest.Name or id)
		end

		fillObjectives(quest, progress)

		local timeStr = timeRemainingText(progress)
		if refs.trackerTimer then
			if timeStr then
				refs.trackerTimer.Text = string.upper(timeStr)
				refs.trackerTimer.Visible = true
			else
				refs.trackerTimer.Visible = false
			end
		end
	end

	function QuestClient:Refresh()
		if not refs.list then return end
		for _, child in ipairs(refs.list:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		local function tabColor(active)
			return active and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(30, 30, 38)
		end
		refs.activeTab.BackgroundColor3 = tabColor(refs.currentTab == "Active")
		refs.completedTab.BackgroundColor3 = tabColor(refs.currentTab == "Completed")

		local entries = {}
		if refs.currentTab == "Active" then
			for id, _ in pairs(activeQuests) do table.insert(entries, id) end
		else
			for _, id in ipairs(completedQuests) do table.insert(entries, id) end
		end

		for i, id in ipairs(entries) do
			local quest = questDef(id)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, -16, 0, 36)
			b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
			b.Text = (quest and quest.Name) or id
			b.TextColor3 = Color3.fromRGB(230, 230, 230)
			b.Font = Enum.Font.GothamMedium
			b.TextSize = 13
			b.LayoutOrder = i
			b.BorderSizePixel = 0
			b.Parent = refs.list
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
			b.MouseButton1Click:Connect(function()
				selectedId = id
				QuestClient:RenderDetails(id)
			end)
		end

		if selectedId then
			QuestClient:RenderDetails(selectedId)
		else
			refs.dTitle.Text = "Select a quest"
			refs.dCategory.Text = ""
			refs.dDesc.Text = ""
			refs.dObjBody.Text = ""
			refs.dRewBody.Text = ""
			refs.abandonBtn.Visible = false
			refs.trackBtn.Visible = false
		end
	end

	function QuestClient:RenderDetails(id)
		local quest = questDef(id)
		if not quest then
			refs.dTitle.Text = id
			refs.dCategory.Text = ""
			refs.dDesc.Text = ""
			refs.dObjBody.Text = ""
			refs.dRewBody.Text = ""
			return
		end
		refs.dTitle.Text = quest.Name or id
		refs.dCategory.Text = (quest.Category or "Quest") .. (quest.Repeatable and " — Repeatable" or "")
		refs.dDesc.Text = quest.Description or ""

		local progress = activeQuests[id]
		if progress then
			refs.dObjBody.Text = objectiveSummary(quest, progress)
		else
			local lines = {}
			local stages = quest.Stages or { { Objectives = quest.Objectives } }
			for _, stage in ipairs(stages) do
				if stage.Title then table.insert(lines, "• " .. stage.Title) end
				if stage.Objectives then
					for _, obj in ipairs(stage.Objectives) do
						table.insert(lines, "    - " .. (obj.Description or obj.Id))
					end
				end
			end
			refs.dObjBody.Text = table.concat(lines, "\n")
		end

		local rewardLines = {}
		for _, reward in ipairs(quest.Rewards or {}) do
			table.insert(rewardLines, "• " .. rewardLine(reward))
		end
		refs.dRewBody.Text = table.concat(rewardLines, "\n")

		local isActive = activeQuests[id] ~= nil
		refs.abandonBtn.Visible = isActive
		refs.trackBtn.Visible = isActive
		refs.trackBtn.Text = (trackedId == id) and "Untrack" or "Track"
	end

	function QuestClient:HandleUpdate(payload)
		if not payload or type(payload) ~= "table" then return end
		local kind = payload.Kind

		if kind == "Sync" then
			activeQuests = payload.Active or {}
			completedQuests = payload.Completed or {}
			if payload.Tracked ~= nil and activeQuests[payload.Tracked] then
				trackedId = payload.Tracked
			end
			if selectedId and not activeQuests[selectedId] and not table.find(completedQuests, selectedId) then
				selectedId = nil
			end
			if trackedId and not activeQuests[trackedId] then
				trackedId = nil
			end
		elseif kind == "Accepted" then
			activeQuests[payload.QuestId] = payload.Progress
			local quest = questDef(payload.QuestId)
			notifyQuest("New quest: " .. ((quest and quest.Name) or payload.QuestId), false, payload.QuestId)
			if not trackedId or not activeQuests[trackedId] then trackedId = payload.QuestId end
		elseif kind == "Progress" then
			activeQuests[payload.QuestId] = payload.Progress
			local quest = questDef(payload.QuestId)
			if payload.Complete then
				notifyQuest((quest and quest.Name or payload.QuestId) .. " — ready to turn in", false, payload.QuestId)
			else
				notifyQuest((quest and quest.Name or payload.QuestId) .. ": " .. objectiveSummary(quest, payload.Progress), false, payload.QuestId)
			end
		elseif kind == "Completed" then
			activeQuests[payload.QuestId] = nil
			local quest = questDef(payload.QuestId)
			if not table.find(completedQuests, payload.QuestId) then
				table.insert(completedQuests, payload.QuestId)
			end
			notifyQuest("Completed: " .. ((quest and quest.Name) or payload.QuestId), true, payload.QuestId)
			if Client.QuestCompleteController and Client.QuestCompleteController.Show then
				Client.QuestCompleteController:Show(
					(quest and quest.Name) or payload.QuestId,
					quest and quest.Caption or ""
				)
			else
				completeSound:Stop()
				completeSound:Play()
			end
			if trackedId == payload.QuestId then trackedId = nil end
			if selectedId == payload.QuestId then selectedId = nil end
		elseif kind == "Abandoned" then
			activeQuests[payload.QuestId] = nil
			local quest = questDef(payload.QuestId)
			notifyQuest("Abandoned: " .. ((quest and quest.Name) or payload.QuestId), false, payload.QuestId)
			if trackedId == payload.QuestId then trackedId = nil end
			if selectedId == payload.QuestId then selectedId = nil end
		elseif kind == "Failed" then
			activeQuests[payload.QuestId] = nil
			local quest = questDef(payload.QuestId)
			local reason = payload.Reason == "time" and "ran out of time" or (payload.Reason or "failed")
			notifyQuest("Failed: " .. ((quest and quest.Name) or payload.QuestId) .. " (" .. reason .. ")", true, payload.QuestId)
			if trackedId == payload.QuestId then trackedId = nil end
			if selectedId == payload.QuestId then selectedId = nil end
		end

		QuestClient:Refresh()
		QuestClient:RefreshTracker()
	end

	function QuestClient:Toggle()
		if refs.log then
			refs.log.Enabled = not refs.log.Enabled
			if refs.log.Enabled then QuestClient:Refresh() end
		end
	end

	function QuestClient:GetActive() return activeQuests end
	function QuestClient:GetCompleted() return completedQuests end

	function QuestClient:Init()
		local playerGui = player:WaitForChild("PlayerGui", 30)
		if not playerGui then return end

		ensureLog(playerGui)
		bindTracker(playerGui)

		if Client.QuestCompleteController and Client.QuestCompleteController.SetSound then
			Client.QuestCompleteController:SetSound(completeSound)
		end

		if Network and Network.bindEvent then
			Network:bindEvent("QuestUpdate", function(payload)
				QuestClient:HandleUpdate(payload)
			end)
		end

		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.J then
				QuestClient:Toggle()
			end
		end)

		task.spawn(function()
			task.wait(2)
			if Network and Network.get then
				local activeOk, active = pcall(function() return Network:get("Quest_GetActive") end)
				if activeOk and active then activeQuests = active end
				local completedOk, completed = pcall(function() return Network:get("Quest_GetCompleted") end)
				if completedOk and completed then completedQuests = completed end
				local trackedOk, tracked = pcall(function() return Network:get("Quest_GetTracked") end)
				if trackedOk and tracked and activeQuests[tracked] then
					trackedId = tracked
				end
				QuestClient:Refresh()
				QuestClient:RefreshTracker()
			end
		end)

		task.spawn(function()
			while true do
				task.wait(1)
				QuestClient:RefreshTracker()
			end
		end)
	end

	return QuestClient
end
