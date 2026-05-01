local Server = require(script.Parent)
local Network = Server.Network

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestService = {}

local function questDef(questId)
	return Server.QuestInfo and Server.QuestInfo[questId]
end

local function getEntity(player)
	return Server.EntityService and Server.EntityService.Find and Server.EntityService.Find(player)
end

local function getProfile(player)
	local entity = getEntity(player)
	return entity and entity.SlotProfile
end

local function getStageData(quest, stageIndex)
	if quest.Stages then
		return quest.Stages[stageIndex]
	end
	if quest.Objectives and stageIndex == 1 then
		return { Objectives = quest.Objectives, Title = quest.Name }
	end
	return nil
end

local function totalStages(quest)
	if quest.Stages then return #quest.Stages end
	return 1
end

local function makeProgressTable(quest)
	local progress = { Stage = 1, Objectives = {} }
	local stage = getStageData(quest, 1)
	if stage then
		for _, obj in ipairs(stage.Objectives) do
			progress.Objectives[obj.Id] = 0
		end
	end
	if quest.TimeLimit and quest.TimeLimit > 0 then
		progress.ExpiresAt = os.time() + quest.TimeLimit
	end
	return progress
end

local function isProgressTable(value)
	return type(value) == "table" and type(value.Stage) == "number"
end

local function migrateLegacyProgress(quest, value)
	local progress = makeProgressTable(quest)
	local stage = getStageData(quest, 1)
	if stage and stage.Objectives[1] then
		local firstId = stage.Objectives[1].Id
		if type(value) == "number" then
			progress.Objectives[firstId] = value
		elseif value == true then
			progress.Objectives[firstId] = (stage.Objectives[1].Count or 1)
		end
	end
	return progress
end

local function ensureProgressTable(profile, questId)
	local quest = questDef(questId)
	if not quest then return nil end
	local current = profile.currentQuests[questId]
	if not isProgressTable(current) then
		profile.currentQuests[questId] = migrateLegacyProgress(quest, current)
	end
	return profile.currentQuests[questId]
end

local function broadcast(player, payload)
	if Network and Network.post then
		Network:post("QuestUpdate", player, payload)
	end
end

local function getCrewMembers(player)
	if Server.CrewService and Server.CrewService.GetCrewMembers then
		return Server.CrewService:GetCrewMembers(player) or { player }
	end
	return { player }
end

local function getPartyMembers(player)
	if Server.PartyService and Server.PartyService.GetPartyMembers then
		return Server.PartyService:GetPartyMembers(player) or { player }
	end
	return { player }
end

local function resolveScope(player, quest)
	if quest.ProgressScope == "CrewShared" then
		return getCrewMembers(player)
	elseif quest.ProgressScope == "PartyShared" then
		return getPartyMembers(player)
	end
	return { player }
end

local function checkPrereqs(player, quest)
	local profile = getProfile(player)
	if not profile then return false, "no profile" end
	local prereqs = quest.Prerequisites or {}

	if prereqs.MinLevel and (profile.UserData.Level or 1) < prereqs.MinLevel then
		return false, "level too low"
	end
	if prereqs.MinBounty and (profile.UserData.Bounty or 0) < prereqs.MinBounty then
		return false, "bounty too low"
	end
	if prereqs.Faction and profile.UserData.Faction ~= prereqs.Faction then
		return false, "wrong faction"
	end
	if prereqs.RequiresCrew and (profile.UserData.Crew == nil or profile.UserData.Crew == "None") then
		return false, "no crew"
	end
	if prereqs.MinCrewSize then
		local members = getCrewMembers(player)
		if #members < prereqs.MinCrewSize then return false, "crew too small" end
	end
	if prereqs.CompletedQuests then
		for _, q in ipairs(prereqs.CompletedQuests) do
			if not table.find(profile.questsCompleted, q) then
				return false, "missing prerequisite quest: " .. q
			end
		end
	end
	if prereqs.Custom and type(prereqs.Custom) == "function" then
		local ok, reason = prereqs.Custom(player, profile)
		if not ok then return false, reason or "custom prereq failed" end
	end
	return true
