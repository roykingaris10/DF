return function(Client)

	local CrewClient = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local TweenService = game:GetService('TweenService')
	local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
	local ContextActionService = game:GetService("ContextActionService")
	local Players = game:GetService("Players")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local PlayerGui = player:WaitForChild('PlayerGui')
	local CrewController = require(Nodes.Gameplay.CrewController)(Client)

	local activeInvite = nil

	function CrewClient:CreateToggle()

		local UI = PlayerGui:WaitForChild("UI")
		local CrewFrame = UI.CrewFrame
		local CreateButton = CrewFrame.CreateButton
		local maid = {}

		maid[#maid + 1] = CreateButton.Activated:Connect(function()
			local crewName = CrewFrame.CrewNameBox.Text

			crewName = crewName:gsub("^%s+", ""):gsub("%s+$", "")

			if crewName == "" then
				warn("Please enter a crew name first")
				return
			end
			CrewController.CreateCrew(crewName)
		end)

		PlayerGui.UI.AncestryChanged:Connect(function(_, parent)
			if not parent then 
				for _, connection in maid do
					connection:Disconnect()
				end
			end
		end)
	end

	function CrewClient:OpenToggle()

		local UI = PlayerGui:WaitForChild("UI")
		local CrewFrame = UI.CrewFrame
		local OpenButton = UI.CrewOpenButton
		local maid = {}

		maid[#maid + 1] = OpenButton.Activated:Connect(function()
			CrewFrame.Visible = not CrewFrame.Visible
		end)

		PlayerGui.UI.AncestryChanged:Connect(function(_, parent)
			if not parent then 
				for _, connection in maid do
					connection:Disconnect()
				end
			end
		end)
	end

	function CrewClient:CrewInfo()

		local UI = PlayerGui:WaitForChild("UI")
		local CrewInfoFrame = UI.CrewInfoFrame
		local OpenButton = UI.CrewInfoButton
		local InviteButton = UI.CrewInfoFrame.CrewInviteButton
		local InviteBox = UI.CrewInfoFrame.CrewInviteBox
		local InvitePrompt = UI:WaitForChild("InvitePrompt")
		local AutofillText = CrewInfoFrame:WaitForChild("autoFillText")
		local notiFrame = UI.topBtns:WaitForChild("noti")
		

		local maid = {}
		local currentMatch = nil

		print("[CrewClient] CrewInfo initialized")

		local function findMatch(text)
			if text == "" then return nil end

			local lowerText = text:lower()
			for _, plr in ipairs(Players:GetPlayers()) do
				-- if plr ~= player then
				local playerName = plr.Name
				if playerName:lower():sub(1, #text) == lowerText then
					return playerName
				end
				-- end
			end
			return nil
		end

		local function updateShadowText()
			local text = InviteBox.Text
			currentMatch = findMatch(text)

			if currentMatch then

		local typed = text
				local suffix = ""

				if #typed < #currentMatch then
					suffix = currentMatch:sub(#typed + 1)
				end

				AutofillText.Text = typed .. suffix
				AutofillText.Visible = true
			else
				AutofillText.Text = ""
				AutofillText.Visible = false
			end
		end

		maid[#maid + 1] = InviteBox:GetPropertyChangedSignal("Text"):Connect(function()
			updateShadowText()
		end)

		maid[#maid + 1] = InviteBox.Focused:Connect(function()
			updateShadowText()
		end)

		maid[#maid + 1] = InviteBox.FocusLost:Connect(function()
			AutofillText.Visible = false
		end)

		local function onTabComplete(actionName, inputState, input)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end

			if InviteBox:IsFocused() and currentMatch then
				InviteBox.Text = currentMatch
				AutofillText.Visible = false

				InviteBox.CursorPosition = #InviteBox.Text + 1

				return Enum.ContextActionResult.Sink 
			end

			return Enum.ContextActionResult.Pass
		end

		ContextActionService:BindAction(
			"CrewInviteTabComplete",
			onTabComplete,
			false,
			Enum.KeyCode.Tab
		)

		maid[#maid + 1] = OpenButton.Activated:Connect(function()
			CrewInfoFrame.Visible = not CrewInfoFrame.Visible
		end)

		maid[#maid + 1] = InviteButton.Activated:Connect(function()

			local playerInvited = InviteBox.Text
			playerInvited = playerInvited:gsub("^%s+", ""):gsub("%s+$", "")

			if playerInvited == "" then
				self:ShowError("Please enter a player name")
				return
			end

			Network:post("CrewInviteRequest", playerInvited)

			InviteBox.Text = ""
			AutofillText.Visible = false
			
			for _, v in pairs(notiFrame:GetChildren())  do
				if v:IsA("Frame") or v:IsA("ImageLabel") or v:IsA("TextLabel") then
					v.Visible = true
					task.spawn(function()
						if v:IsA("Frame") then
							TweenService:Create(v, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, math.huge, false, 0),
								{Size = UDim2.new(0.53,0,0.53,0), BackgroundTransparency = 0}):Play()
						end
					end)
				end
			end
		
			
			self:ShowSuccess("Invite sent!")
			
			
			
		end)

		maid[#maid + 1] = InvitePrompt.acceptButton.Activated:Connect(function()
			self:RespondToInvite(true)
		end)

		maid[#maid + 1] = InvitePrompt.declineButton.Activated:Connect(function()
			self:RespondToInvite(false)
		end)

		PlayerGui.UI.AncestryChanged:Connect(function(_, parent)
			if not parent then 
				for _, connection in maid do
					connection:Disconnect()
				end
				
				ContextActionService:UnbindAction("CrewInviteTabComplete")
			end
		end)
	end

	function CrewClient:BindNetworkEvents()
		
		Network:bindEvent("CrewInviteReceived", function(inviterName)
			self:ShowInvitePrompt(inviterName)
		end)

		Network:bindEvent("CrewInviteError", function(errorMessage)
			self:ShowError(errorMessage)
		end)

		Network:bindEvent("CrewInviteResult", function(targetPlayerName, accepted)
			if accepted then
				self:ShowSuccess(`{targetPlayerName} has joined your crew!`)
			else
				self:ShowError(`{targetPlayerName} declined your invite`)
			end
		end)

		Network:bindEvent("CrewInviteAccepted", function(inviterName)
			self:ShowSuccess(`You joined {inviterName}'s crew!`)
			
			CrewController.GetCrewState()
		end)
	end

	function CrewClient:ShowInvitePrompt(inviterName)
		local UI = PlayerGui.UI
		local InvitePrompt = UI.InvitePrompt

		activeInvite = inviterName

		InvitePrompt.inviteText.Text = `{inviterName} has invited you to join their crew.`
		InvitePrompt.Visible = true
	end

	function CrewClient:RespondToInvite(accepted)
		local UI = PlayerGui.UI
		local InvitePrompt = UI.InvitePrompt

		if not activeInvite then
			warn("No active invite to respond to")
			return
		end

		InvitePrompt.Visible = false

		Network:post("CrewInviteResponse", activeInvite, accepted)

		activeInvite = nil
	end

	function CrewClient:ShowError(message)
		local UI = PlayerGui.UI
		local RejectPrompt = UI.rejectPrompt

		RejectPrompt.Text = message
		RejectPrompt.TextColor3 = Color3.fromRGB(255, 100, 100)
		RejectPrompt.Visible = true

		task.delay(3, function()
			if RejectPrompt.Text == message then
				RejectPrompt.Visible = false
				RejectPrompt.Text = ""
			end
		end)
	end

	function CrewClient:ShowSuccess(message)
		local UI = PlayerGui.UI
		local RejectPrompt = UI.rejectPrompt

		RejectPrompt.Text = message
		RejectPrompt.TextColor3 = Color3.fromRGB(100, 255, 100)
		RejectPrompt.Visible = true

		task.delay(3, function()
			if RejectPrompt.Text == message then
				RejectPrompt.Visible = false
				RejectPrompt.Text = ""
			end
		end)
	end

	function CrewClient:CrewDisband()

		local UI = PlayerGui:WaitForChild("UI")		
		local CrewDisbandButton = UI.CrewDisbandButton
		local maid = {}

		maid[#maid + 1] = CrewDisbandButton.Activated:Connect(function()
			CrewController.DisbandCrew()
		end)

		UI.AncestryChanged:Connect(function(_, parent)
			if not parent then 
				for _, connection in maid do
					connection:Disconnect()
				end
			end
		end)
	end

	function CrewClient:CrewLeave()
		local UI = PlayerGui:WaitForChild("UI")		
		local CrewLeaveButton = UI.CrewLeaveButton
		local maid = {}

		maid[#maid + 1] = CrewLeaveButton.Activated:Connect(function()
			CrewController.LeaveCrew()
		end)

		UI.AncestryChanged:Connect(function(_, parent)
			if not parent then 
				for _, connection in maid do
					connection:Disconnect()
				end
			end
		end)
	end

	function CrewClient:Init()
		
		CrewClient:BindNetworkEvents()

		CrewClient:CreateToggle()
		CrewClient:CrewDisband()
		CrewClient:CrewLeave()
		CrewClient:OpenToggle()
		CrewClient:CrewInfo()
	end

	return CrewClient
end