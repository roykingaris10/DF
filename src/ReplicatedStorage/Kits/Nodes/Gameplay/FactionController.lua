return function(Client)
	local FactionController = {}
	local player = Client.player

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	local Signal = require(Nodes.Utility.Signal)

	FactionController.FactionChanged = Signal.new()
	FactionController.LevelRankChanged = Signal.new()
	FactionController.BountyChanged = Signal.new()
	FactionController.StateRefreshed = Signal.new()

	local factionState = {
		FactionId = "Pirate",
		DisplayName = "Pirate",
		Bounty = 0,
		BountyRank = "Unranked",
		Level = 1,
		LevelRank = "Unknown",
	}

	local function applyState(factionId, displayName, bounty, levelRank, level, bountyRankDisplay)
		local oldFactionId = factionState.FactionId
		local oldLevelRank = factionState.LevelRank
		local oldBounty = factionState.Bounty

		factionState.FactionId = factionId or "Civilian"
		factionState.DisplayName = displayName or "Civilian"
		factionState.Bounty = bounty or 0
		factionState.BountyRank = bountyRankDisplay or "Unranked"
		factionState.Level = level or 1
		factionState.LevelRank = levelRank or "Civilian"

		if oldFactionId ~= factionState.FactionId then
			FactionController.FactionChanged:Fire(factionState.FactionId, factionState.DisplayName)
		end

		if oldLevelRank ~= factionState.LevelRank then
			FactionController.LevelRankChanged:Fire(factionState.LevelRank, factionState.Level)
		end

		if oldBounty ~= factionState.Bounty then
			FactionController.BountyChanged:Fire(factionState.Bounty, factionState.BountyRank)
		end

		FactionController.StateRefreshed:Fire(factionState)
	end

	function FactionController.GetState()
		return factionState
	end

	function FactionController.RefreshState()
		local success, factionId, displayName, bounty, levelRank, level, bountyRankDisplay = Client.PacketLinks.GetFactionState:Fire()
		if success then
			applyState(factionId, displayName, bounty, levelRank, level, bountyRankDisplay)
		end
		return factionState
	end

	function FactionController.JoinFaction(factionId: string)
		local success, displayNameOrError, levelRank = Client.PacketLinks.JoinFaction:Fire(factionId)
		if success then
			local oldFactionId = factionState.FactionId

			factionState.FactionId = factionId
			factionState.DisplayName = displayNameOrError
			factionState.Bounty = 0
			factionState.LevelRank = levelRank
			factionState.BountyRank = "Unranked"

			FactionController.FactionChanged:Fire(factionId, displayNameOrError)
			FactionController.LevelRankChanged:Fire(levelRank, factionState.Level)
			FactionController.BountyChanged:Fire(0, "Unranked")

			print(`[FactionController] Joined {displayNameOrError} as {levelRank}`)
		else
			warn(`Join failed: {displayNameOrError}`)
		end
		return success, displayNameOrError
	end

	function FactionController.LeaveFaction()
		local success, message = Client.PacketLinks.LeaveFaction:Fire()
		if success then
			factionState.FactionId = "Civilian"
			factionState.DisplayName = "Civilian"
			factionState.Bounty = 0
			factionState.LevelRank = "Civilian"
			factionState.BountyRank = "Unranked"

			-- Fire signals
			FactionController.FactionChanged:Fire("Civilian", "Civilian")
			FactionController.LevelRankChanged:Fire("Civilian", factionState.Level)
			FactionController.BountyChanged:Fire(0, "Unranked")

			print(message)
		else
			warn(`Leave failed: {message}`)
		end
		return success, message
	end

	-- Listen for server-sent rank ups
	Client.PacketLinks.LevelRankUp.OnClientEvent:Connect(function(newRank, newLevel)
		factionState.LevelRank = newRank
		factionState.Level = newLevel
		FactionController.LevelRankChanged:Fire(newRank, newLevel)
		print(`[FactionController] Level Rank Up: {newRank} (Level: {newLevel})`)
	end)

	-- Initial state fetch
	FactionController.RefreshState()

	return FactionController
end