end

local function isStageComplete(quest, stageIndex, progress)
	local stage = getStageData(quest, stageIndex)
	if not stage then return false end
	for _, obj in ipairs(stage.Objectives) do
		local needed = obj.Count or 1
		local have = progress.Objectives[obj.Id] or 0
		if have < needed then return false end
	end
	return true
end

local function advanceStageIfReady(player, profile, questId)
	local quest = questDef(questId)
	if not quest then return false end
	local progress = profile.currentQuests[questId]
	if not isProgressTable(progress) then return false end

	local stages = totalStages(quest)
	local advanced = false
	while progress.Stage <= stages and isStageComplete(quest, progress.Stage, progress) do
		progress.Stage += 1
		advanced = true
		if progress.Stage > stages then break end
		progress.Objectives = {}
		local newStage = getStageData(quest, progress.Stage)
		if newStage then
			for _, obj in ipairs(newStage.Objectives) do
				progress.Objectives[obj.Id] = 0
			end
		end
	end
	return advanced
end

local function isFullyComplete(quest, progress)
	if not isProgressTable(progress) then return false end
	return progress.Stage > totalStages(quest)
end

local function grantReward(player, profile, reward)
	local rType = reward.Type
	if rType == "XP" then
		local sm = Server.EntityService and Server.EntityService.Find and Server.EntityService.Find(player)
		sm = sm and sm.StatManager
		if sm and sm.AddEXP then
			sm:AddEXP(reward.Amount or 0, reward.Track)
		else
			profile.statInfo.StatPoints = (profile.statInfo.StatPoints or 0) + 0
			local track = profile.XPInfo and profile.XPInfo[reward.Track or "Combat"]
			if track then track.Exp = (track.Exp or 0) + (reward.Amount or 0) end
		end
	elseif rType == "Beli" then
		local oldBeli = profile.UserData.Beli or 0
		local amount = reward.Amount or 0
		profile.UserData.Beli = oldBeli + amount
		player:SetAttribute("Beli", profile.UserData.Beli)
		if player:FindFirstChild("StatFolder") then
			local userFolder = player.StatFolder:FindFirstChild("UserFolder")
			if userFolder then
				userFolder:SetAttribute("Beli", profile.UserData.Beli)
			end
		end
		if Network and Network.post then
			Network:post("BeliUpdate", player, oldBeli, profile.UserData.Beli, -amount)
		end
	elseif rType == "Bounty" then
		local oldBounty = profile.UserData.Bounty or 0
		profile.UserData.Bounty = oldBounty + (reward.Amount or 0)
		player:SetAttribute("Bounty", profile.UserData.Bounty)
		if player:FindFirstChild("StatFolder") then
			local userFolder = player.StatFolder:FindFirstChild("UserFolder")
			if userFolder then
				userFolder:SetAttribute("Bounty", profile.UserData.Bounty)
			end
		end
	elseif rType == "Item" then
		local entity = getEntity(player)
		local im = entity and entity.InventoryManager
		if im and im.AddItem then
			im:AddItem(reward.ItemId, { Amount = reward.Amount or 1 })
		end
	elseif rType == "Skill" then
		profile.SkillInventory = profile.SkillInventory or {}
		profile.SkillInventory[reward.SkillId] = true
	elseif rType == "Reputation" then
		if Server.FactionService and Server.FactionService.AddReputation then
			Server.FactionService:AddReputation(player, reward.Faction or profile.UserData.Faction, reward.Amount or 0)
		else
			profile.UserData.FactionRep = profile.UserData.FactionRep or {}
			local key = reward.Faction or profile.UserData.Faction
			profile.UserData.FactionRep[key] = (profile.UserData.FactionRep[key] or 0) + (reward.Amount or 0)
		end
	elseif rType == "Title" then
		profile.UserData.Title = reward.Title
		player:SetAttribute("Title", reward.Title)
	elseif rType == "Custom" and type(reward.Apply) == "function" then
		pcall(reward.Apply, player, profile)
	end
