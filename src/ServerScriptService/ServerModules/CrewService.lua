local Server = require(script.Parent)
local Network = Server.Network

local HTTPService = game:GetService("HttpService")
local ProfileService = require(game.ServerScriptService.ProfileService)
local PacketLinks = Server.PacketLinks

local CrewStore = ProfileService.GetProfileStore("DataProfileService", {
	CrewId = "",
	CrewName = "",
	CreatedAt = 0,
	CaptainUserId = 0,
	Members = {},
	History = {}
})

local CrewService = {}
CrewService._index = CrewService
local activeCrews: { [string]: {Profile: ProfileService.Profile, Data: any}} = {}

local function generateCrewId(): string
	return HTTPService:GenerateGUID(false)
end

local SAVE_DEBOUNCE_SECONDS = 2.0

local pendingSaves = {} :: {[any]: {again: boolean}}

local function profileIsActive(profile)
	
	local ok, active = pcall(function()
		return profile:IsActive()
	end)
	return ok and active
end

local function requestSave(profile)
	if not profile then return end

	local state = pendingSaves[profile]
	if state then
		state.again = true
		return
	end

	pendingSaves[profile] = { again = false }

	task.delay(SAVE_DEBOUNCE_SECONDS, function()
		local s = pendingSaves[profile]
		pendingSaves[profile] = nil

		if not profileIsActive(profile) then
			return
		end

		local ok, err = pcall(function()
			profile:Save()
		end)
		if not ok then
			warn("[CrewService] Debounced Save failed:", err)
		end

		if s and s.again then
			requestSave(profile)
		end
	end)
end

local ACTION_COOLDOWN = {
	Create = 1.0,  
	Disband = 1.0,
	Leave = 1.0,
	Join = 1.0,
	Invite = 0.25,
}

local lastAction = {} :: {[number]: {[string]: number}}

local function rateLimit(player: Player, action: string)
	local uid = player.UserId
	lastAction[uid] = lastAction[uid] or {}
	local now = os.clock()
	local last = lastAction[uid][action] or 0
	local cd = ACTION_COOLDOWN[action] or 0

	if (now - last) < cd then
		return false, "Please wait a moment."
	end

	lastAction[uid][action] = now
	return true
end

game:GetService("Players").PlayerRemoving:Connect(function(plr)
	lastAction[plr.UserId] = nil
end)



local function loadCrew(crewId: string)
	local cached = activeCrews[crewId]
	if cached then
		if cached.Profile:IsActive() then
			return cached
		else
			activeCrews[crewId] = "" or nil
		end
	end

	if (not crewId) or (crewId == "") then return nil end

	local profile = CrewStore:LoadProfileAsync("Crew_" .. crewId, "ForceLoad")
	if not profile then
		return nil
	end

	profile:ListenToRelease(function()
		activeCrews[crewId] = nil
	end)

	local entry = {Profile = profile, Data = profile.Data}
	activeCrews[crewId] = entry
	return entry
end

local function clearCrewData(entity)
	entity.Data.CrewData.CrewId = ""
	entity.Data.CrewData.CrewName = ""
	entity.Data.CrewData.CreatedAt = 0
	entity.Data.CrewData.CaptainUserId = 0
	entity.Data.CrewData.Members = {}
	entity.Data.CrewData.History = {}
	entity.Data.CrewData.Rank = "None"
	entity.Data.CrewData.JoinedAt = 0

	requestSave(entity.ProfileHolder.Profile)

	-- Update Crew attribute
	if entity.player and entity.player:FindFirstChild("StatFolder") then
		local userFolder = entity.player.StatFolder:FindFirstChild("UserFolder")
		if userFolder then
			userFolder:SetAttribute("Crew", "None")
		end
	end
end


local function updateCrewAttribute(player, crewName)
	if player and player:FindFirstChild("StatFolder") then
		local userFolder = player.StatFolder:FindFirstChild("UserFolder")
		if userFolder then
			userFolder:SetAttribute("Crew", crewName or "None")
		end
	end
end

