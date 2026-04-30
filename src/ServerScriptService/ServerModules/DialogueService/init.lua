local Server = require(script.Parent)
local Network = Server.Network
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local DialogueService = {}
DialogueService.NPCDialogues = {}
DialogueService.QuestDialogues = {}
DialogueService.ShopDialogues = {}
DialogueService.SkillDialogues = {}

local function loadDictionaries()
	local function safeRequire(child)
		if not child or not child:IsA("ModuleScript") then return nil end
		local ok, dict = pcall(require, child)
		if not ok or type(dict) ~= "table" then return nil end
		return dict
	end

	local function merge(target, dict)
		if not dict then return end
		for npcName, value in pairs(dict) do
			if target[npcName] == nil then
				target[npcName] = value
			end
		end
	end

	merge(DialogueService.NPCDialogues, safeRequire(script:FindFirstChild("DialogueDictionary")))
	merge(DialogueService.QuestDialogues, safeRequire(script:FindFirstChild("QuestDialogueDictionary")))
	merge(DialogueService.ShopDialogues, safeRequire(script:FindFirstChild("ShopDialogueDictionary")))
	merge(DialogueService.SkillDialogues, safeRequire(script:FindFirstChild("SkillDialogueDictionary")))
end

local function initializeNPC(NPC)
	if not NPC then return end

	for _, part in pairs(NPC:GetDescendants()) do
		if part:IsA('BasePart') then
			part.CollisionGroup = "Characters"
		end
	end

	local function loadInto(target, childName)
		local child = NPC:FindFirstChild(childName)
		if child and child:IsA("ModuleScript") then
			local ok, dialogue = pcall(require, child)
			if ok and dialogue then
				target[NPC.Name] = dialogue
			end
		end
	end

	loadInto(DialogueService.NPCDialogues, "Dialogue")
	loadInto(DialogueService.QuestDialogues, "QuestDialogue")
	loadInto(DialogueService.ShopDialogues, "ShopDialogue")
	loadInto(DialogueService.SkillDialogues, "SkillDialogue")
end

function DialogueService.GetDialogue(player, NPC)
	local entity = Server.EntityService.Find(player)
	if not entity then
		return false, "Entity not found"
	end

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return false, "Character not loaded"
	end

	if not NPC:FindFirstChild("HumanoidRootPart") then
		return false, "NPC invalid"
	end

	local distance = (player.Character.HumanoidRootPart.Position - NPC.HumanoidRootPart.Position).Magnitude
	if distance > 50 then
		return false, "Too far from NPC"
	end

	local profile = entity.SlotProfile

	if Server.QuestService and Server.QuestService.RegisterEvent then
		Server.QuestService:RegisterEvent(player, "Talk", NPC.Name, 1)
	end

	if DialogueService.QuestDialogues[NPC.Name] then
		local function hasDefault(node)
			return type(node) == "table" and type(node.Default) == "table"
		end

		for _, questDialogue in ipairs(DialogueService.QuestDialogues[NPC.Name]) do
			local questName = questDialogue.Name
			local questInfo = Server.QuestInfo and Server.QuestInfo[questName]
			local repeatable = questInfo and questInfo.Repeatable

			if table.find(profile.questsCompleted, questName) and not repeatable then
				continue
			end

			local current = profile.currentQuests[questName]
			if current ~= nil then
				local stateTable
				if type(current) == "table" and questInfo then
					local lastStageIdx = questInfo.Stages and #questInfo.Stages or 1
					if current.Stage > lastStageIdx then
						stateTable = questDialogue.Completed
					else
						stateTable = questDialogue.InProgress
					end
				elseif type(current) == "number" and questInfo then
					if questInfo.Requirement == current then
						table.insert(profile.questsCompleted, questName)
						stateTable = questDialogue.Completed
					else
						stateTable = questDialogue.InProgress
					end
				elseif type(current) == "boolean" then
					if current then
						table.insert(profile.questsCompleted, questName)
						stateTable = questDialogue.Completed
					else
						stateTable = questDialogue.InProgress
					end
				end

				if hasDefault(stateTable) then
					return true, stateTable
				end
				continue
			end

			if Server.QuestService and Server.QuestService.CanAccept then
				local canAccept = Server.QuestService:CanAccept(player, questName)
				if not canAccept then
					continue
				end
			end

			if hasDefault(questDialogue.Initial) then
				return true, questDialogue.Initial
			end
		end
	end

	if DialogueService.ShopDialogues[NPC.Name] then
		local shopData = (Server.ShopInfo and Server.ShopInfo[NPC.Name]) or nil
		return true, DialogueService.ShopDialogues[NPC.Name], shopData
	end

	if DialogueService.NPCDialogues[NPC.Name] then
		local shopData = (Server.ShopInfo and Server.ShopInfo[NPC.Name]) or nil
		local entry = DialogueService.NPCDialogues[NPC.Name]
		local node = (type(entry) == "table" and entry[1] and type(entry[1]) == "table" and entry[1].Default) and entry[1] or entry
		return true, node, shopData
	end

	return false, "No dialogue found"
end

function DialogueService.ProcessAction(player, action, data)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "Entity not found" end

	local profile = entity.SlotProfile

	if action == "AcceptQuest" then
		local questName = data.questName
		if not (Server.QuestInfo and Server.QuestInfo[questName]) then
			return false, "Quest not found"
		end
		if Server.QuestService and Server.QuestService.AcceptQuest then
			return Server.QuestService:AcceptQuest(player, questName)
		end
		return false, "QuestService unavailable"

	elseif action == "TurnInQuest" then
		if Server.QuestService and Server.QuestService.CompleteQuest then
			return Server.QuestService:CompleteQuest(player, data.questName)
		end
		return false, "QuestService unavailable"

	elseif action == "AbandonQuest" then
		if Server.QuestService and Server.QuestService.AbandonQuest then
			return Server.QuestService:AbandonQuest(player, data.questName)
		end
		return false, "QuestService unavailable"

	elseif action == "JoinFaction" then
		local factionId = data.factionId
		if not factionId then return false, "No faction specified" end

		local success, displayNameOrError, levelRank = Server.FactionService.JoinFaction(player, factionId)
		return success, displayNameOrError, levelRank

	elseif action == "Marine" then
		local success, displayNameOrError, levelRank = Server.FactionService.JoinFaction(player, "Marine")
		return success, displayNameOrError, levelRank

	elseif action == "Pirate" then
		local success, displayNameOrError, levelRank = Server.FactionService.JoinFaction(player, "Pirate")
		return success, displayNameOrError, levelRank

	elseif action == "Revolutionary" then
		local success, displayNameOrError, levelRank = Server.FactionService.JoinFaction(player, "Revolutionary")
		return success, displayNameOrError, levelRank

	elseif action == "Civilian" then
		local success, message = Server.FactionService.LeaveFaction(player)
		return success, message

	elseif action == "CrewCreator" then
		return true, "Crew creator opened"
	end

	return false, "Unknown action"
end

local function initializeAllNPCs()
	loadDictionaries()

	local npcFolder = workspace:WaitForChild("NPCDialogue")
	for _, npc in pairs(npcFolder:GetChildren()) do
		initializeNPC(npc)
	end

	npcFolder.ChildAdded:Connect(initializeNPC)
end

Network:bindFunction('Dialogue', function(player, NPC)
	return DialogueService.GetDialogue(player, NPC)
end)

Network:bindFunction('DialogueAction', function(player, action, data)
	return DialogueService.ProcessAction(player, action, data)
end)

initializeAllNPCs()

return DialogueService