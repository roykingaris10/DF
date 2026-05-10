local AudioDirector = {}

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Kits = ReplicatedStorage:WaitForChild("Kits")

local FadeProfiles = {
	Default     = { out = 1.0,  inn = 1.0  },
	Region      = { out = 1.5,  inn = 1.5  },
	TimeChange  = { out = 2.0,  inn = 2.0  },
	Combat      = { out = 0.25, inn = 0.15 },
	BossCombat  = { out = 0.20, inn = 0.10 },
	Story       = { out = 0.5,  inn = 0.5  },
	Death       = { out = 0.10, inn = 0.05 },
	Ambience    = { out = 2.5,  inn = 2.5  },
}

local CHATTER_MIN_INTERVAL = 3
local CHATTER_MAX_INTERVAL = 8
local CHATTER_MIN_VOLUME = 0.20
local CHATTER_MAX_VOLUME = 0.40

local State = {
	timeState       = "Day",
	regionConfig    = nil,
	regionName      = nil,

	inCombat        = false,
	isBossCombat    = false,
	combatTimer     = 0,
	combatCooldown  = 8,

	inStory         = false,
	storyTrackId    = nil,

	isDead          = false,

	masterVolume    = 1.0,
	musicVolume     = 1.0,
	ambienceVolume  = 1.0,
}

local Buses = {
	Music = {
		name = "Music",
		sound = nil,
		sourceKey = nil,
		trackId = nil,
		baseVolume = 0.1,
		fadeProfile = FadeProfiles.Default,
	},
	Ambience = {
		name = "Ambience",
		sound = nil,
		sourceKey = nil,
		trackId = nil,
		baseVolume = 0.15,
		fadeProfile = FadeProfiles.Ambience,
	},
}

local Chatter = {
	task = nil,
	sourceKey = nil,
	folder = nil,
}

local Pools = {
	Music = { Day = nil, Night = nil, Combat = nil, BossCombat = nil, Death = nil },
	Ambience = { Day = nil, Night = nil },
	Chatter = { Day = nil, Night = nil },
}

local Folders = {
	audio = nil,
	music = nil,
	ambience = nil,
	chatter = nil,
}

local updateConnection = nil

local function isValidId(id)
	return type(id) == "string"
		and id ~= ""
		and id ~= "rbxassetid://"
		and id ~= "rbxassetid://0"
		and id ~= "rbxassetid://000000000"
end

local function poolKeyForTime(timeState)
	if timeState == "Night" or timeState == "Dusk" then return "Night" end
	return "Day"
end

