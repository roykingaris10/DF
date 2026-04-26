local Server = require(script.Parent)
local Network = Server.Network
local Players = game:GetService("Players")

local FactionInfo = Server.FactionInfo

local FactionService = {}

function FactionService.GetFactionConfig(factionId: string)
	return FactionInfo.Factions[factionId]
end

function FactionService.GetLevelRank(factionId: string, level: number): string
	local levelRanks = FactionInfo.LevelRanks[factionId]
	if not levelRanks then return "Unknown" end

	local currentRank = levelRanks[1].Name

	for _, rankData in ipairs(levelRanks) do
		if level >= rankData.MinLevel then
			currentRank = rankData.Name
		else
			break
		end
	end

	return currentRank
end

function FactionService.GetNextLevelRankInfo(factionId: string, level: number)
	local levelRanks = FactionInfo.LevelRanks[factionId]
	if not levelRanks then return nil end

	for _, rankData in ipairs(levelRanks) do
		if level < rankData.MinLevel then
			return {
				Name = rankData.Name,
				RequiredLevel = rankData.MinLevel,
				Remaining = rankData.MinLevel - level,
			}
		end
	end
	return nil
end

function FactionService.GetBountyRank(player: Player): (number?, string)
	local entity = Server.EntityService.Find(player)
	if not entity then return nil, "Unranked" end

	local bounty = entity.SlotProfile.Bounty or 0

	if bounty == 0 then
		return nil, "Unranked"
	end
	return nil, "Unranked"
end

function FactionService.GetMaxBountyForLevel(level: number): number
	local maxBounty = math.huge

	for bountyThreshold, requiredLevel in pairs(FactionInfo.BountyLevelRequirements) do
		if level < requiredLevel then
			maxBounty = math.min(maxBounty, bountyThreshold - 1) 
		end
	end
	return maxBounty
end

function FactionService.CanGainBounty(level: number, currentBounty: number, bountyGain: number): (boolean, number)
	local maxBounty = FactionService.GetMaxBountyForLevel(level)
	local newBounty = currentBounty + bountyGain

	if newBounty > maxBounty then
		local clampedGain = math.max(0, maxBounty - currentBounty)
		return false, clampedGain
	end
	return true, bountyGain
end

local function updateFactionAttributes(player: Player, factionId: string, levelRank: string, bountyRankDisplay: string)
	local entity = Server.EntityService.Find(player)

	if entity and entity.SlotProfile and entity.SlotProfile.UserData then
		entity.SlotProfile.UserData.Faction = factionId
		entity.SlotProfile.UserData.FactionRank = levelRank
	end

	if player and player:FindFirstChild("StatFolder") then
		local userFolder = player.StatFolder:FindFirstChild("UserFolder")
		if userFolder then
			userFolder:SetAttribute("Faction", factionId)
			userFolder:SetAttribute("FactionRank", levelRank)
		end
	end

	player:SetAttribute("Faction", factionId)
	player:SetAttribute("FactionRank", levelRank)
	player:SetAttribute("BountyRank", bountyRankDisplay)
end

local meetsRequirements = function(entity, factionId: string): (boolean, string)
	local faction = FactionInfo.Factions[factionId]
	if not faction then return false, "Invalid faction" end

	local reqs = faction.JoinRequirements
	if not reqs then return true, "" end

	local level = entity.SlotProfile.Level or (entity.SlotProfile.UserData and entity.SlotProfile.UserData.Level) or 1
	local bounty = entity.SlotProfile.Bounty or (entity.SlotProfile.UserData and entity.SlotProfile.UserData.Bounty) or 0

	if reqs.MinLevel and level < reqs.MinLevel then
		return false, `Must be level {reqs.MinLevel} or higher`
	end

	--if reqs.MaxBounty and bounty > reqs.MaxBounty then
	--		return false, "Cannot join with an active bounty"
	--end

	return true, ""
end

function FactionService.JoinFaction(player: Player, factionId: string)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "Invalid entity", "" end

	local faction = FactionInfo.Factions[factionId]
	if not faction then
		return false, "Invalid faction", ""
	end

	local currentFaction = entity.Data.FactionData.FactionId or "Civilian"

	if currentFaction == factionId then
		return false, `Already a {faction.DisplayName}`, ""
	end

	if not faction.CanHaveCrew and (entity.Data.CrewData.CrewId or "") ~= "" then
		return false, `{faction.DisplayName}s cannot be in a pirate crew. Leave your crew first`, ""
	end

	local canJoin, reason = meetsRequirements(entity, factionId)
	if not canJoin then
		return false, reason, ""
	end

	entity.Data.FactionData.FactionId = factionId
	entity.Data.FactionData.JoinedAt = os.time()

	local level = entity.SlotProfile.Level or (entity.SlotProfile.UserData and entity.SlotProfile.UserData.Level) or 1
	local levelRank = FactionService.GetLevelRank(factionId, level)

	if entity.SlotProfile.UserData then
		entity.SlotProfile.UserData.Faction = factionId
		entity.SlotProfile.UserData.FactionRank = levelRank  -- SAVE THIS
		if currentFaction ~= "Civilian" then
			entity.SlotProfile.UserData.Bounty = 0
		end
	end

	if currentFaction ~= "Civilian" then
		entity.SlotProfile.Bounty = 0
	end

	local _, bountyRankDisplay = FactionService.GetBountyRank(player)

	entity.ProfileHolder.Profile:Save()

	updateFactionAttributes(player, factionId, levelRank, bountyRankDisplay)

	Server.PlayerListService.BroadcastUpdate()

	return true, faction.DisplayName, levelRank
