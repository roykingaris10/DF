local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TimeService = {}

local TimeConfig = nil

local state = {
	currentTime = 8,
	currentDay = 1,
	currentMoonPhase = 1,
	remotes = nil,
	initialized = false,
}

local function createRemotes()
	local existing = ReplicatedStorage:FindFirstChild("TimeRemotes")
	if existing then
		return {
			TimeSync = existing:WaitForChild("TimeSync"),
			RequestState = existing:WaitForChild("RequestState"),
		}
	end

	local folder = Instance.new("Folder")
	folder.Name = "TimeRemotes"
	folder.Parent = ReplicatedStorage

	local timeSync = Instance.new("RemoteEvent")
	timeSync.Name = "TimeSync"
	timeSync.Parent = folder

	local requestState = Instance.new("RemoteFunction")
	requestState.Name = "RequestState"
	requestState.Parent = folder

	return {
		TimeSync = timeSync,
		RequestState = requestState,
	}
end

function TimeService:GetFullState()
	return {
		time = state.currentTime,
		day = state.currentDay,
		moonPhase = TimeConfig.Moon.Phases[state.currentMoonPhase],
	}
end

function TimeService:SyncTimeToClients()
	if not state.remotes then return end

	state.remotes.TimeSync:FireAllClients({
		type = "TimeSync",
		time = state.currentTime,
		day = state.currentDay,
		moonPhase = TimeConfig.Moon.Phases[state.currentMoonPhase],
	})
end

function TimeService:UpdateTime(delta)
	local timeIncrement = (delta / 60) * TimeConfig.Time.TimeScale / 60
	state.currentTime = state.currentTime + timeIncrement

	if state.currentTime >= 24 then
		state.currentTime = state.currentTime - 24
		state.currentDay = state.currentDay + 1
		state.currentMoonPhase = ((state.currentDay - 1) % TimeConfig.Moon.PhaseCycleDays) + 1

		state.remotes.TimeSync:FireAllClients({
			type = "NewDay",
			day = state.currentDay,
			moonPhase = TimeConfig.Moon.Phases[state.currentMoonPhase],
		})

		self:IncrementPlayerDays()
	end
end

function TimeService:IncrementPlayerDays()
	for _, player in ipairs(Players:GetPlayers()) do
		local statFolder = player:FindFirstChild("StatFolder")
		if statFolder then
			local currentDays = statFolder:GetAttribute("DaysPlayed") or 0
			statFolder:SetAttribute("DaysPlayed", currentDays + 1)
		end
	end
end

function TimeService:SetupPlayerTracking(player)
	local statFolder = player:WaitForChild("StatFolder", 10)
	if statFolder then
		if not statFolder:GetAttribute("DaysPlayed") then
			statFolder:SetAttribute("DaysPlayed", 0)
		end
	end
end

function TimeService:StartTimeLoop()
	local lastTick = tick()

	RunService.Heartbeat:Connect(function()
		local now = tick()
		local delta = now - lastTick
		lastTick = now
		self:UpdateTime(delta)
	end)

	task.spawn(function()
		while true do
			task.wait(5)
			self:SyncTimeToClients()
		end
	end)
end

function TimeService:Init()
	if state.initialized then return end

	local success, err = pcall(function()
		TimeConfig = require(ReplicatedStorage.Kits.Nodes.Gameplay.TimeConfig)
	end)

	if not success then
		warn("[TimeService] Failed to load config:", err)
		return
	end

	state.currentTime = TimeConfig.Time.StartTime
	state.remotes = createRemotes()

	state.remotes.RequestState.OnServerInvoke = function(player)
		return self:GetFullState()
	end

	self:StartTimeLoop()

	Players.PlayerAdded:Connect(function(player)
		self:SetupPlayerTracking(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:SetupPlayerTracking(player)
	end

	state.initialized = true
end

function TimeService:SetTime(time)
	state.currentTime = time % 24
	self:SyncTimeToClients()
end

function TimeService:GetCurrentTime()
	return state.currentTime
end

function TimeService:GetCurrentDay()
	return state.currentDay
end

function TimeService:GetMoonPhase()
	return TimeConfig.Moon.Phases[state.currentMoonPhase]
end

return TimeService