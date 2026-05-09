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

		for _, section in ipairs(PlayerListFrame:GetChildren()) do
			local list = section:FindFirstChild("PlayerList")
			if list then
				for _, child in ipairs(list:GetChildren()) do
					if child:GetAttribute(FAKE_TAG) then
						child:Destroy()
					end
				end
			end
		end
	end

	local function bumpSectionSize(section, faction, fakeCount)
		local countFrame = section:FindFirstChild("CountFrame")
		local countLabel = countFrame and countFrame:FindFirstChild("CountLabel")
		if countLabel then
			local current = countLabel.Text:match("%((%d+)%)") or "0"
			local realCount = tonumber(current) or 0
			local total = realCount + fakeCount

			local sectionName = ({
				Pirate = "PIRATES",
				Marine = "MARINES",
				Revolutionary = "REBELS",
				Civilian = "CIVILIANS",
			})[faction] or faction:upper()

			countLabel.Text = sectionName .. " (" .. total .. ")"
		end
		section.Visible = true
	end

	local function spawnFake(faction, firstName, lastName)
		local section, list = getSection(faction)
		if not section or not list then
			warn("[DevFakePlayers] Section not found for", faction)
			return
		end

		local tab = ListTab:Clone()
		tab:SetAttribute(FAKE_TAG, true)
		tab.LayoutOrder = math.random(1, 10000)

		local nameLabel = tab:FindFirstChild("playerNameRank")
		if nameLabel then
			nameLabel.Name = "NameLabel"
			nameLabel.Text = (firstName .. " " .. lastName):upper()
		end

		local crewLabel = tab:FindFirstChild("playerCrew")
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
			local section = getSection(faction)
			if section then
				for _ = 1, count do
					local first, last = pickName(used)
					spawnFake(faction, first, last)
				end
				bumpSectionSize(section, faction, count)
			end
		end
	end

	function DevFakePlayers:Init()
		if not RunService:IsStudio() then return end

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