end

function FactionService.LeaveFaction(player: Player)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "Entity not found" end

	local currentFaction = entity.Data.FactionData.FactionId or "Civilian"

	if currentFaction == "Civilian" then
		return false, "Already a civilian"
	end

	entity.Data.FactionData.FactionId = "Civilian"
	entity.Data.FactionData.JoinedAt = 0

	if entity.SlotProfile.UserData then
		entity.SlotProfile.UserData.Faction = "Civilian"
		entity.SlotProfile.UserData.FactionRank = "Civilian"  -- SAVE THIS
		entity.SlotProfile.UserData.Bounty = 0
	end

	entity.SlotProfile.Bounty = 0

	entity.ProfileHolder.Profile:Save()

	updateFactionAttributes(player, "Civilian", "Civilian", "Unranked")

	Server.PlayerListService.BroadcastUpdate()

	return true, "Faction left, you are now a Civilian"
end

function FactionService.AddBounty(player: Player, amount: number)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, 0 end

	local factionId = entity.Data.FactionData.FactionId or "Civilian"
	if factionId == "Civilian" then return false, 0 end

	local level = entity.SlotProfile.Level or (entity.SlotProfile.UserData and entity.SlotProfile.UserData.Level) or 1
	local currentBounty = entity.SlotProfile.Bounty or 0

	local canGain, actualGain = FactionService.CanGainBounty(level, currentBounty, amount)

	if actualGain <= 0 then
		return false, 0, "Level too low for more bounty"
	end

	entity.SlotProfile.Bounty = currentBounty + actualGain
	if entity.SlotProfile.UserData then
		entity.SlotProfile.UserData.Bounty = currentBounty + actualGain
	end

	player:SetAttribute("Bounty", entity.SlotProfile.Bounty)
	if player:FindFirstChild("StatFolder") then
		local userFolder = player.StatFolder:FindFirstChild("UserFolder")
		if userFolder then
			userFolder:SetAttribute("Bounty", entity.SlotProfile.Bounty)
		end
	end

	return true, actualGain, entity.SlotProfile.Bounty
end

function FactionService.OnLevelUp(player: Player, newLevel: number)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "Entity not found" end

	local factionId = entity.Data.FactionData.FactionId or "Civilian"

	local oldLevelRank = FactionService.GetLevelRank(factionId, newLevel - 1)
	local newLevelRank = FactionService.GetLevelRank(factionId, newLevel)

	if oldLevelRank ~= newLevelRank then
		local _, bountyRankDisplay = FactionService.GetBountyRank(player)
		updateFactionAttributes(player, factionId, newLevelRank, bountyRankDisplay)
		Server.PacketLinks.LevelRankUp:FireClient(player, newLevelRank, newLevel)
	end
end

function FactionService.AreEnemies(player1: Player, player2: Player): boolean
	local entity1 = Server.EntityService.Find(player1)
	local entity2 = Server.EntityService.Find(player2)

	if not entity1 or not entity2 then return false end

	local faction1 = entity1.Data.FactionData.FactionId or "Civilian"
	local faction2 = entity2.Data.FactionData.FactionId or "Civilian"

	local config1 = FactionInfo.Factions[faction1]
	if not config1 then return false end

	return table.find(config1.EnemyFactions, faction2) ~= nil
end

function FactionService.GetFactionState(player: Player)
	local entity = Server.EntityService.Find(player)
	if not entity then 
		return false, "Civilian", "Civilian", 0, "Civilian", 1, "Unranked"  
	end

	local factionId = entity.Data.FactionData.FactionId or FactionInfo.DefaultFaction
	local bounty = entity.SlotProfile.Bounty or 0
	local level = entity.SlotProfile.Level or (entity.SlotProfile.UserData and entity.SlotProfile.UserData.Level) or 1
	local config = FactionInfo.Factions[factionId]

	local levelRank = FactionService.GetLevelRank(factionId, level)
	local _, bountyRankDisplay = FactionService.GetBountyRank(player)

	local displayName = "Civilian"
	if config and config.DisplayName then
		displayName = config.DisplayName
	end

	return true, factionId, displayName, bounty, levelRank, level, bountyRankDisplay
end

function FactionService.InitializePlayer(player: Player)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "Entity not found" end

	if not entity.Data.FactionData then
		entity.Data.FactionData = {
			FactionId = FactionInfo.DefaultFaction,
			JoinedAt = 0,
		}
	end

	local factionId = entity.Data.FactionData.FactionId or FactionInfo.DefaultFaction
	local level = entity.SlotProfile.Level or (entity.SlotProfile.UserData and entity.SlotProfile.UserData.Level) or 1

	local levelRank = FactionService.GetLevelRank(factionId, level)
	local _, bountyRankDisplay = FactionService.GetBountyRank(player)

	if entity.SlotProfile.UserData then
		entity.SlotProfile.UserData.Faction = factionId
		entity.SlotProfile.UserData.FactionRank = levelRank
	end

	updateFactionAttributes(player, factionId, levelRank, bountyRankDisplay)
end

Server.PacketLinks.GetFactionState.OnServerInvoke = function(player)
	return FactionService.GetFactionState(player)
end

Server.PacketLinks.JoinFaction.OnServerInvoke = function(player, factionId)
	return FactionService.JoinFaction(player, factionId)
end

Server.PacketLinks.LeaveFaction.OnServerInvoke = function(player)
	return FactionService.LeaveFaction(player)
end



Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		FactionService.InitializePlayer(player)
	end)
end)

return FactionService