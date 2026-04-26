--[[
    AUDIO DIRECTOR
    Location: ReplicatedStorage > Kits > Audio > AudioDirector
    
    Central music system with priority-based playback.
    External systems request music, AudioDirector decides what plays.
    
    Priority Ladder:
    100 = Death (locks system until respawn)
    80  = Boss Combat
    60  = Combat
    50  = Story/Cutscene
    20  = Region (Day/Night)
    0   = Default/World
    
    Usage from external systems:
    - Combat: AudioDirector:StartCombat(isBoss) / AudioDirector:EndCombat()
    - Death: AudioDirector:StartDeath() / AudioDirector:EndDeath()
    - Region: AudioDirector:SetRegion(config, timeState)
    - Story: AudioDirector:StartStory(trackId) / AudioDirector:EndStory()
]]

local AudioDirector = {}

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = ReplicatedStorage.Kits

local player = Players.LocalPlayer

AudioDirector.Priority = {
	DEATH = 100,
	BOSS_COMBAT = 80,
	COMBAT = 60,
	STORY = 50,
	REGION = 20,
	DEFAULT = 0,
}

local Priority = AudioDirector.Priority

local FadeProfiles = {
	Death = { out = 0.1, inn = 0.05 },
	Combat = { out = 0.25, inn = 0.15 },
	BossCombat = { out = 0.15, inn = 0.1 },
	Region = { out = 1.5, inn = 1.5 },
	TimeChange = { out = 2.0, inn = 2.0 },
	Story = { out = 0.5, inn = 0.5 },
	Default = { out = 1.0, inn = 1.0 },
}

local State = {
	-- Current playback
	currentPriority = Priority.DEFAULT,
	currentTrackId = nil,
	currentMusic = nil,
	currentReason = nil,

	-- Lock (for death)
	isLocked = false,

	-- Combat tracking
	inCombat = false,
	isBossCombat = false,
	combatTimer = 0,
	combatCooldown = 10,

	-- Region tracking (so we can resume after combat/story)
	regionConfig = nil,
	regionTimeState = "Day",

	-- Story tracking
	inStory = false,
	storyTrackId = nil,

	-- Volume (0-1)
	masterVolume = 1.0,
	musicVolume = 1.0,

	-- Folders
	musicFolder = nil,

	-- Update connection
	updateConnection = nil,
}

local MusicFolders = {}

local function setupFolders()
	-- Get music folders from ReplicatedStorage

	local musicRoot = Kits.Sounds.Music

	if musicRoot then
		MusicFolders.Combat = musicRoot:FindFirstChild("Combat")
		MusicFolders.Day = musicRoot:FindFirstChild("Day")
		MusicFolders.Night = musicRoot:FindFirstChild("Night")
		MusicFolders.Death = musicRoot:FindFirstChild("Death")
	end

	-- Create playback folder in SoundService
	local audioFolder = SoundService:FindFirstChild("AudioDirector")
	if not audioFolder then
		audioFolder = Instance.new("Folder")
		audioFolder.Name = "AudioDirector"
		audioFolder.Parent = SoundService
	end

	State.musicFolder = audioFolder:FindFirstChild("Music")
	if not State.musicFolder then
		State.musicFolder = Instance.new("Folder")
		State.musicFolder.Name = "Music"
		State.musicFolder.Parent = audioFolder
	end
end

