return function(Client)
	local DevFakePlayers = {}

	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Client.player
	local PlayerGui = player:WaitForChild("PlayerGui")

	local ListTab = ReplicatedStorage:WaitForChild("Kits"):WaitForChild("UI"):WaitForChild("ListTab")

	local FAKE_TAG = "DevFakeListTab"

	local NAMES = {
		{ "Roronoa", "Zoro" },
		{ "Nico", "Robin" },
		{ "Sanji", "Vinsmoke" },
		{ "Tony", "Chopper" },
		{ "Usopp", "Sogeking" },
		{ "Franky", "Cutty" },
		{ "Brook", "Soul" },
		{ "Jinbe", "Knight" },
		{ "Portgas", "Ace" },
		{ "Edward", "Newgate" },
		{ "Marshall", "Teach" },
		{ "Charlotte", "Linlin" },
		{ "Kaido", "Kurozumi" },
		{ "Boa", "Hancock" },
		{ "Trafalgar", "Law" },
		{ "Eustass", "Kid" },
		{ "Smoker", "Tashigi" },
		{ "Garp", "Monkey" },
		{ "Sengoku", "Buddha" },
		{ "Akainu", "Sakazuki" },
		{ "Kuzan", "Aokiji" },
		{ "Borsalino", "Kizaru" },
		{ "Tsuru", "Marine" },
		{ "Coby", "Marine" },
		{ "Helmeppo", "Marine" },
		{ "Monkey", "Dragon" },
		{ "Sabo", "Revolutionary" },
		{ "Koala", "Revolutionary" },
		{ "Ivankov", "Emporio" },
		{ "Kuma", "Bartholomew" },
	}

	local CREWS = {
		Pirate = { "Straw Hat", "Heart", "Kid Pirates", "Whitebeard", "Beast Pirates", "Big Mom", "None" },
		Marine = { "G-1", "G-2", "G-5", "Marine HQ", "SWORD", "None" },
		Revolutionary = { "Revolutionary Army", "Eastern Army", "Northern Army", "None" },
		Civilian = { "None", "None", "None", "Pacifista" },
	}

	local FACTION_PLAN = {
		Pirate = 6,
		Marine = 5,
		Revolutionary = 2,
		Civilian = 1,
	}

	local FACTION_COLORS = {
		Pirate = Color3.fromRGB(150, 50, 50),
		Marine = Color3.fromRGB(50, 100, 200),
		Revolutionary = Color3.fromRGB(85, 85, 255),
		Civilian = Color3.fromRGB(150, 150, 150),
	}

	local function pickName(usedSet)
		for _ = 1, 50 do
			local entry = NAMES[math.random(1, #NAMES)]
			local key = entry[1] .. "_" .. entry[2]
			if not usedSet[key] then
				usedSet[key] = true
				return entry[1], entry[2]
			end
		end
		local n = math.random(1000, 9999)
		return "Pirate", tostring(n)
	end

	local function pickCrew(faction)
		local pool = CREWS[faction] or CREWS.Civilian
		return pool[math.random(1, #pool)]
	end

	local function getSection(faction)
		local UI = PlayerGui:WaitForChild("UI")
		local PlayerListFrame = UI:FindFirstChild("PlayerListFrame")
		if not PlayerListFrame then return nil end

		local map = {
			Pirate = "PirateSection",
			Marine = "MarineSection",
			Revolutionary = "RevSection",
			Civilian = "CivilianSection",
		}
		local section = PlayerListFrame:FindFirstChild(map[faction])
		if not section then return nil end
		local list = section:FindFirstChild("PlayerList")
		if not list then return nil end
		return section, list
	end

	local function clearFakes()
		local UI = PlayerGui:FindFirstChild("UI")
		local PlayerListFrame = UI and UI:FindFirstChild("PlayerListFrame")
		if not PlayerListFrame then return end

		local touched = {}
		for _, section in ipairs(PlayerListFrame:GetChildren()) do
			local list = section:FindFirstChild("PlayerList")
			if list then
				for _, child in ipairs(list:GetChildren()) do
					if child:GetAttribute(FAKE_TAG) then
						child:Destroy()
						touched[section.Name] = true
					end
				end
			end
		end

		local nameToFaction = {
			PirateSection = "Pirate",
			MarineSection = "Marine",
			RevSection = "Revolutionary",
			CivilianSection = "Civilian",
		}
		for sectionName in pairs(touched) do
			local faction = nameToFaction[sectionName]
			if faction then
				task.defer(function()
					if Client.PlayerList and Client.PlayerList.UpdateSection then
						local section, list = getSection(faction)
						if section and list then
							local count = 0
							for _, c in ipairs(list:GetChildren()) do
								if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
									count += 1
								end
							end
							Client.PlayerList:UpdateSection(section, ({
								Pirate = "PIRATES",
								Marine = "MARINES",
								Revolutionary = "REBELS",
								Civilian = "CIVILIANS",
							})[faction], count)
						end
					end
				end)
			end
		end
	end

	local SECTION_NAME = {
		Pirate = "PIRATES",
		Marine = "MARINES",
		Revolutionary = "REBELS",
		Civilian = "CIVILIANS",
	}

	local function countListEntries(list)
		local count = 0
		for _, child in ipairs(list:GetChildren()) do
			if not child:IsA("UIListLayout")
				and not child:IsA("UIPadding")
				and not child:IsA("UIGridLayout")
				and not child:IsA("UICorner")
				and not child:IsA("UIStroke") then
				count += 1
			end
		end
		return count
	end

	local function refreshSectionSize(faction)
		local PlayerListClient = Client.PlayerList
		if not PlayerListClient or not PlayerListClient.UpdateSection then return end

		local section, list = getSection(faction)
		if not section or not list then return end

		PlayerListClient:UpdateSection(section, SECTION_NAME[faction] or faction:upper(), countListEntries(list))
	end

	local function spawnFake(faction, firstName, lastName, layoutOrder)
		local section, list = getSection(faction)
		if not section or not list then
			warn("[DevFakePlayers] Section not found for", faction)
			return
		end

		local tab = ListTab:Clone()
		tab:SetAttribute(FAKE_TAG, true)
		tab.Visible = true
		tab.LayoutOrder = layoutOrder

		local nameLabel = tab:FindFirstChild("playerNameRank") or tab:FindFirstChild("NameLabel")
		if nameLabel then
			nameLabel.Name = "NameLabel"
			nameLabel.Text = (firstName .. " " .. lastName):upper()
		end

		local crewLabel = tab:FindFirstChild("playerCrew") or tab:FindFirstChild("CrewLabel")
		if crewLabel then
			crewLabel.Name = "CrewLabel"
			crewLabel.BackgroundTransparency = 1
			crewLabel.Text = (pickCrew(faction)):upper()
		end

		tab.Parent = list
	end

	local function populate()
		clearFakes()

		local used = {}
		for faction, count in pairs(FACTION_PLAN) do
			local section, list = getSection(faction)
			if section and list then
				local startOrder = countListEntries(list) + 1
				for i = 1, count do
					local first, last = pickName(used)
					spawnFake(faction, first, last, startOrder + i - 1)
				end
				refreshSectionSize(faction)
			end
		end
	end

	local function hookRefresh()
		local PlayerListClient = Client.PlayerList
		if not PlayerListClient or not PlayerListClient.RefreshPlayerList then return end
		if PlayerListClient._devFakePatched then return end
		PlayerListClient._devFakePatched = true

		local original = PlayerListClient.RefreshPlayerList
		PlayerListClient.RefreshPlayerList = function(self, ...)
			local result = original(self, ...)
			task.defer(populate)
			return result
		end
	end

	function DevFakePlayers:Init()
		if not RunService:IsStudio() then return end

		hookRefresh()

		task.spawn(function()
			task.wait(3)
			populate()
		end)

		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.KeyCode == Enum.KeyCode.F9 then
				populate()
			elseif input.KeyCode == Enum.KeyCode.F10 then
				clearFakes()
			end
		end)
	end

	return DevFakePlayers
end
