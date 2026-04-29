-- Dev-only chat commands. Loaded as a Script directly under ServerScriptService.
-- Studio-only by default so it can't ship live by accident.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

if not RunService:IsStudio() then
	return
end

local function listRegions()
	local regionsFolder = workspace:FindFirstChild("Regions")
	if not regionsFolder then
		return "No Regions folder in workspace."
	end
	local names = {}
	for _, typeFolder in ipairs(regionsFolder:GetChildren()) do
		for _, part in ipairs(typeFolder:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(names, typeFolder.Name .. "/" .. part.Name)
			end
		end
	end
	if #names == 0 then
		return "No region parts found."
	end
	table.sort(names)
	return "Regions: " .. table.concat(names, ", ")
end

local function findRegion(query)
	local regionsFolder = workspace:FindFirstChild("Regions")
	if not regionsFolder then return nil end
	local lower = string.lower(query)
	for _, typeFolder in ipairs(regionsFolder:GetChildren()) do
		for _, part in ipairs(typeFolder:GetChildren()) do
			if part:IsA("BasePart") and string.lower(part.Name) == lower then
				return part, typeFolder.Name
			end
		end
	end
	return nil
end

local function teleport(player, regionName)
	if not regionName or regionName == "" then
		return listRegions()
	end

	local part, typeName = findRegion(regionName)
	if not part then
		return ("Region %q not found. Try /tp with no argument to list."):format(regionName)
	end

	local character = player.Character
	if not character then
		return "No character to teleport."
	end

	local target = part.Position + Vector3.new(0, part.Size.Y / 2 + 5, 0)
	character:PivotTo(CFrame.new(target))
	return ("Teleported to %s/%s at %.0f, %.0f, %.0f"):format(typeName, part.Name, target.X, target.Y, target.Z)
end

local cmd = Instance.new("TextChatCommand")
cmd.Name = "DevTeleportCommand"
cmd.PrimaryAlias = "/tp"
cmd.SecondaryAlias = "/tpregion"
cmd.Parent = TextChatService

cmd.Triggered:Connect(function(textSource, message)
	local player = Players:GetPlayerByUserId(textSource.UserId)
	if not player then return end

	-- Strip the command itself off the front to get the argument.
	local arg = message:match("^/%S+%s*(.-)%s*$") or ""
	local result = teleport(player, arg)
	print("[/tp] " .. result)
end)

local OkFramework = game:GetService("ServerScriptService"):FindFirstChild("OkFramework")
if OkFramework then
	task.spawn(function()
		local ok, Server = pcall(require, OkFramework)
		if not ok or not Server then return end

		local questCmd = Instance.new("TextChatCommand")
		questCmd.Name = "DevQuestCommand"
		questCmd.PrimaryAlias = "/quest"
		questCmd.Parent = TextChatService

		questCmd.Triggered:Connect(function(textSource, msg)
			local p = Players:GetPlayerByUserId(textSource.UserId)
			if not p then return end
			local sub, rest = msg:match("^/%S+%s+(%S+)%s*(.-)%s*$")
			if not sub then
				print("[/quest] usage: /quest list | /quest accept <id> | /quest complete <id> | /quest abandon <id>")
				return
			end
			if sub == "list" then
				local names = {}
				for id in pairs(Server.QuestInfo or {}) do table.insert(names, id) end
				table.sort(names)
				print("[/quest] Quests: " .. table.concat(names, ", "))
			elseif sub == "accept" and rest ~= "" then
				local ok2, reason = Server.QuestService:AcceptQuest(p, rest)
				print(string.format("[/quest accept %s] %s %s", rest, tostring(ok2), tostring(reason)))
			elseif sub == "complete" and rest ~= "" then
				local ok2, reason = Server.QuestService:CompleteQuest(p, rest)
				print(string.format("[/quest complete %s] %s %s", rest, tostring(ok2), tostring(reason)))
			elseif sub == "abandon" and rest ~= "" then
				local ok2, reason = Server.QuestService:AbandonQuest(p, rest)
				print(string.format("[/quest abandon %s] %s %s", rest, tostring(ok2), tostring(reason)))
			else
				print("[/quest] usage: /quest list | /quest accept <id> | /quest complete <id> | /quest abandon <id>")
			end
		end)
	end)
end

print("[DevCommands] /tp registered (Studio-only). Usage: /tp <RegionName> | /tp")