local function randomIdFromPool(pool)
	if not pool then return nil end
	local valid = {}
	for _, child in ipairs(pool:GetChildren()) do
		if child:IsA("Sound") and isValidId(child.SoundId) then
			table.insert(valid, child.SoundId)
		end
	end
	if #valid == 0 then return nil end
	return valid[math.random(1, #valid)]
end

local function regionTrackFor(spec, timeState)
	if not spec then return nil end
	if type(spec) == "string" then
		return isValidId(spec) and spec or nil
	end
	if type(spec) == "table" then
		local key = poolKeyForTime(timeState)
		if isValidId(spec[key]) then return spec[key] end
		if isValidId(spec.Day) then return spec.Day end
		if isValidId(spec.Night) then return spec.Night end
	end
	return nil
end

local function setupFolders()
	local soundsRoot = Kits:FindFirstChild("Sounds")
	if soundsRoot then
		local musicRoot = soundsRoot:FindFirstChild("Music")
		if musicRoot then
			Pools.Music.Day        = musicRoot:FindFirstChild("Day")
			Pools.Music.Night      = musicRoot:FindFirstChild("Night")
			Pools.Music.Combat     = musicRoot:FindFirstChild("Combat")
			Pools.Music.BossCombat = musicRoot:FindFirstChild("BossCombat")
			Pools.Music.Death      = musicRoot:FindFirstChild("Death")
		end
		local ambienceRoot = soundsRoot:FindFirstChild("Ambience")
		if ambienceRoot then
			Pools.Ambience.Day   = ambienceRoot:FindFirstChild("Day")
			Pools.Ambience.Night = ambienceRoot:FindFirstChild("Night")
		end
		local chatterRoot = soundsRoot:FindFirstChild("Chatter")
		if chatterRoot then
			Pools.Chatter.Day   = chatterRoot:FindFirstChild("Day")
			Pools.Chatter.Night = chatterRoot:FindFirstChild("Night")
		end
	end

	Folders.audio = SoundService:FindFirstChild("AudioDirector")
	if not Folders.audio then
		Folders.audio = Instance.new("Folder")
		Folders.audio.Name = "AudioDirector"
		Folders.audio.Parent = SoundService
	end

	for _, sub in ipairs({"Music", "Ambience", "Chatter"}) do
		local folder = Folders.audio:FindFirstChild(sub)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = sub
			folder.Parent = Folders.audio
		end
		Folders[sub:lower()] = folder
	end

	Chatter.folder = Folders.chatter
end

local function effectiveVolume(busName, baseVolume)
	local m = State.masterVolume
	if busName == "Music" then
		return (baseVolume or 0.1) * m * State.musicVolume
	elseif busName == "Ambience" then
		return (baseVolume or 0.15) * m * State.ambienceVolume
	end
	return (baseVolume or 0.1) * m
end

local function fadeOutAndDestroy(sound, time)
	if not sound then return end
	local tween = TweenService:Create(sound, TweenInfo.new(time), { Volume = 0 })
	tween:Play()
	tween.Completed:Connect(function()
		if sound and sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end)
end

local function spawnBusSound(bus, trackId, baseVolume)
	local sound = Instance.new("Sound")
	sound.Name = "Bus_" .. bus.name
	sound.SoundId = trackId
	sound.Looped = true
	sound.Volume = 0
	sound:SetAttribute("BaseVolume", baseVolume)
	sound.Parent = Folders[bus.name:lower()] or Folders.audio
	sound:Play()
	return sound
end

local function crossfadeBus(busName, trackId, baseVolume, profile)
	local bus = Buses[busName]
	local prevSound = bus.sound
	local fade = profile or bus.fadeProfile or FadeProfiles.Default

	local newSound = spawnBusSound(bus, trackId, baseVolume)
	bus.sound = newSound
	bus.trackId = trackId
	bus.baseVolume = baseVolume

	local target = effectiveVolume(busName, baseVolume)
	TweenService:Create(newSound, TweenInfo.new(fade.inn), { Volume = target }):Play()

	if prevSound then
		fadeOutAndDestroy(prevSound, fade.out)
	end
end

local function silenceBus(busName, profile)
	local bus = Buses[busName]
	if bus.sound then
		fadeOutAndDestroy(bus.sound, (profile or bus.fadeProfile or FadeProfiles.Default).out)
		bus.sound = nil
	end
	bus.sourceKey = nil
	bus.trackId = nil
end

local function resolveMusic()
	if State.isDead then
		local id = randomIdFromPool(Pools.Music.Death)
		if id then return "death", id, 0.22, FadeProfiles.Death end
	end
	if State.inCombat and State.isBossCombat then
		local id = randomIdFromPool(Pools.Music.BossCombat) or randomIdFromPool(Pools.Music.Combat)
		if id then return "bossCombat", id, 0.18, FadeProfiles.BossCombat end
	end
	if State.inCombat then
		local id = randomIdFromPool(Pools.Music.Combat)
		if id then return "combat", id, 0.16, FadeProfiles.Combat end
	end
	if State.inStory and isValidId(State.storyTrackId) then
		return "story", State.storyTrackId, 0.15, FadeProfiles.Story
	end
	if State.regionConfig then
		local id = regionTrackFor(State.regionConfig.Music, State.timeState)
		if id then
			return "region:" .. (State.regionName or "?"),
				id,
				State.regionConfig.Volume or 0.1,
				FadeProfiles.Region
		end
	end
	local generalPool = Pools.Music[poolKeyForTime(State.timeState)]
	local id = randomIdFromPool(generalPool)
	if id then
		return "general:" .. poolKeyForTime(State.timeState), id, 0.08, FadeProfiles.TimeChange
	end
	return nil, nil, 0, FadeProfiles.Default
end

local function resolveAmbience()
	if State.isDead then return nil, nil, 0, FadeProfiles.Ambience end

	if State.regionConfig then
		local id = regionTrackFor(State.regionConfig.Ambience, State.timeState)
		if id then
			return "region:" .. (State.regionName or "?"),
				id,
				State.regionConfig.AmbienceVolume or 0.15,
				FadeProfiles.Region
		end
	end

	local generalPool = Pools.Ambience[poolKeyForTime(State.timeState)]
	local id = randomIdFromPool(generalPool)
	if id then
		return "general:" .. poolKeyForTime(State.timeState), id, 0.12, FadeProfiles.Ambience
	end
	return nil, nil, 0, FadeProfiles.Ambience
end

local function resolveChatter()
	if State.isDead then return nil, nil end

	if State.regionConfig
		and State.regionConfig.Chatter
		and State.regionConfig.ChatterSounds
		and #State.regionConfig.ChatterSounds > 0 then
		local list = {}
		for _, id in ipairs(State.regionConfig.ChatterSounds) do
			if isValidId(id) then table.insert(list, id) end
		end
		if #list > 0 then
			return "region:" .. (State.regionName or "?"), list
		end
	end

	local pool = Pools.Chatter[poolKeyForTime(State.timeState)]
	if pool then
		local list = {}
		for _, child in ipairs(pool:GetChildren()) do
			if child:IsA("Sound") and isValidId(child.SoundId) then
				table.insert(list, child.SoundId)
			end
		end
		if #list > 0 then
			return "general:" .. poolKeyForTime(State.timeState), list
		end
	end
	return nil, nil
end

local function stopChatter()
	if Chatter.task then
		pcall(function() task.cancel(Chatter.task) end)
		Chatter.task = nil
	end
	if Chatter.folder then
		for _, child in ipairs(Chatter.folder:GetChildren()) do
			if child:IsA("Sound") then child:Destroy() end
		end
	end
end

local function startChatter(sessionKey, soundIds)
	Chatter.task = task.spawn(function()
		while Chatter.sourceKey == sessionKey do
			task.wait(math.random(CHATTER_MIN_INTERVAL, CHATTER_MAX_INTERVAL))
			if Chatter.sourceKey ~= sessionKey then break end

			local id = soundIds[math.random(1, #soundIds)]
			local s = Instance.new("Sound")
			s.Name = "ChatterShot"
			s.SoundId = id
			local base = math.random(math.floor(CHATTER_MIN_VOLUME * 100), math.floor(CHATTER_MAX_VOLUME * 100)) / 100
			s.Volume = base * State.masterVolume * State.ambienceVolume
			s:SetAttribute("BaseVolume", base)
			s.Parent = Chatter.folder
			s:Play()
			s.Ended:Connect(function() s:Destroy() end)
			Debris:AddItem(s, 30)
		end
	end)
end

local function updateBus(busName, resolver)
	local key, trackId, baseVolume, profile = resolver()
	local bus = Buses[busName]

	if not key or not trackId then
		if bus.sound then silenceBus(busName, profile) end
		bus.sourceKey = nil
		return
	end

	if bus.sourceKey == key and bus.trackId == trackId then return end

	bus.sourceKey = key
	crossfadeBus(busName, trackId, baseVolume, profile)
end

local function updateChatter()
	local key, sounds = resolveChatter()
	if Chatter.sourceKey == key then return end
	stopChatter()
	Chatter.sourceKey = key
	if key and sounds then
		startChatter(key, sounds)
	end
end

local function refresh()
	updateBus("Music", resolveMusic)
	updateBus("Ambience", resolveAmbience)
	updateChatter()
end

local function refreshVolumes()
	for _, bus in pairs(Buses) do
		if bus.sound and bus.sound.Parent then
			bus.sound.Volume = effectiveVolume(bus.name, bus.sound:GetAttribute("BaseVolume") or 0.1)
		end
	end
end

function AudioDirector:SetRegion(config, timeState, regionName)
	State.regionConfig = config
	State.regionName = regionName or (config and config.DisplayName) or nil
	if timeState then State.timeState = timeState end
	refresh()
end

function AudioDirector:ClearRegion()
	State.regionConfig = nil
	State.regionName = nil
	refresh()
end

function AudioDirector:SetTimeState(timeState)
	if not timeState or State.timeState == timeState then return end
	State.timeState = timeState
	refresh()
end

function AudioDirector:GetTimeState()
	return State.timeState
end

function AudioDirector:StartCombat(isBoss)
	State.inCombat = true
	State.isBossCombat = isBoss or false
	State.combatTimer = State.combatCooldown
	refresh()
end

function AudioDirector:ExtendCombat()
	if State.inCombat then
		State.combatTimer = State.combatCooldown
	end
end

function AudioDirector:EndCombat()
	if not State.inCombat then return end
	State.inCombat = false
	State.isBossCombat = false
	State.combatTimer = 0
	refresh()
end

function AudioDirector:IsInCombat()
	return State.inCombat
end

function AudioDirector:StartDeath()
	State.isDead = true
	State.inCombat = false
	State.isBossCombat = false
	State.combatTimer = 0
	refresh()
end

function AudioDirector:EndDeath()
	if not State.isDead then return end
	State.isDead = false
	refresh()
end

function AudioDirector:StartStory(trackId)
	State.inStory = true
	State.storyTrackId = trackId
	refresh()
end

function AudioDirector:EndStory()
	State.inStory = false
	State.storyTrackId = nil
	refresh()
end

function AudioDirector:SetMasterVolume(v)
	State.masterVolume = math.clamp(v or 1, 0, 1)
	refreshVolumes()
end

function AudioDirector:SetMusicVolume(v)
	State.musicVolume = math.clamp(v or 1, 0, 1)
	refreshVolumes()
end

function AudioDirector:SetAmbienceVolume(v)
	State.ambienceVolume = math.clamp(v or 1, 0, 1)
	refreshVolumes()
end

function AudioDirector:GetVolumes()
	return {
		master = State.masterVolume,
		music = State.musicVolume,
		ambience = State.ambienceVolume,
	}
end

function AudioDirector:GetCurrentMusicTrack()
	return Buses.Music.trackId
end

function AudioDirector:GetCurrentAmbienceTrack()
	return Buses.Ambience.trackId
end

function AudioDirector:Refresh()
	refresh()
end

local function update(dt)
	if State.inCombat and not State.isDead then
		State.combatTimer -= dt
		if State.combatTimer <= 0 then
			AudioDirector:EndCombat()
		end
	end
end

function AudioDirector:Init()
	setupFolders()
	if updateConnection then return end
	updateConnection = RunService.Heartbeat:Connect(update)
	refresh()
end

function AudioDirector:Cleanup()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end
	stopChatter()
	silenceBus("Music")
	silenceBus("Ambience")
end

return AudioDirector