function CrewService.CreateCrew(player: Player, crewName: string)
	local entity = Server.EntityService.Find(player)
	Server.PlayerListService.BroadcastUpdate()
	local userFolder = entity.player.StatFolder:FindFirstChild("UserFolder")


	if not entity then return false, "", "Missing entity profile" end
	if (entity.Data.CrewData.CrewId or "") ~= "" then
		return false, "", "Player is already in a crew"
	end
	if #crewName < 3 or #crewName > 24 then
		return false, "", "Crew name must be 3-24 characters"
	end
	
	if userFolder:GetAttribute("Faction") ~= "Pirate" then
		if userFolder then
			warn(`You cannot create a crew as a {userFolder:GetAttribute("Faction")}`)
			return false, warn(`You must first abandon your role as a {userFolder:GetAttribute("Faction")} [{userFolder:GetAttribute("FactionRank")}]`)
		end
	end

	local cleanName = entity:FilterName(crewName)
	if not cleanName or cleanName == "" then
		return false, "", "Name could not be filtered"
	end

	local createdAt = os.time()
	local crewId = generateCrewId()

	local profile = CrewStore:LoadProfileAsync("Crew_" .. crewId, "ForceLoad")
	if not profile then
		return false, "", "Crew store busy, try again"
	end

	-- Setup Data
	profile.Data.CrewId = crewId
	profile.Data.CrewName = cleanName
	profile.Data.CreatedAt = createdAt
	profile.Data.CaptainUserId = player.UserId
	profile.Data.Members[player.UserId] = {
		Rank = "Captain";
		JoinedAt = createdAt;
	}

	profile:ListenToRelease(function()
		activeCrews[crewId] = nil
	end)
	activeCrews[crewId] = {Profile = profile, Data = profile.Data}

	entity.Data.CrewData.CrewId = crewId
	entity.Data.CrewData.CrewName = cleanName
	entity.Data.CrewData.CreatedAt = createdAt
	entity.Data.CrewData.CaptainUserId = player.UserId
	entity.Data.CrewData.Members = {
		[player.UserId] = { Rank = "Captain"; JoinedAt = createdAt };
	}
	entity.Data.CrewData.History = {}
	entity.Data.CrewData.Rank = "Captain"
	entity.Data.CrewData.JoinedAt = createdAt


	print(`[CrewService] Created Crew {cleanName} ({crewId})`)
	updateCrewAttribute(player, cleanName)

	return true, crewId, cleanName
end

function CrewService.GetCrewMembers(crewId: string)
	local entry = loadCrew(crewId)
	if not entry then return nil end

	local members = {}
	for userId, memberData in pairs(entry.Data.Members) do
		table.insert(members, {
			UserId = userId,
			Rank = memberData.Rank,
			JoinedAt = memberData.JoinedAt
		})
	end
	return members
end

function CrewService.JoinCrew(player: Player, crewId: string)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "Entity not found" end

	Server.PlayerListService.BroadcastUpdate()

	if (entity.Data.CrewData.CrewId or "") ~= "" then  
		return false, "Player is already in a crew"
	end

	-- CACHE CHECK (Fast because we kept it loaded in CreateCrew)
	local entry = loadCrew(crewId) 
	if not entry then return false, "Crew not found" end

	entry.Data.Members[player.UserId] = {
		Rank = "Member",
		JoinedAt = os.time(),
	}
	-- REMOVED manual Save().

	entity.Data.CrewData.CrewId = crewId
	entity.Data.CrewData.CrewName = entry.Data.CrewName
	entity.Data.CrewData.CreatedAt = entry.Data.CreatedAt
	entity.Data.CrewData.CaptainUserId = entry.Data.CaptainUserId
	entity.Data.CrewData.Rank = "Member"
	entity.Data.CrewData.JoinedAt = os.time()

	updateCrewAttribute(player, entry.Data.CrewName)

	return true, {
		CrewId = crewId,
		Name = entry.Data.CrewName,
		Rank = "Member",
		Members = CrewService.GetCrewMembers(crewId),
	}
end

function CrewService.RemoveMember(userId: number, crewId: string)
	local entry = loadCrew(crewId)
	if not entry then return false, "No crew found" end

	Server.PlayerListService.BroadcastUpdate()

	local memberData = entry.Data.Members[userId]
	if memberData then
		entry.Data.Members[userId] = nil
		local player = game.Players:GetPlayerByUserId(userId)
		if player then
			local entity = Server.EntityService.Find(player)
			if entity then
				clearCrewData(entity)
				updateCrewAttribute(player, "None")
				Server.PacketLinks.CrewDisbanded:FireClient(player) -- Or a Kick packet
			end
		end
	end
	return true
