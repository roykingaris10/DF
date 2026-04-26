local ClientSFX = {}

local MAIN_MUSIC = nil
local MUSIC_PLAYING = {}

local RNG = Random.new()

function ClientSFX.PlaySFX(sound: Sound, randomPitch: bool, lowestPitch: number, highestPitch: number)
	
	local Copy = sound:Clone()
	Copy.Parent = sound.Parent
	
	if randomPitch then
		local Pitch = Instance.new("PitchShiftSoundEffect", Copy)
		Pitch.Octave = RNG:NextNumber(lowestPitch or 1, highestPitch or 3)
	end
	
	Copy:Play()
	
	Copy.Ended:Once(function()
		Copy:Destroy()
	end)
	
end

function ClientSFX.PlayMusic(sound: Sound, isMainMusic: bool)
	
	if isMainMusic and MAIN_MUSIC ~= sound then
		if MAIN_MUSIC then
			MAIN_MUSIC:Stop()
		end
		MAIN_MUSIC = sound
		MAIN_MUSIC:Play()
		
		MUSIC_PLAYING[sound] = MUSIC_PLAYING[sound] or true
		
	else
		
		sound:Play()
		MUSIC_PLAYING[sound] = MUSIC_PLAYING[sound] or true
		
	end
	
end

function ClientSFX.StopAllMusic(exception: Sound)
	for music, playing in MUSIC_PLAYING do
		if music ~= exception then
			music:Stop()
		end
	end
end

return ClientSFX
