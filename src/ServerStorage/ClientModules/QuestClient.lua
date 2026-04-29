return function(Client)
	local QuestClient = {}
	local player = Client.player
	local Network = Client.Network

	local activeQuests = {}
	local completedQuests = {}

	local function getQuestInfo()
		if Client.QuestInfo then return Client.QuestInfo end
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

	local function notifyQuest(message, isComplete)
		if Client.NotificationController and Client.NotificationController.AddQuestUpdate then
			Client.NotificationController:AddQuestUpdate("Quest", message, isComplete or false)
		else
			print("[QuestClient]", message)
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

	function QuestClient:HandleUpdate(payload)
		if not payload or type(payload) ~= "table" then return end
		local kind = payload.Kind

		if kind == "Sync" then
			activeQuests = payload.Active or {}
			completedQuests = payload.Completed or {}
		elseif kind == "Accepted" then
			activeQuests[payload.QuestId] = payload.Progress
			local quest = questDef(payload.QuestId)
			notifyQuest("New quest: " .. ((quest and quest.Name) or payload.QuestId))
		elseif kind == "Progress" then
			activeQuests[payload.QuestId] = payload.Progress
			local quest = questDef(payload.QuestId)
			if payload.Complete then
				notifyQuest((quest and quest.Name or payload.QuestId) .. " — ready to turn in", true)
			else
				notifyQuest((quest and quest.Name or payload.QuestId) .. ": " .. objectiveSummary(quest, payload.Progress))
			end
		elseif kind == "Completed" then
			activeQuests[payload.QuestId] = nil
			local quest = questDef(payload.QuestId)
			if quest and not quest.Repeatable then
				table.insert(completedQuests, payload.QuestId)
			end
			notifyQuest("Completed: " .. ((quest and quest.Name) or payload.QuestId), true)
		elseif kind == "Abandoned" then
			activeQuests[payload.QuestId] = nil
			local quest = questDef(payload.QuestId)
			notifyQuest("Abandoned: " .. ((quest and quest.Name) or payload.QuestId))
		elseif kind == "RewardGranted" then
			-- visual reward popup hook (UI to be added)
		end
	end

	function QuestClient:GetActive() return activeQuests end
	function QuestClient:GetCompleted() return completedQuests end

	function QuestClient:Init()
		if Network and Network.bindEvent then
			Network:bindEvent("QuestUpdate", function(payload)
				QuestClient:HandleUpdate(payload)
			end)
		end

		task.spawn(function()
			task.wait(2)
			if Network and Network.get then
				local activeOk, active = pcall(function() return Network:get("Quest_GetActive") end)
				if activeOk and active then activeQuests = active end
				local completedOk, completed = pcall(function() return Network:get("Quest_GetCompleted") end)
				if completedOk and completed then completedQuests = completed end
			end
		end)

		print("[QuestClient] Initialized")
	end

	return QuestClient
end
