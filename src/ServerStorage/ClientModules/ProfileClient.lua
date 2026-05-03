return function(Client)
	local ProfileClient = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local CharacterCustomizationInfo = Client.CharacterCustomizationInfo
	local RaceChances = Client.RaceChances
	local TweenService = game:GetService('TweenService')
	local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
	local MarketplaceService = game:GetService("MarketplaceService")
	local RunService = game:GetService("RunService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local GameSettings = require(Nodes.Data.GameSettings)
	
	local BoatTween = require(Nodes.Utility.BoatTween)
	local EnhancedTypewriter = require(Nodes.Utility.EnhancedTypewriter)
	local PlayerGui = player:WaitForChild('PlayerGui')
	
	local profileConns = {}
	ProfileClient.selectedPage = "Profile"

	local function ilerp(value, minimum, maximum) 
		return (value - minimum) / (maximum - minimum)
	end
	
	function ProfileClient:SetupProfile()
		local UserFolder = player.StatFolder.UserFolder
		local UI = PlayerGui:WaitForChild("UI")
		local ProfileFrame = UI.QuestLogFrame.ProfileFrame
		
		local ProfilePage = ProfileFrame.ProfilePage
		local SummaryPage = ProfileFrame.SummaryPage
		local DreamsPage = ProfileFrame.DreamsPage
		
		ProfilePage.Visible = true
		SummaryPage.Visible = false
		DreamsPage.Visible = false
		ProfileFrame.marker.Position = UDim2.fromScale(0.225,0.045)
		
		local FullName = UserFolder:GetAttribute("FirstName").." "..(UserFolder:GetAttribute("MiddleName").." " or " ")..UserFolder:GetAttribute("LastName")
		ProfileFrame.playerName.Text = (FullName):upper()
		
		for i, button in pairs(ProfileFrame.btnFrame:GetChildren()) do
			if not button:IsA("ImageButton") then continue end

			button.MouseEnter:Connect(function()
				local enterTween = TweenService:Create(button.ImageLabel,TweenInfo.new(0.2),{ImageTransparency = 0}):Play()
			end)

			button.MouseLeave:Connect(function()
				local leaveTween = TweenService:Create(button.ImageLabel,TweenInfo.new(0.2),{ImageTransparency = 1}):Play()
			end)

			button.Activated:Connect(function()
				local activeTween = TweenService:Create(button,TweenInfo.new(0.15,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,true),{ImageColor3 = Color3.fromRGB(255, 238, 155)})
				activeTween:Play()
				if ProfileClient.selectedPage ~= button.Name then 
					self:closePage(ProfileClient.selectedPage)
					local OldTab = ProfileFrame.btnFrame[ProfileClient.selectedPage]

					local markerXPosition = {
						Profile = 0.225, Summary = 0.5, Dreams = 0.78
					}

					local markerTween = TweenService:Create(ProfileFrame.marker,TweenInfo.new(0.2,Enum.EasingStyle.Sine),{Position = UDim2.fromScale(markerXPosition[button.Name],0.045)})
					markerTween:Play()

					if button.Name == "Profile" then
						self:openProfilePage()
					elseif button.Name == "Summary" then
						self:openSummaryPage()
					elseif button.Name == "Dreams" then
						self:openDreamsPage()
					end
					ProfileClient.selectedPage = button.Name
				end
			end)
		end
	end
	
	function ProfileClient:OpenProfile()
		local UserFolder = player.StatFolder.UserFolder
		local UI = PlayerGui:WaitForChild("UI")
		local ProfileFrame = UI.QuestLogFrame.ProfileFrame

		local ProfilePage = ProfileFrame.ProfilePage
		local SummaryPage = ProfileFrame.SummaryPage
		local DreamsPage = ProfileFrame.DreamsPage
		
		if ProfileClient.selectedPage == "Profile" then
			self:openProfilePage()
		elseif ProfileClient.selectedPage == "Summary" then
			self:openSummaryPage()
		elseif ProfileClient.selectedPage == "Dreams" then
			self:openDreamsPage()
		end
		Client.InventoryClient:VisibleToolbar(true)
	end
	
	function ProfileClient:CloseProfile()
		local UserFolder = player.StatFolder.UserFolder
		local UI = PlayerGui:WaitForChild("UI")
		local ProfileFrame = UI.QuestLogFrame.ProfileFrame

		local ProfilePage = ProfileFrame.ProfilePage
		local SummaryPage = ProfileFrame.SummaryPage
		local DreamsPage = ProfileFrame.DreamsPage
		
		self:closePage(ProfileClient.selectedPage)
		Client.InventoryClient:VisibleToolbar(false)
	end
	
	function ProfileClient:openProfilePage()
		
		local UserFolder = player.StatFolder.UserFolder
		local UI = PlayerGui.UI
		local ProfileFrame = UI.QuestLogFrame.ProfileFrame
		local infoFrame = ProfileFrame.ProfilePage.playerFrame

		for i, object in pairs(ProfileFrame.ProfilePage:GetDescendants()) do
			if object:GetAttribute("IGNORE") == true then continue end
			if object:IsA("ImageLabel") or object:IsA("ImageButton") then 
				object.ImageTransparency = 1
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad),{ImageTransparency = val})
				transTween:Play()
			elseif object:IsA("TextLabel") then
				object.TextTransparency = 1 
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad),{TextTransparency = val})
				transTween:Play()
			elseif object:IsA("UIStroke") then
				object.Transparency = 1
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad),{Transparency = val})
				transTween:Play()
			end
		end

		pcall(function()
			infoFrame.playerRank.RankValue.Text = tostring(UserFolder:GetAttribute("FactionRank"))
			infoFrame.playerBounty.BountyValue.Text = tostring(UserFolder:GetAttribute("Beli")).." Beli" -- FOR BOUNTY
			infoFrame.playerCrew.CrewValue.Text = tostring(UserFolder:GetAttribute("Crew"))
			ProfileFrame.ProfilePage.statPointsText.Text = tostring(UserFolder:GetAttribute("StatPoints"))
		end)

		profileConns.fctrank = UserFolder:GetAttributeChangedSignal("FactionRank"):Connect(function()
			pcall(function() infoFrame.playerRank.RankValue.Text = tostring(UserFolder:GetAttribute("FactionRank")) end)
		end)

		profileConns.bounty = UserFolder:GetAttributeChangedSignal("Bounty"):Connect(function()
			pcall(function() infoFrame.playerBounty.BountyValue.Text = tostring(UserFolder:GetAttribute("Beli")) .." Beli" end) -- FOR BOUNTY 
		end)

		profileConns.crew = UserFolder:GetAttributeChangedSignal("Crew"):Connect(function()
			pcall(function() infoFrame.playerCrew.CrewValue.Text = tostring(UserFolder:GetAttribute("Crew"))  end)
		end)

		profileConns.statpnts = UserFolder:GetAttributeChangedSignal("StatPoints"):Connect(function()
			pcall(function() ProfileFrame.ProfilePage.statPointsText.Text = tostring(UserFolder:GetAttribute("StatPoints")):upper()  end)
		end)

		local statTable = {"Strength","Vitality","Dexterity","Cognition","Will","Haki"}

		for i = 1,6 do 
			ProfileFrame.ProfilePage.statFrame[statTable[i]].statValue.Text = tostring(UserFolder:GetAttribute(statTable[i]))
			local XSize = ilerp(tostring(UserFolder:GetAttribute(statTable[i])),0,GameSettings.StatMax)
			ProfileFrame.ProfilePage.statFrame[statTable[i]].back.bar.Size = UDim2.new(XSize,0,1,0)
			profileConns[1+#profileConns] = UserFolder:GetAttributeChangedSignal(statTable[i]):Connect(function()
				ProfileFrame.ProfilePage.statFrame[statTable[i]].statValue.Text = tostring(UserFolder:GetAttribute(statTable[i]))
				local XSize = ilerp(tostring(UserFolder:GetAttribute(statTable[i])),0,GameSettings.StatMax)
				ProfileFrame.ProfilePage.statFrame[statTable[i]].back.bar.Size = UDim2.new(XSize,0,1,0)
			end)
		end

		for i = 1,6 do
			local statFrame = ProfileFrame.ProfilePage.statFrame[statTable[i]]
			profileConns[1+#profileConns] = statFrame.addsubFrame.add.MouseEnter:Connect(function()
				local enterTween = TweenService:Create(statFrame.addsubFrame.add,TweenInfo.new(0.2),{ImageColor3 = Color3.fromRGB(255, 203, 80),Size = UDim2.new(1.06,0,1.06,0)})
				enterTween:Play()
			end)

			profileConns[1+#profileConns] = statFrame.addsubFrame.add.MouseLeave:Connect(function()
				local leaveTween = TweenService:Create(statFrame.addsubFrame.add,TweenInfo.new(0.2),{ImageColor3 = Color3.fromRGB(255, 255, 255),Size = UDim2.new(1,0,1,0)})
				leaveTween:Play()
			end)

			profileConns[1+#profileConns] = statFrame.addsubFrame.add.Activated:Connect(function()
				local activeTween = TweenService:Create(statFrame.addsubFrame.add,TweenInfo.new(0.15,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,true),{ImageColor3 = Color3.fromRGB(119, 255, 117)})
				activeTween:Play()
			end)

			profileConns[1+#profileConns] = statFrame.addsubFrame.subtract.MouseEnter:Connect(function()
				local enterTween = TweenService:Create(statFrame.addsubFrame.subtract,TweenInfo.new(0.2),{ImageColor3 = Color3.fromRGB(255, 203, 80),Size = UDim2.new(1.06,0,1.06,0)})
				enterTween:Play()
			end)

			profileConns[1+#profileConns] = statFrame.addsubFrame.subtract.MouseLeave:Connect(function()
				local leaveTween = TweenService:Create(statFrame.addsubFrame.subtract,TweenInfo.new(0.2),{ImageColor3 = Color3.fromRGB(255, 255, 255),Size = UDim2.new(1,0,1,0)})
				leaveTween:Play()
			end)

			profileConns[1+#profileConns] = statFrame.addsubFrame.subtract.Activated:Connect(function()
				local activeTween = TweenService:Create(statFrame.addsubFrame.subtract,TweenInfo.new(0.15,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,true),{ImageColor3 = Color3.fromRGB(255, 26, 26)})
				activeTween:Play()
			end)
		end

		profileConns.profenter = ProfileFrame.ProfilePage.ProfessionLabel.MouseEnter:Connect(function()
			ProfileFrame.ProfilePage.ProfessionInfo.Visible = true
		end)

		profileConns.profleave = ProfileFrame.ProfilePage.ProfessionLabel.MouseLeave:Connect(function()
			ProfileFrame.ProfilePage.ProfessionInfo.Visible = false
		end)

		ProfileFrame.ProfilePage.Visible = true
	end
	
	function ProfileClient:openSummaryPage()
		local UI = PlayerGui.UI
		local ProfileFrame = UI.QuestLogFrame.ProfileFrame
		local Page = ProfileFrame.SummaryPage

		for i, object in pairs(Page:GetDescendants()) do
			if object:GetAttribute("IGNORE") == true then continue end
			if object:IsA("ImageLabel") or object:IsA("ImageButton")then 
				object.ImageTransparency = 1
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad),{ImageTransparency = val})
				transTween:Play()
			elseif object:IsA("TextLabel") then
				object.TextTransparency = 1 
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0.3),{TextTransparency = val})
				transTween:Play()
			elseif object:IsA("UIStroke") then
				object.Transparency = 1
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0.3),{Transparency = val})
				transTween:Play()
			end
		end

		Page.Visible = true
	end

	function ProfileClient:openDreamsPage()
		local UI = PlayerGui.UI
		local ProfileFrame = UI.QuestLogFrame.ProfileFrame
		local Page = ProfileFrame.DreamsPage

		for i, object in pairs(Page:GetDescendants()) do
			if object:GetAttribute("IGNORE") == true then continue end
			if object:IsA("ImageLabel") or object:IsA("ImageButton") then 
				object.ImageTransparency = 1
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad),{ImageTransparency = val})
				transTween:Play()
			elseif object:IsA("TextLabel") then
				object.TextTransparency = 1 
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0.3),{TextTransparency = val})
				transTween:Play()
			elseif object:IsA("UIStroke") then
				object.Transparency = 1
				local val = object:GetAttribute("Val") or 0
				local transTween = TweenService:Create(object,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0.3),{Transparency = val})
				transTween:Play()
			end
		end

		Page.Visible = true
	end
	
	function ProfileClient:closePage(Name)
		local UI = PlayerGui.UI
		local ProfileFrame = UI.QuestLogFrame.ProfileFrame
		local Page = ProfileFrame[Name.."Page"]
		Page.Visible = false
		--MAKE ALL THE STUFF FOR THE PAGE INVISIBLE SO IT CAN APPEAR SMOOTHLY
		for i, object in pairs(Page:GetDescendants()) do
			if object:GetAttribute("IGNORE") == true then continue end
			if object:IsA("ImageLabel") or object:IsA("ImageButton") then 
				object.ImageTransparency = 1
			elseif object:IsA("TextLabel") then
				object.TextTransparency = 1 
			elseif object:IsA("UIStroke") then
				object.Transparency = 1
			end
		end
		for i, v in pairs(profileConns) do
			v:Disconnect() -- disconnect connection.
		end
		profileConns = {}
	end
	

	
	
	
	return ProfileClient end

	


