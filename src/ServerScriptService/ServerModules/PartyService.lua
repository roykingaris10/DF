local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Wait for framework to be ready
local OkFramework = ServerScriptService:WaitForChild("OkFramework")
local Server = require(OkFramework)

local PartyService = {}

local Parties = {}
local PlayerToParty = {}
local PendingInvites = {}

local MAX_PARTY_SIZE = 6
local INVITE_TIMEOUT = 30

local PARTY_COLORS = {
	Color3.fromRGB(255, 100, 100),
	Color3.fromRGB(100, 255, 100),
	Color3.fromRGB(100, 100, 255),
	Color3.fromRGB(255, 255, 100),
	Color3.fromRGB(255, 100, 255),
	Color3.fromRGB(100, 255, 255),
}

local function generatePartyId()
	return tostring(tick()) .. "_" .. tostring(math.random(10000, 99999))
end

local function broadcastPartyUpdate(party)
	local memberData = {}
	for i, member in ipairs(party.members) do
		local character = member.Character
		local health, maxHealth = 100, 100
		if character then
			health = character:GetAttribute("Health") or 100
			maxHealth = character:GetAttribute("MaxHealth") or 100
		end

		table.insert(memberData, {
			userId = member.UserId,
			name = member.Name,
			displayName = member.DisplayName,
			isLeader = member == party.leader,
			color = PARTY_COLORS[i],
			health = health,
			maxHealth = maxHealth,
		})
	end

	for _, member in ipairs(party.members) do
		Server.Network:post("PartyUpdated", member, {
			partyId = party.id,
			members = memberData,
			leaderId = party.leader.UserId,
		})
	end
end

local function removeFromParty(player, silent)
	local partyId = PlayerToParty[player]
	if not partyId then return end

	local party = Parties[partyId]
	if not party then
		PlayerToParty[player] = nil
		return
	end

	local playerName = player.Name
	local index = table.find(party.members, player)
	if index then
		table.remove(party.members, index)
	end

	PlayerToParty[player] = nil

	if not silent then
		Server.Network:post("RemovedFromParty", player)
	end

	if #party.members == 0 then
		Parties[partyId] = nil
		return
	end

	if party.leader == player then
		party.leader = party.members[1]

		for _, member in ipairs(party.members) do
			Server.Network:post("PartyLeaderChanged", member, party.leader.Name)
		end
	end

	broadcastPartyUpdate(party)

	for _, member in ipairs(party.members) do
		Server.Network:post("PartyMemberLeft", member, playerName)
	end
end

function PartyService.CreateParty(player)
	if PlayerToParty[player] then
		return { success = false, message = "You are already in a party" }
	end

	local partyId = generatePartyId()

	local party = {
		id = partyId,
		leader = player,
		members = { player },
		createdAt = tick(),
	}

	Parties[partyId] = party
	PlayerToParty[player] = partyId

	broadcastPartyUpdate(party)

	return { success = true, partyId = partyId }
end

function PartyService.InvitePlayer(inviter, targetName)
	-- FIRST: Find target player and validate BEFORE creating party
	local targetPlayer = nil
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower() == targetName:lower() or plr.DisplayName:lower() == targetName:lower() then
			targetPlayer = plr
			break
		end
	end

	if not targetPlayer then
		Server.Network:post("PartyInviteError", inviter, "Player not found")
		return
	end

	-- Check self-invite BEFORE creating party
	if targetPlayer == inviter then
		Server.Network:post("PartyInviteError", inviter, "You cannot invite yourself")
		return
	end

	-- Check if target is already in a party BEFORE creating party
	if PlayerToParty[targetPlayer] then
		Server.Network:post("PartyInviteError", inviter, targetPlayer.Name .. " is already in a party")
		return
	end

	-- NOW create party if inviter isn't in one
	local partyId = PlayerToParty[inviter]

	if not partyId then
		local result = PartyService.CreateParty(inviter)
		if not result.success then
			Server.Network:post("PartyInviteError", inviter, result.message)
			return
		end
		partyId = result.partyId
	end

	local party = Parties[partyId]

	if party.leader ~= inviter then
		Server.Network:post("PartyInviteError", inviter, "Only the party leader can invite players")
		return
	end

	if #party.members >= MAX_PARTY_SIZE then
		Server.Network:post("PartyInviteError", inviter, "Party is full (max " .. MAX_PARTY_SIZE .. " members)")
		return
	end

	if PendingInvites[inviter] and PendingInvites[inviter].target == targetPlayer then
		Server.Network:post("PartyInviteError", inviter, "Already sent an invite to " .. targetPlayer.Name)
		return
	end

	PendingInvites[inviter] = {
		target = targetPlayer,
		partyId = partyId,
		timestamp = tick(),
	}

	Server.Network:post("PartyInviteReceived", targetPlayer, inviter.Name, inviter.UserId)
	Server.Network:post("PartyNotification", inviter, "Invite sent to " .. targetPlayer.Name)

	task.delay(INVITE_TIMEOUT, function()
		if PendingInvites[inviter] and PendingInvites[inviter].target == targetPlayer then
			PendingInvites[inviter] = nil
			Server.Network:post("PartyInviteResult", inviter, targetPlayer.Name, false, "expired")
		end
	end)
end

