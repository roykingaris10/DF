
return function(Client)

	local PlayerListClient = {}
	local player = Client.player
	local Network = Client.Network
	local Players = game:GetService("Players")
	local PlayerGui = player:WaitForChild('PlayerGui')

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ListTab = ReplicatedStorage.Kits.UI.ListTab

	function PlayerListClient:RefreshPlayerList()
		local UI = PlayerGui:WaitForChild("UI")
		local PlayerListFrame = UI:WaitForChild("PlayerListFrame")

		local PirateSection = PlayerListFrame:WaitForChild("PirateSection")
		local MarineSection = PlayerListFrame:WaitForChild("MarineSection")
		local CivilianSection = PlayerListFrame:WaitForChild("CivilianSection")
		local RevSection = PlayerListFrame:WaitForChild("RevSection")


		local PirateList = PirateSection:WaitForChild("PlayerList")
		local MarineList = MarineSection:WaitForChild("PlayerList")
		local CivilianList = CivilianSection:WaitForChild("PlayerList")
		local RevList = RevSection:WaitForChild("PlayerList")


		-- Clear existing entries
		PirateList:ClearAllChildren()
		MarineList:ClearAllChildren()
		CivilianList:ClearAllChildren()
		RevList:ClearAllChildren()

		local pirates = {}
		local marines = {}
		local civilians = {}
		local revs = {}


		for _, plr in ipairs(Players:GetPlayers()) do
			local statFolder = plr:FindFirstChild("StatFolder")
			if not statFolder then continue end

			local userFolder = statFolder:FindFirstChild("UserFolder")
			if not userFolder then continue end

			local factionName = userFolder:GetAttribute("Faction") --or "None" or nil or ""

			local playerData = {
				Name = plr.Name,
				Faction = factionName,
				Player = plr
			}
			
			
			if factionName == "Marine" then
				table.insert(marines, playerData)
			elseif factionName == "Revolutionary" then
				table.insert(revs, playerData)
			elseif factionName == "Pirate" then
				table.insert(pirates, playerData)
			elseif factionName == "None" or nil or "" then
				table.insert(civilians, playerData)
			end

		--[[	if factionName == "Marine" then
				table.insert(marines, playerData)
			elseif factionName == "Revolutionary" then
				table.insert(revs, playerData)
			elseif factionName ~= "None" and factionName ~= "" and factionName ~= "nil" then
				table.insert(pirates, playerData)
			else
				table.insert(civilians, playerData)
			end]]
		end

		-- Sort by name
		table.sort(pirates, function(a, b) return a.Name < b.Name end)
		table.sort(marines, function(a, b) return a.Name < b.Name end)
		table.sort(civilians, function(a, b) return a.Name < b.Name end)
		table.sort(revs, function(a, b) return a.Name < b.Name end)

		-- Create entries
		PlayerListClient:PopulateList(PirateList, pirates, Color3.fromRGB(150, 50, 50))
		PlayerListClient:PopulateList(MarineList, marines, Color3.fromRGB(50, 100, 200))
		PlayerListClient:PopulateList(CivilianList, civilians, Color3.fromRGB(150, 150, 150))
		PlayerListClient:PopulateList(RevList, revs, Color3.fromRGB(85, 85, 255))

		-- Update counts and visibility
		PlayerListClient:UpdateSection(PirateSection, "PIRATES", #pirates)
		PlayerListClient:UpdateSection(MarineSection, "MARINES", #marines)
		PlayerListClient:UpdateSection(CivilianSection, "CIVILIANS", #civilians)
		PlayerListClient:UpdateSection(RevSection, "REBELS", #revs)

	end

	function PlayerListClient:UpdateSection(section, sectionName, playerCount)
		local countLabel = section.CountFrame:FindFirstChild("CountLabel")
		local playerList = section:FindFirstChild("PlayerList")

		if not countLabel or not playerList then return end

		countLabel.Text = `{sectionName} ({playerCount})`

		if playerCount == 0 then
			section.Visible = false
			section.CountFrame.Visible = true
			section.Size = UDim2.new(1, 0, 0, 0)
		else
			-- Show section
			section.Visible = true
			section.CountFrame.Visible = true

			local tabHeight = ListTab.Size.Y.Offset
			local padding = 6
			local headerHeight = 25
			local maxHeight = 200 

			local contentHeight = (playerCount * tabHeight) + ((playerCount - 1) * padding) + 10
			local finalListHeight = math.min(contentHeight, maxHeight)

			playerList.Size = UDim2.new(1, 0, 0, finalListHeight)

			section.Size = UDim2.new(1, 0, 0, headerHeight + finalListHeight)
		end
	end

	function PlayerListClient:PopulateList(scrollingFrame, playerDataList, color)
		-- Clear existing UIListLayout if it exists
		local existingLayout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
		if existingLayout then
			existingLayout:Destroy()
		end

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 2)
		UIListLayout.Parent = scrollingFrame

		for i, data in ipairs(playerDataList) do

			local targetPlayer = data.Player
			local targetStatFolder = targetPlayer:FindFirstChild("StatFolder")

			if not targetStatFolder then
				warn(`Could not find StatFolder for {targetPlayer.Name}`)
				continue
			end

			local targetUserFolder = targetStatFolder:FindFirstChild("UserFolder")

			if not targetUserFolder then
				warn(`Could not find UserFolder for {targetPlayer.Name}`)
				continue
			end

			local Tab = ListTab:Clone()
			Tab.LayoutOrder = i

			local nameLabel = Tab:FindFirstChild("playerNameRank")
			if nameLabel then
				nameLabel.Name = "NameLabel"

				local firstName = targetUserFolder:GetAttribute("FirstName") or ""
				local middleName = targetUserFolder:GetAttribute("MiddleName") or ""
				local lastName = targetUserFolder:GetAttribute("LastName") or ""

				local fullName = firstName
				if middleName ~= "" then
					fullName = fullName .. " " .. middleName
				end
				fullName = fullName .. " " .. lastName

				nameLabel.Text = fullName:upper()

				nameLabel.MouseEnter:Connect(function()
					nameLabel.Text = targetPlayer.Name:upper()
				end)

				nameLabel.MouseLeave:Connect(function()
					nameLabel.Text = fullName:upper()
				end)
			end

			local crewLabel = Tab:FindFirstChild("playerCrew")
			if crewLabel then
				crewLabel.Name = "CrewLabel"
				crewLabel.BackgroundTransparency = 1

				local crewName = targetUserFolder:GetAttribute("Crew") or "None"
				crewLabel.Text = crewName:upper()

				targetUserFolder:GetAttributeChangedSignal("Crew"):Connect(function()
					task.wait(0.1) -- Small delay to prevent spam
					PlayerListClient:RefreshPlayerList()
				end)
			end

			Tab.Parent = scrollingFrame
		end

		local function updateCanvasSize()
			scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
		end

		UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
		task.defer(updateCanvasSize)
	end

	function PlayerListClient:SetupUI()
		local UI = PlayerGui:WaitForChild("UI")
		local PlayerListFrame = UI:WaitForChild("PlayerListFrame")
		local ToggleButton = UI:WaitForChild("PlayerListToggle")

		local mainLayout = PlayerListFrame:FindFirstChildOfClass("UIListLayout")
		if not mainLayout then
			mainLayout = Instance.new("UIListLayout")
			mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
			mainLayout.Padding = UDim.new(0, -5)
			mainLayout.FillDirection = Enum.FillDirection.Vertical
			mainLayout.Parent = PlayerListFrame
		else
			mainLayout.Padding = UDim.new(0, -5)
		end

		local PirateSection = PlayerListFrame:FindFirstChild("PirateSection")
		local MarineSection = PlayerListFrame:FindFirstChild("MarineSection")
		local CivilianSection = PlayerListFrame:FindFirstChild("CivilianSection")
		local RevSection = PlayerListFrame:FindFirstChild("RevSection")

		if PirateSection then PirateSection.LayoutOrder = 1 end
		if MarineSection then MarineSection.LayoutOrder = 2 end
		if CivilianSection then CivilianSection.LayoutOrder = 3 end
		if RevSection then RevSection.LayoutOrder = 4 end


		for _, section in ipairs({PirateSection, MarineSection, CivilianSection, RevSection}) do
			if section then
				
				local sectionLayout = section:FindFirstChildOfClass("UIListLayout")
				if not sectionLayout then
					sectionLayout = Instance.new("UIListLayout")
					sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
					sectionLayout.Padding = UDim.new(0, 2)
					sectionLayout.FillDirection = Enum.FillDirection.Vertical
					sectionLayout.Parent = section
				else
					sectionLayout.Padding = UDim.new(0, 2)
				end

				local countLabel = section.CountFrame:FindFirstChild("CountLabel")
				local playerList = section:FindFirstChild("PlayerList")

				if countLabel then countLabel.LayoutOrder = 1 end
				if playerList then 
					playerList.LayoutOrder = 2
					
					playerList.ClipsDescendants = true
				end
			end
		end

		local maid = {}

		maid[#maid + 1] = ToggleButton.Activated:Connect(function()
			PlayerListFrame.Visible = not PlayerListFrame.Visible
			if PlayerListFrame.Visible then
				PlayerListClient:RefreshPlayerList()
			end
		end)

		PlayerListFrame.Visible = true

		UI.AncestryChanged:Connect(function(_, parent)
			if not parent then 
				for _, connection in maid do
					connection:Disconnect()
				end
			end
		end)
	end

	function PlayerListClient:BindNetworkEvents()
		
		Network:bindEvent("PlayerListUpdate", function()
			PlayerListClient:RefreshPlayerList()
		end)

		Players.PlayerRemoving:Connect(function(plr)
			PlayerListClient:RefreshPlayerList()
		end)

		Players.PlayerAdded:Connect(function(plr)
			task.wait(2) 
			PlayerListClient:RefreshPlayerList()
		end)
	end

	function PlayerListClient:Init()
		PlayerListClient:BindNetworkEvents()
		PlayerListClient:SetupUI()

		task.spawn(function()
			while task.wait(5) do
				if PlayerGui:FindFirstChild("UI") then
					local PlayerListFrame = PlayerGui.UI:FindFirstChild("PlayerListFrame")
					if PlayerListFrame and PlayerListFrame.Visible then
						PlayerListClient:RefreshPlayerList()
					end
				end
			end
		end)
	end

	return PlayerListClient
end