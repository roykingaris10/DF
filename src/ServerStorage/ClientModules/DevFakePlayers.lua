return function(Client)
	local DevFakePlayers = {}

	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Client.player
	local PlayerGui = player:WaitForChild("PlayerGui")

	local DEV_USER_IDS = {
		[22985938] = true,
		[146140097] = true,
		[1122722591] = true,
	}

	local function isDev()
		if RunService:IsStudio() then return true end
		return DEV_USER_IDS[player.UserId] == true
	end

	local ListTab = ReplicatedStorage:WaitForChild("Kits"):WaitForChild("UI"):WaitForChild("ListTab")
	local PartyInfoTemplate = ReplicatedStorage:WaitForChild("Kits"):WaitForChild("UI"):FindFirstChild("partyInfo")

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

	local cachedRoster = nil

	local function buildRoster()
		local roster = {}
		local used = {}
		for faction, count in pairs(FACTION_PLAN) do
			roster[faction] = {}
			for _ = 1, count do
				local first, last = pickName(used)
				table.insert(roster[faction], {
					first = first,
					last = last,
					crew = pickCrew(faction),
				})
			end
		end
		return roster
	end

	local function populate(reroll)
		clearFakes()

		if reroll or not cachedRoster then
			cachedRoster = buildRoster()
		end

		for faction, entries in pairs(cachedRoster) do
			local section, list = getSection(faction)
			if section and list then
				local startOrder = countListEntries(list) + 1
				for i, entry in ipairs(entries) do
					local section2, list2 = getSection(faction)
					if section2 and list2 then
						local tab = ListTab:Clone()
						tab:SetAttribute(FAKE_TAG, true)
						tab.Visible = true
						tab.LayoutOrder = startOrder + i - 1

						local nameLabel = tab:FindFirstChild("playerNameRank") or tab:FindFirstChild("NameLabel")
						if nameLabel then
							nameLabel.Name = "NameLabel"
							nameLabel.Text = (entry.first .. " " .. entry.last):upper()
						end

						local crewLabel = tab:FindFirstChild("playerCrew") or tab:FindFirstChild("CrewLabel")
						if crewLabel then
							crewLabel.Name = "CrewLabel"
							crewLabel.BackgroundTransparency = 1
							crewLabel.Text = entry.crew:upper()
						end

						tab.Parent = list2
					end
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

	local PARTY_FAKE_TAG = "DevFakePartyTab"
	local PARTY_PLAN_SIZE = 5

	local PARTY_NAMES = {
		{ "Roronoa", "Zoro", 42 },
		{ "Nico", "Robin", 38 },
		{ "Sanji", "Vinsmoke", 41 },
		{ "Tony", "Chopper", 26 },
		{ "Usopp", "Sogeking", 33 },
		{ "Franky", "Cutty", 47 },
		{ "Brook", "Soul", 55 },
		{ "Jinbe", "Knight", 60 },
		{ "Trafalgar", "Law", 50 },
		{ "Eustass", "Kid", 49 },
	}

	local PARTY_COLORS = {
		Color3.fromRGB(220, 100, 100),
		Color3.fromRGB(100, 180, 255),
		Color3.fromRGB(120, 220, 140),
		Color3.fromRGB(255, 200, 80),
		Color3.fromRGB(190, 130, 255),
		Color3.fromRGB(255, 150, 200),
	}

	local cachedPartyRoster = nil

	local function buildPartyRoster()
		local roster = {}
		local used = {}
		for i = 1, PARTY_PLAN_SIZE do
			local pickIdx
			repeat
				pickIdx = math.random(1, #PARTY_NAMES)
			until not used[pickIdx]
			used[pickIdx] = true

			local entry = PARTY_NAMES[pickIdx]
			table.insert(roster, {
				first = entry[1],
				last = entry[2],
				level = entry[3] + math.random(-3, 5),
				color = PARTY_COLORS[((i - 1) % #PARTY_COLORS) + 1],
				isLeader = i == 1,
			})
		end
		return roster
	end

	local function getPartyFrame()
		local HUD = PlayerGui:FindFirstChild("HUD")
		local PartyHolder = HUD and HUD:FindFirstChild("PartyHolder")
		if not PartyHolder then return nil end
		local partyFrame = PartyHolder:FindFirstChild("partyFrame")
		return partyFrame, PartyHolder
	end

	local function clearPartyFakes()
		local partyFrame = getPartyFrame()
		if not partyFrame then return end
		for _, child in ipairs(partyFrame:GetChildren()) do
			if child:GetAttribute(PARTY_FAKE_TAG) then
				child:Destroy()
			end
		end
	end

	local function spawnPartyFake(entry, index)
		if not PartyInfoTemplate then
			warn("[DevFakePlayers] partyInfo template missing in Kits.UI")
			return
		end

		local partyFrame, PartyHolder = getPartyFrame()
		if not partyFrame or not PartyHolder then
			warn("[DevFakePlayers] PartyHolder.partyFrame not found")
			return
		end

		PartyHolder.Visible = true
		partyFrame.Visible = true

		local newFrame = PartyInfoTemplate:Clone()
		if not newFrame then
			warn("[DevFakePlayers] partyInfo clone returned nil")
			return
		end
		newFrame:SetAttribute(PARTY_FAKE_TAG, true)
		newFrame.Name = "partyInfo_fake_" .. index
		newFrame.LayoutOrder = index
		newFrame.Visible = true

		local colour = newFrame:FindFirstChild("colour")
		if colour and colour:IsA("ImageLabel") then
			colour.ImageColor3 = entry.color
		end

		local info = newFrame:FindFirstChild("info")
		if info then
			local playerFolder = info:FindFirstChild("player")
			if playerFolder then
				local playerName = playerFolder:FindFirstChild("playerName")
				local playerLevel = playerFolder:FindFirstChild("playerLevel")

				if playerName then
					local display = entry.first .. " " .. entry.last
					if entry.isLeader then display = "★ " .. display end
					playerName.Text = display:upper()
				end
				if playerLevel then
					playerLevel.Text = "Lv. " .. tostring(entry.level)
				end
			end
		end

		local inner = newFrame:FindFirstChild("inner")
		local playerView = inner and inner:FindFirstChild("playerView")
		if playerView and playerView:IsA("ViewportFrame") and player.Character then
			pcall(function()
				local cameraSlot = playerView:FindFirstChildOfClass("Camera")
				if not cameraSlot then
					cameraSlot = Instance.new("Camera")
					cameraSlot.Parent = playerView
				end
				playerView.CurrentCamera = cameraSlot

				for _, c in ipairs(playerView:GetChildren()) do
					if c:IsA("Model") then c:Destroy() end
				end

				local clone = player.Character:Clone()
				if clone then
					clone.Parent = playerView
					local head = clone:FindFirstChild("Head")
					if head and head:IsA("BasePart") then
						cameraSlot.CFrame = CFrame.new(head.Position + head.CFrame.LookVector * 3, head.Position)
					end
				end
			end)
		end

		newFrame.Parent = partyFrame
	end

	local partyVisibilityConn = nil

	local function lockPartyHolderVisible()
		if partyVisibilityConn then return end
		local _, PartyHolder = getPartyFrame()
		if not PartyHolder then return end

		partyVisibilityConn = PartyHolder:GetPropertyChangedSignal("Visible"):Connect(function()
			if cachedPartyRoster and not PartyHolder.Visible then
				task.defer(function()
					if cachedPartyRoster then
						PartyHolder.Visible = true
					end
				end)
			end
		end)
	end

	local function unlockPartyHolderVisible()
		if partyVisibilityConn then
			partyVisibilityConn:Disconnect()
			partyVisibilityConn = nil
		end
	end

	local function populateParty(reroll)
		clearPartyFakes()
		if reroll or not cachedPartyRoster then
			cachedPartyRoster = buildPartyRoster()
		end
		lockPartyHolderVisible()
		for i, entry in ipairs(cachedPartyRoster) do
			spawnPartyFake(entry, i)
		end
	end

	function DevFakePlayers:Init()
		if not isDev() then return end

		hookRefresh()

		task.spawn(function()
			task.wait(3)
			populate()
			populateParty()
		end)

		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.KeyCode == Enum.KeyCode.F9 then
				populate(true)
			elseif input.KeyCode == Enum.KeyCode.F10 then
				cachedRoster = nil
				clearFakes()
			elseif input.KeyCode == Enum.KeyCode.F7 then
				populateParty(true)
			elseif input.KeyCode == Enum.KeyCode.F8 then
				cachedPartyRoster = nil
				unlockPartyHolderVisible()
				clearPartyFakes()
				local _, PartyHolder = getPartyFrame()
				if PartyHolder then PartyHolder.Visible = false end
			end
		end)
	end

	return DevFakePlayers
end