function PartyService.HandleInviteResponse(player, inviterName, accepted)
	local inviter = nil
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name == inviterName then
			inviter = plr
			break
		end
	end

	if not inviter or not PendingInvites[inviter] or PendingInvites[inviter].target ~= player then
		return
	end

	local inviteData = PendingInvites[inviter]
	PendingInvites[inviter] = nil

	if not accepted then
		Server.Network:post("PartyInviteResult", inviter, player.Name, false, "declined")
		return
	end

	local party = Parties[inviteData.partyId]
	if not party then
		Server.Network:post("PartyInviteError", player, "Party no longer exists")
		return
	end

	if #party.members >= MAX_PARTY_SIZE then
		Server.Network:post("PartyInviteError", player, "Party is now full")
		Server.Network:post("PartyInviteResult", inviter, player.Name, false, "party_full")
		return
	end

	if PlayerToParty[player] then
		Server.Network:post("PartyInviteError", player, "You are already in a party")
		return
	end

	table.insert(party.members, player)
	PlayerToParty[player] = party.id

	for _, member in ipairs(party.members) do
		if member ~= player then
			Server.Network:post("PartyMemberJoined", member, player.Name)
		end
	end

	Server.Network:post("PartyInviteResult", inviter, player.Name, true)

	broadcastPartyUpdate(party)
end

function PartyService.KickPlayer(leader, targetUserId)
	local partyId = PlayerToParty[leader]
	if not partyId then return end

	local party = Parties[partyId]
	if not party or party.leader ~= leader then
		Server.Network:post("PartyInviteError", leader, "Only the party leader can kick members")
		return
	end

	local targetPlayer = nil
	for _, member in ipairs(party.members) do
		if member.UserId == targetUserId then
			targetPlayer = member
			break
		end
	end

	if not targetPlayer then return end

	if targetPlayer == leader then
		Server.Network:post("PartyInviteError", leader, "You cannot kick yourself")
		return
	end

	local targetName = targetPlayer.Name
	removeFromParty(targetPlayer, false)
	Server.Network:post("PartyNotification", targetPlayer, "You have been kicked from the party")

	for _, member in ipairs(party.members) do
		Server.Network:post("PartyNotification", member, targetName .. " was kicked from the party")
	end
end

function PartyService.LeaveParty(player)
	removeFromParty(player, false)
end

function PartyService.TransferLeadership(leader, targetUserId)
	local partyId = PlayerToParty[leader]
	if not partyId then return end

	local party = Parties[partyId]
	if not party or party.leader ~= leader then
		Server.Network:post("PartyInviteError", leader, "Only the party leader can transfer leadership")
		return
	end

	local targetPlayer = nil
	for _, member in ipairs(party.members) do
		if member.UserId == targetUserId then
			targetPlayer = member
			break
		end
	end

	if not targetPlayer or targetPlayer == leader then return end

	party.leader = targetPlayer

	for _, member in ipairs(party.members) do
		Server.Network:post("PartyLeaderChanged", member, targetPlayer.Name)
	end

	broadcastPartyUpdate(party)
end

function PartyService.GetPartyState(player)
	local partyId = PlayerToParty[player]
	if not partyId then
		return { inParty = false }
	end

	local party = Parties[partyId]
	if not party then
		PlayerToParty[player] = nil
		return { inParty = false }
	end

	local memberData = {}
	for i, member in ipairs(party.members) do
		local character = member.Character
		local health, maxHealth = 100, 100
		if character then
			health = character:GetAttribute("Health") or 100
			maxHealth = character:GetAttribute("MaxHealth") or 100
		end

		table.insert(memberData, {
			userId = member.UserId,
			name = member.Name,
			displayName = member.DisplayName,
			isLeader = member == party.leader,
			color = PARTY_COLORS[i],
			health = health,
			maxHealth = maxHealth,
		})
	end

	return {
		inParty = true,
		partyId = party.id,
		members = memberData,
		leaderId = party.leader.UserId,
		isLeader = party.leader == player,
	}
end

function PartyService.GetPartyMembers(player)
	local partyId = PlayerToParty[player]
	if not partyId then return nil end

	local party = Parties[partyId]
	if not party then return nil end

	return party.members
end

-- Wait for Network to be ready then bind
task.spawn(function()
	while not Server.Network do
		task.wait(0.1)
	end

	-- Bind event handlers
	Server.Network:bindEvent("PartyInvite", function(player, targetName)
		PartyService.InvitePlayer(player, targetName)
	end)

	Server.Network:bindEvent("PartyInviteResponse", function(player, inviterName, accepted)
		PartyService.HandleInviteResponse(player, inviterName, accepted)
	end)

	Server.Network:bindEvent("PartyKick", function(player, targetUserId)
		PartyService.KickPlayer(player, targetUserId)
	end)

	Server.Network:bindEvent("PartyLeave", function(player)
		PartyService.LeaveParty(player)
	end)

	Server.Network:bindEvent("PartyTransferLeader", function(player, targetUserId)
		PartyService.TransferLeadership(player, targetUserId)
	end)

	-- Bind function handlers
	Server.Network:bindFunction("PartyCreate", function(player)
		return PartyService.CreateParty(player)
	end)

	Server.Network:bindFunction("PartyGetState", function(player)
		return PartyService.GetPartyState(player)
	end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	PendingInvites[player] = nil

	for inviter, data in pairs(PendingInvites) do
		if data.target == player then
			PendingInvites[inviter] = nil
		end
	end

	removeFromParty(player, true)
end)

return PartyService