local function getRandomTrackFromFolder(folder)
	if not folder then return nil end
	local children = folder:GetChildren()
	if #children == 0 then return nil end
	local track = children[math.random(1, #children)]
	return track and track.SoundId
end

local function getEffectiveVolume(baseVolume)
	return (baseVolume or 0.1) * State.masterVolume * State.musicVolume
end

local function isValidTrackId(trackId)
	return trackId 
		and trackId ~= "" 
		and trackId ~= "rbxassetid://" 
		and trackId ~= "rbxassetid://000000000"
end

local function stopMusic(fadeTime, callback)
	if not State.currentMusic then
		if callback then callback() end
		return
	end

	local music = State.currentMusic
	State.currentMusic = nil
	State.currentTrackId = nil

	local tween = TweenService:Create(music, TweenInfo.new(fadeTime), { Volume = 0 })
	tween:Play()
	tween.Completed:Connect(function()
		music:Stop()
		music:Destroy()
		if callback then callback() end
	end)
end

local function playTrack(trackId, volume, fadeProfile, reason)
	if not isValidTrackId(trackId) then return false end
	if trackId == State.currentTrackId then return false end -- Same track, skip

	local profile = fadeProfile or FadeProfiles.Default
	local targetVolume = getEffectiveVolume(volume)

	stopMusic(profile.out, function()
		local music = Instance.new("Sound")
		music.SoundId = trackId
		music.Looped = true
		music.Volume = 0
		music:SetAttribute("BaseVolume", volume or 0.1)
		music.Parent = State.musicFolder
		music:Play()

		State.currentMusic = music
		State.currentTrackId = trackId
		State.currentReason = reason

		TweenService:Create(music, TweenInfo.new(profile.inn), { Volume = targetVolume }):Play()
	end)

	return true
end

local function resolveRegionTrack()
	local config = State.regionConfig
	if not config then return nil, 0.1 end

	local trackId = nil
	local music = config.Music

	if type(music) == "table" then
		-- Day/Night variants
		trackId = music[State.regionTimeState] or music.Day or music.Night
	elseif isValidTrackId(music) then
		trackId = music
	end

	-- Fallback to Day/Night folders
	if not isValidTrackId(trackId) then
		local folder = (State.regionTimeState == "Night" or State.regionTimeState == "Dusk")
			and MusicFolders.Night
			or MusicFolders.Day
		trackId = getRandomTrackFromFolder(folder)
	end

	return trackId, config.Volume or 0.1
end

local function playHighestPriority()
	if State.isLocked then return end

	-- Death (handled separately with lock)

	-- Boss Combat
	if State.inCombat and State.isBossCombat then
		local trackId = getRandomTrackFromFolder(MusicFolders.Combat)
		if trackId and State.currentPriority ~= Priority.BOSS_COMBAT then
			State.currentPriority = Priority.BOSS_COMBAT
			playTrack(trackId, 0.15, FadeProfiles.BossCombat, "BossCombat")
		end
		return
	end

	-- Combat
	if State.inCombat then
		local trackId = getRandomTrackFromFolder(MusicFolders.Combat)
		if trackId and State.currentPriority ~= Priority.COMBAT then
			State.currentPriority = Priority.COMBAT
			playTrack(trackId, 0.15, FadeProfiles.Combat, "Combat")
		end
		return
	end

	-- Story
	if State.inStory and isValidTrackId(State.storyTrackId) then
		if State.currentPriority ~= Priority.STORY then
			State.currentPriority = Priority.STORY
			playTrack(State.storyTrackId, 0.15, FadeProfiles.Story, "Story")
		end
		return
	end

	-- Region
	local trackId, volume = resolveRegionTrack()
	if isValidTrackId(trackId) then
		State.currentPriority = Priority.REGION
		playTrack(trackId, volume, FadeProfiles.Region, "Region")
		return
	end

	-- Default (silence or world music from Day folder)
	State.currentPriority = Priority.DEFAULT
	local defaultTrack = getRandomTrackFromFolder(MusicFolders.Day)
	if defaultTrack then
		playTrack(defaultTrack, 0.08, FadeProfiles.Default, "Default")
	end
end

function AudioDirector:SetRegion(config, timeState)
	State.regionConfig = config
	State.regionTimeState = timeState or State.regionTimeState or "Day"

	if not State.isLocked and not State.inCombat and not State.inStory then
		playHighestPriority()
	end
end

function AudioDirector:ClearRegion()
	State.regionConfig = nil

	if not State.isLocked and not State.inCombat and not State.inStory then
		playHighestPriority()
	end
end

function AudioDirector:SetTimeState(timeState)
	if State.regionTimeState == timeState then return end
	State.regionTimeState = timeState

	-- Only change music if we're at region priority
	if State.currentPriority == Priority.REGION then
		local trackId, volume = resolveRegionTrack()
		if isValidTrackId(trackId) and trackId ~= State.currentTrackId then
			playTrack(trackId, volume, FadeProfiles.TimeChange, "Region")
		end
	end
end

function AudioDirector:StartCombat(isBoss)
	if State.isLocked then return end

	State.inCombat = true
	State.isBossCombat = isBoss or false
	State.combatTimer = State.combatCooldown

	playHighestPriority()
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

	playHighestPriority()
end

function AudioDirector:IsInCombat()
	return State.inCombat
end

function AudioDirector:StartDeath()
	State.isLocked = true
	State.currentPriority = Priority.DEATH
	State.inCombat = false
	State.combatTimer = 0

	local trackId = getRandomTrackFromFolder(MusicFolders.Death)
	if trackId then
		playTrack(trackId, 0.25, FadeProfiles.Death, "Death")
	end
end

function AudioDirector:EndDeath()
	State.isLocked = false
	State.currentPriority = Priority.DEFAULT

	playHighestPriority()
end

function AudioDirector:StartStory(trackId)
	if State.isLocked then return end

	State.inStory = true
	State.storyTrackId = trackId

	playHighestPriority()
end

function AudioDirector:EndStory()
	State.inStory = false
	State.storyTrackId = nil

	playHighestPriority()
end

function AudioDirector:PlayCustom(trackId, priority, volume, fadeProfile)
	if State.isLocked and priority < Priority.DEATH then return false end
	if priority < State.currentPriority then return false end

	State.currentPriority = priority
	return playTrack(trackId, volume or 0.1, fadeProfile or FadeProfiles.Default, "Custom")
end

function AudioDirector:ReleaseCustom(priority)
	if State.currentPriority == priority and State.currentReason == "Custom" then
		State.currentPriority = Priority.DEFAULT
		playHighestPriority()
	end
end

function AudioDirector:SetMasterVolume(volume)
	State.masterVolume = math.clamp(volume, 0, 1)
	AudioDirector:RefreshVolume()
end

function AudioDirector:SetMusicVolume(volume)
	State.musicVolume = math.clamp(volume, 0, 1)
	AudioDirector:RefreshVolume()
end

function AudioDirector:RefreshVolume()
	if State.currentMusic then
		local baseVolume = State.currentMusic:GetAttribute("BaseVolume") or 0.1
		State.currentMusic.Volume = getEffectiveVolume(baseVolume)
	end
end

function AudioDirector:GetVolumes()
	return {
		master = State.masterVolume,
		music = State.musicVolume,
	}
end

function AudioDirector:GetCurrentPriority()
	return State.currentPriority
end

function AudioDirector:GetCurrentTrack()
	return State.currentTrackId
end

function AudioDirector:IsLocked()
	return State.isLocked
end

local function update(dt)
	if State.inCombat and not State.isLocked then
		State.combatTimer = State.combatTimer - dt
		if State.combatTimer <= 0 then
			AudioDirector:EndCombat()
		end
	end
end


function AudioDirector:Init()
	setupFolders()

	State.updateConnection = RunService.Heartbeat:Connect(update)

	print("[AudioDirector] Initialized")
end

function AudioDirector:Cleanup()
	if State.updateConnection then
		State.updateConnection:Disconnect()
		State.updateConnection = nil
	end

	stopMusic(0)
end

return AudioDirector