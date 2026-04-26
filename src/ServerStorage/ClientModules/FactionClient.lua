return function(Client)
	local FactionClient = {}
	local player = Client.player
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local PlayerGui = player:WaitForChild("PlayerGui")
	local FactionController = require(Nodes.Gameplay.FactionController)(Client)

	local maid = {}

	function FactionClient:SetupFactionSelection()
		local UI = PlayerGui:WaitForChild("UI")
		local FactionFrame = UI:FindFirstChild("FactionFrame")
		if not FactionFrame then return end

		local pirateBtn = FactionFrame:FindFirstChild("pirateBtn")
		local marineBtn = FactionFrame:FindFirstChild("marineBtn")
		local revBtn = FactionFrame:FindFirstChild("revBtn")

		if pirateBtn then
			maid[#maid + 1] = pirateBtn.MouseButton1Click:Connect(function()
				FactionController.JoinFaction("Pirate")
			end)
		end

		if marineBtn then
			maid[#maid + 1] = marineBtn.MouseButton1Click:Connect(function()
				FactionController.JoinFaction("Marine")
			end)
		end

		if revBtn then
			maid[#maid + 1] = revBtn.MouseButton1Click:Connect(function()
				FactionController.JoinFaction("Revolutionary")
			end)
		end

		UI.AncestryChanged:Connect(function(_, parent)
			if not parent then
				for _, conn in maid do
					if typeof(conn) == "RBXScriptConnection" then
						conn:Disconnect()
					end
				end
			end
		end)
	end

	function FactionClient:UpdateDisplay()
		local state = FactionController.GetState()
		local UI = PlayerGui:FindFirstChild("UI")
		if not UI then return end

		local FactionFrame = UI:FindFirstChild("FactionFrame")
		if not FactionFrame then return end

		local factionLabel = FactionFrame:FindFirstChild("factionLabel")
		if factionLabel then
			factionLabel.Text = state.DisplayName
		end

		local rankLabel = FactionFrame:FindFirstChild("rankLabel")
		if rankLabel then
			rankLabel.Text = state.LevelRank
		end

		local bountyLabel = FactionFrame:FindFirstChild("bountyLabel")
		if bountyLabel then
			bountyLabel.Text = "Bounty: " .. tostring(state.Bounty)
		end
	end

	function FactionClient:ConnectSignals()
		
		maid[#maid + 1] = FactionController.FactionChanged:Connect(function(factionId, displayName)
			local UI = PlayerGui:FindFirstChild("UI")
			if not UI then return end

			local FactionFrame = UI:FindFirstChild("FactionFrame")
			if not FactionFrame then return end

			local factionLabel = FactionFrame:FindFirstChild("factionLabel")
			if factionLabel then
				factionLabel.Text = displayName
			end

			print(`[FactionClient] Faction changed to: {displayName}`)
		end)

		maid[#maid + 1] = FactionController.LevelRankChanged:Connect(function(newRank, newLevel)
			local UI = PlayerGui:FindFirstChild("UI")
			if not UI then return end

			local FactionFrame = UI:FindFirstChild("FactionFrame")
			if not FactionFrame then return end

			local rankLabel = FactionFrame:FindFirstChild("rankLabel")
			if rankLabel then
				rankLabel.Text = newRank
			end

			print(`[FactionClient] Rank changed to: {newRank} (Level {newLevel})`)
		end)

		maid[#maid + 1] = FactionController.BountyChanged:Connect(function(newBounty, bountyRank)
			local UI = PlayerGui:FindFirstChild("UI")
			if not UI then return end

			local FactionFrame = UI:FindFirstChild("FactionFrame")
			if not FactionFrame then return end

			local bountyLabel = FactionFrame:FindFirstChild("bountyLabel")
			if bountyLabel then
				bountyLabel.Text = "Bounty: " .. tostring(newBounty)
			end

			print(`[FactionClient] Bounty changed to: {newBounty} ({bountyRank})`)
		end)
	end

	function FactionClient:Init()
		FactionClient:SetupFactionSelection()
		FactionClient:ConnectSignals()
		FactionClient:UpdateDisplay()
	end

	function FactionClient:Destroy()
		for _, conn in maid do
			if typeof(conn) == "RBXScriptConnection" then
				conn:Disconnect()
			elseif typeof(conn) == "table" and conn.Disconnect then
				conn:Disconnect()
			end
		end
		table.clear(maid)
	end

	return FactionClient
end