end

local function distributeRewards(player, quest)
	local recipients
	if quest.RewardDistribution == "SplitParty" then
		recipients = getPartyMembers(player)
	elseif quest.RewardDistribution == "CrewVault" then
		recipients = { player }
	else
		recipients = { player }
	end

	for _, p in ipairs(recipients) do
		local prof = getProfile(p)
		if prof then
			for _, reward in ipairs(quest.Rewards or {}) do
				local copy = reward
				if quest.RewardDistribution == "SplitParty" and reward.Amount and #recipients > 1 then
					copy = table.clone(reward)
					copy.Amount = math.floor(reward.Amount / #recipients)
				end
				grantReward(p, prof, copy)
			end
			broadcast(p, { Kind = "RewardGranted", QuestId = quest.Id, Rewards = quest.Rewards })
		end
	end
end

function QuestService:CanAccept(player, questId)
	local quest = questDef(questId)
	if not quest then return false, "unknown quest" end
	local profile = getProfile(player)
	if not profile then return false, "no profile" end

	if profile.currentQuests[questId] ~= nil then return false, "already active" end

	if table.find(profile.questsCompleted, questId) and not quest.Repeatable then
		return false, "already completed"
	end

	return checkPrereqs(player, quest)
end

function QuestService:AcceptQuest(player, questId)
	local quest = questDef(questId)
	if not quest then return false, "unknown quest" end
	local profile = getProfile(player)
	if not profile then return false, "no profile" end

	local ok, reason = self:CanAccept(player, questId)
	if not ok then return false, reason end

	profile.currentQuests[questId] = makeProgressTable(quest)
	broadcast(player, { Kind = "Accepted", QuestId = questId, Progress = profile.currentQuests[questId] })
	return true, "accepted"
end

function QuestService:AbandonQuest(player, questId)
	local profile = getProfile(player)
	if not profile or profile.currentQuests[questId] == nil then return false, "not active" end
	profile.currentQuests[questId] = nil
	broadcast(player, { Kind = "Abandoned", QuestId = questId })
	QuestService:SyncToClient(player)
	return true, "abandoned"
end

function QuestService:CompleteQuest(player, questId)
	local quest = questDef(questId)
	if not quest then return false, "unknown quest" end
	local profile = getProfile(player)
	if not profile then return false, "no profile" end

	local progress = profile.currentQuests[questId]
	if not isProgressTable(progress) then return false, "not active" end
	if not isFullyComplete(quest, progress) then return false, "not all objectives complete" end

	profile.currentQuests[questId] = nil
	if not quest.Repeatable then
		if not table.find(profile.questsCompleted, questId) then
			table.insert(profile.questsCompleted, questId)
		end
	end

	distributeRewards(player, quest)
	broadcast(player, { Kind = "Completed", QuestId = questId })
	QuestService:SyncToClient(player)
	return true, "completed"
end

function QuestService:FailQuest(player, questId, reason)
	local profile = getProfile(player)
	if not profile or profile.currentQuests[questId] == nil then return false end
	profile.currentQuests[questId] = nil
	broadcast(player, { Kind = "Failed", QuestId = questId, Reason = reason or "failed" })
	QuestService:SyncToClient(player)
	return true
end

local function checkExpiration(player, profile, questId, progress)
	if not progress or type(progress) ~= "table" or not progress.ExpiresAt then return false end
	if os.time() < progress.ExpiresAt then return false end
	profile.currentQuests[questId] = nil
	broadcast(player, { Kind = "Failed", QuestId = questId, Reason = "time" })
	return true
end

function QuestService:RegisterEvent(player, eventType, target, amount)
	amount = amount or 1
	local profile = getProfile(player)
	if not profile then return end

	local eventTypeLower = string.lower(tostring(eventType or ""))
	local targetLower = string.lower(tostring(target or ""))

	local affectedScopes = {}

	for questId, progress in pairs(profile.currentQuests) do
		if checkExpiration(player, profile, questId, progress) then continue end
		local quest = questDef(questId)
		if quest and isProgressTable(progress) then
			local stage = getStageData(quest, progress.Stage)
			if stage then
				for _, obj in ipairs(stage.Objectives) do
					if string.lower(tostring(obj.Type or "")) == eventTypeLower
						and string.lower(tostring(obj.Target or "")) == targetLower then
						local needed = obj.Count or 1
						local have = progress.Objectives[obj.Id] or 0
						if have < needed then
							progress.Objectives[obj.Id] = math.min(have + amount, needed)
							affectedScopes[questId] = quest
						end
					end
				end
			end
		end
	end

	for questId, quest in pairs(affectedScopes) do
		advanceStageIfReady(player, profile, questId)
		local progress = profile.currentQuests[questId]
		broadcast(player, {
			Kind = "Progress",
			QuestId = questId,
			Progress = progress,
			Complete = isFullyComplete(quest, progress),
		})

		if quest.ProgressScope == "CrewShared" or quest.ProgressScope == "PartyShared" then
			local members = resolveScope(player, quest)
			for _, member in ipairs(members) do
				if member ~= player then
					local memberProfile = getProfile(member)
					if memberProfile and memberProfile.currentQuests[questId] then
						memberProfile.currentQuests[questId] = progress
						broadcast(member, {
							Kind = "Progress",
							QuestId = questId,
							Progress = progress,
							Complete = isFullyComplete(quest, progress),
						})
					end
				end
			end
		end
	end
end

function QuestService:ResetQuests(player)
	local profile = getProfile(player)
	if not profile then return false, "no profile" end

	for questId in pairs(profile.currentQuests) do
		broadcast(player, { Kind = "Abandoned", QuestId = questId })
	end

	profile.currentQuests = {}
	profile.questsCompleted = {}

	QuestService:SyncToClient(player)
	return true, "reset"
end

function QuestService:GetActiveQuests(player)
	local profile = getProfile(player)
	if not profile then return {} end
	local result = {}
	for questId, progress in pairs(profile.currentQuests) do
		ensureProgressTable(profile, questId)
		result[questId] = profile.currentQuests[questId]
	end
	return result
end

function QuestService:GetCompletedQuests(player)
	local profile = getProfile(player)
	return profile and profile.questsCompleted or {}
end

function QuestService:SyncToClient(player)
	broadcast(player, {
		Kind = "Sync",
		Active = self:GetActiveQuests(player),
		Completed = self:GetCompletedQuests(player),
	})
end

if Network and Network.bindFunction then
	Network:bindFunction("Quest_CanAccept", function(player, questId)
		return QuestService:CanAccept(player, questId)
	end)
	Network:bindFunction("Quest_Accept", function(player, questId)
		return QuestService:AcceptQuest(player, questId)
	end)
	Network:bindFunction("Quest_Abandon", function(player, questId)
		return QuestService:AbandonQuest(player, questId)
	end)
	Network:bindFunction("Quest_Complete", function(player, questId)
		return QuestService:CompleteQuest(player, questId)
	end)
	Network:bindFunction("Quest_GetActive", function(player)
		return QuestService:GetActiveQuests(player)
	end)
	Network:bindFunction("Quest_GetCompleted", function(player)
		return QuestService:GetCompletedQuests(player)
	end)
end

Players.PlayerAdded:Connect(function(player)
	task.delay(2, function()
		if player.Parent then QuestService:SyncToClient(player) end
	end)
end)

task.spawn(function()
	while true do
		task.wait(5)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = getProfile(player)
			if profile and profile.currentQuests then
				for questId, progress in pairs(profile.currentQuests) do
					checkExpiration(player, profile, questId, progress)
				end
			end
		end
	end
end)

return QuestService
