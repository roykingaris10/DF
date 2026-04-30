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

task.spawn(function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local OkFramework = ServerScriptService:WaitForChild("OkFramework", 30)
	if not OkFramework then
		warn("[DevCommands] OkFramework not found within 30s; /quest disabled")
		return
	end

	local ok, Server = pcall(require, OkFramework)
	if not ok or not Server then
		warn("[DevCommands] failed to require OkFramework:", Server)
		return
	end

	local USAGE = "[/quest] usage: list | accept <id> | complete <id> | abandon <id> | clear | progress <type> <target> [amount] | kill <target> [amount] | collect <target> [amount] | reach <target> | talk <target>"

	local function fireProgress(p, eventType, target, amount)
		Server.QuestService:RegisterEvent(p, eventType, target, amount or 1)
		print(string.format("[/quest %s] fired %s/%s x%d", string.lower(eventType), eventType, target, amount or 1))
	end

	local questCmd = Instance.new("TextChatCommand")
	questCmd.Name = "DevQuestCommand"
	questCmd.PrimaryAlias = "/quest"
	questCmd.Parent = TextChatService

	questCmd.Triggered:Connect(function(textSource, msg)
		local p = Players:GetPlayerByUserId(textSource.UserId)
		if not p then return end
		local args = {}
		for token in msg:gmatch("%S+") do table.insert(args, token) end
		local sub = args[2] and string.lower(args[2]) or nil
		if not sub then
			print(USAGE)
			return
		end
		if sub == "list" then
			local names = {}
			for id in pairs(Server.QuestInfo or {}) do table.insert(names, id) end
			table.sort(names)
			print("[/quest] Quests: " .. table.concat(names, ", "))
		elseif sub == "accept" and args[3] then
			local ok2, reason = Server.QuestService:AcceptQuest(p, args[3])
			print(string.format("[/quest accept %s] %s %s", args[3], tostring(ok2), tostring(reason)))
		elseif sub == "complete" and args[3] then
			local ok2, reason = Server.QuestService:CompleteQuest(p, args[3])
			print(string.format("[/quest complete %s] %s %s", args[3], tostring(ok2), tostring(reason)))
		elseif sub == "abandon" and args[3] then
			local ok2, reason = Server.QuestService:AbandonQuest(p, args[3])
			print(string.format("[/quest abandon %s] %s %s", args[3], tostring(ok2), tostring(reason)))
		elseif sub == "clear" or sub == "reset" or sub == "wipe" then
			local ok2, reason = Server.QuestService:ResetQuests(p)
			print(string.format("[/quest clear] %s %s", tostring(ok2), tostring(reason)))
		elseif sub == "progress" and args[3] and args[4] then
			fireProgress(p, args[3], args[4], tonumber(args[5]))
		elseif sub == "kill" and args[3] then
			fireProgress(p, "Kill", args[3], tonumber(args[4]))
		elseif sub == "collect" and args[3] then
			fireProgress(p, "Collect", args[3], tonumber(args[4]))
		elseif sub == "reach" and args[3] then
			fireProgress(p, "Reach", args[3], tonumber(args[4]))
		elseif sub == "talk" and args[3] then
			fireProgress(p, "Talk", args[3], tonumber(args[4]))
		else
			print(USAGE)
		end
	end)

	print("[DevCommands] /quest registered")
end)

print("[DevCommands] /tp registered (Studio-only). Usage: /tp <RegionName> | /tp")