end

function CrewService.DisbandCrew(player: Player, crewId: string)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "Missing entity profile" end

	Server.PlayerListService.BroadcastUpdate()

	crewId = crewId or entity.Data.CrewData.CrewId or ""
	if crewId == "" then
		clearCrewData(entity)
		return false, "You are not in a crew."
	end

	local entry = activeCrews[crewId]
	if not entry then
		-- Try loading one last time to delete it
		entry = loadCrew(crewId)
	end

	-- Clear player data regardless of whether crew exists
	clearCrewData(entity)

	if not entry then
		return true, "Crew disbanded (Force)."
	end

	local players = game:GetService("Players")
	for memberUserId, _ in pairs(entry.Data.Members) do
		local memberPlayer = players:GetPlayerByUserId(memberUserId)
		if memberPlayer and memberPlayer ~= player then
			local memberEntity = Server.EntityService.Find(memberPlayer)
			if memberEntity then
				clearCrewData(memberEntity)
				updateCrewAttribute(memberPlayer, "None")
				Server.PacketLinks.CrewDisbanded:FireClient(memberPlayer)
			end
		end
	end

	entry.Data.Members = {}
	
	entry.Profile:Release()
	activeCrews[crewId] = nil

	return true, "Crew disbanded."
end

function CrewService.LeaveCrew(player: Player, crewId: string)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "Missing entity profile" end

	if player.UserId == entity.Data.CaptainUserId then
		return false, "Captain cannot leave. Disband instead."
	end

	Server.PlayerListService.BroadcastUpdate()

	crewId = crewId or entity.Data.CrewData.CrewId or ""
	if crewId == "" then
		clearCrewData(entity)
		return false, "You are not in a crew."
	end

	local entry = activeCrews[crewId] or loadCrew(crewId)

	-- Always clear player data first
	clearCrewData(entity)
	updateCrewAttribute(player, "None")
	Server.PacketLinks.CrewLeft:FireClient(player)

	if not entry then
		return true, "You have left the crew."
	end

	local userId = player.UserId
	if entry.Data.Members[userId] then
		entry.Data.Members[userId] = nil
	end

	-- Check if empty
	local memberCount = 0
	for _,_ in pairs(entry.Data.Members) do
		memberCount = memberCount + 1
	end

	if memberCount == 0 then
		entry.Profile:Release()
		activeCrews[crewId] = nil
	end

	return true, "You have left the crew."
end

function CrewService.GetCrewState(player: Player)
	local entity = Server.EntityService.Find(player)
	if not entity then return false, "", "Missing entity profile" end

	local crewId = entity.Data.CrewData.CrewId or ""
	local crewName = entity.Data.CrewData.CrewName or ""

	if crewId == "" then
		return true, "", "You are not in a crew."
	end

	-- Refresh attribute
	updateCrewAttribute(player, crewName)

	return true, crewId, crewName
end


Server.PacketLinks.GetCrewState.OnServerInvoke = function(player)
	return CrewService.GetCrewState(player)
end

Server.PacketLinks.CreateCrew.OnServerInvoke = function(player, crewName)
	return CrewService.CreateCrew(player, crewName)
end

Server.PacketLinks.DisbandCrew.OnServerInvoke = function(player, crewId)
	return CrewService.DisbandCrew(player, crewId)
end

Server.PacketLinks.LeaveCrew.OnServerInvoke = function(player, crewId)
	return CrewService.LeaveCrew(player, crewId)
end

Server.PacketLinks.JoinCrew.OnServerInvoke = function(inviterPlayer, invitedPlayerName, inviterCrewId)
	-- (Keep your verification logic here)
	local invitedPlayer = game:GetService("Players"):FindFirstChild(invitedPlayerName)
	if not invitedPlayer then return false, "", "Player not found." end

	return CrewService.JoinCrew(invitedPlayer, inviterCrewId)
end

return CrewService