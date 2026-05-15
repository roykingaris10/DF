return function(Client)
	local FootstepsSetup = {}
	local player = Client.player
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
	local FootstepsModule = require(ReplicatedStorage.Kits.Nodes.Utility.FootstepModule)

	-- Configuration
	local CONFIG = {
		
		BaseVolume = 0.08,
		SprintVolumeMultiplier = 1.4,
		CrouchVolumeMultiplier = 0.5,
		RollOffMode = Enum.RollOffMode.InverseTapered,
		RollOffMaxDistance = 70,
		RollOffMinDistance = 10,

		BaseSpeed = 16,
		BaseInterval = 0.4,
		MinInterval = 0.15,
		MaxInterval = 0.6,

		MinPitch = 0.9,
		MaxPitch = 1.1,
		SprintPitchBoost = 0.1,

		-- Landing
		LandingVolumeMultiplier = 1.8,
		LandingCooldown = 0.15,
		FallTimeThreshold = 0.2,
	}

	local state = {
		connection = nil,
		sounds = {},
		soundIndex = 1,
		poolSize = 3,
		lastStepTime = 0,
		lastMaterial = nil,
		cachedSoundTable = nil,
		wasGrounded = true,
		fallStartTime = 0,
		lastLandTime = 0,
	}

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local function shouldDisableFootsteps()
		local entity = Client.Entity
		if not entity then return false end

		local combatData = entity.CombatData
		if not combatData then return false end

		return combatData.CurrentlyAttacking
			or combatData.Dashing
			or combatData.Blocking
			or combatData.ClientActive
			or combatData.WillDash
			or combatData.Stunned
	end

	local function createSoundPool(parent)
		for i = 1, state.poolSize do
			local sound = Instance.new("Sound")
			sound.Name = "Footstep_" .. i
			sound.Volume = CONFIG.BaseVolume
			sound.RollOffMode = CONFIG.RollOffMode
			sound.RollOffMaxDistance = CONFIG.RollOffMaxDistance
			sound.RollOffMinDistance = CONFIG.RollOffMinDistance
			sound.Parent = parent
			state.sounds[i] = sound
		end
	end

	local function getNextSound()
		local sound = state.sounds[state.soundIndex]
		state.soundIndex = (state.soundIndex % state.poolSize) + 1
		return sound
	end

	local function getStepInterval(speed)
		if speed <= 0 then return CONFIG.MaxInterval end

		local interval = CONFIG.BaseInterval * (CONFIG.BaseSpeed / speed)
		return math.clamp(interval, CONFIG.MinInterval, CONFIG.MaxInterval)
	end

	local function getGroundMaterial(humanoidRootPart, character)
		local rayOrigin = humanoidRootPart.Position
		local rayDirection = Vector3.new(0, -humanoidRootPart.Size.Y / 2 - 2.5, 0)

		raycastParams.FilterDescendantsInstances = {character}

		local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

		if result then
			return result.Material
		end

		return nil
	end

	local function playSound(soundId, volume, pitch)
		if not soundId or soundId == "q" then return end

		local sound = getNextSound()
		if not sound or not sound.Parent then return end

		sound.SoundId = soundId
		sound.Volume = volume
		sound.PlaybackSpeed = pitch
		sound.TimePosition = 0
		sound:Play()
	end

	local function playFootstep(material, isSprinting, volume)
		-- Cache sound table if material changed
		if material ~= state.lastMaterial then
			state.cachedSoundTable = FootstepsModule:GetTableFromMaterial(material)
			state.lastMaterial = material
		end

		local soundTable = state.cachedSoundTable
		if not soundTable or #soundTable == 0 then return end

		local soundId = soundTable[math.random(#soundTable)]

		-- Calculate pitch with variation
		local basePitch = CONFIG.MinPitch + math.random() * (CONFIG.MaxPitch - CONFIG.MinPitch)
		if isSprinting then
			basePitch = basePitch + CONFIG.SprintPitchBoost
		end

		playSound(soundId, volume, basePitch)
	end

	local function playLandingSound(material)
		-- Cache sound table if material changed
		if material ~= state.lastMaterial then
			state.cachedSoundTable = FootstepsModule:GetTableFromMaterial(material)
			state.lastMaterial = material
		end

		local soundTable = state.cachedSoundTable
		if not soundTable or #soundTable == 0 then return end

		local soundId = soundTable[math.random(#soundTable)]
		local volume = CONFIG.BaseVolume * CONFIG.LandingVolumeMultiplier
		local pitch = CONFIG.MinPitch + math.random() * 0.1 -- Lower pitch for landing

		playSound(soundId, volume, pitch)
	end

	function FootstepsSetup:Setup()
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local humanoid = character:WaitForChild("Humanoid")

		-- Silence Roblox default Running sound so it doesn't play under ours
		task.spawn(function()
			local running = humanoidRootPart:WaitForChild("Running", 5)
			if running then
				running.Volume = 0
				running:GetPropertyChangedSignal("Volume"):Connect(function()
					if running.Volume ~= 0 then running.Volume = 0 end
				end)
			end
		end)

		-- Cleanup old sounds
		for _, child in ipairs(humanoidRootPart:GetChildren()) do
			if child:IsA("Sound") and child.Name:match("^Footstep") then
				child:Destroy()
			end
		end

		-- Create sound pool
		state.sounds = {}
		state.soundIndex = 1
		createSoundPool(humanoidRootPart)

		-- Reset state
		state.lastStepTime = 0
		state.lastMaterial = nil
		state.cachedSoundTable = nil
		state.wasGrounded = true
		state.fallStartTime = 0
		state.lastLandTime = 0

		-- Disconnect old connection
		if state.connection then
			state.connection:Disconnect()
		end

		state.connection = RunService.Heartbeat:Connect(function(dt)
			if shouldDisableFootsteps() then return end

			local currentTime = tick()
			local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air
			local isMoving = humanoid.MoveDirection.Magnitude > 0.1
			local speed = humanoid.WalkSpeed
			local isSprinting = speed > 20

			-- Landing detection
			if isGrounded and not state.wasGrounded then
				local fallDuration = currentTime - state.fallStartTime

				if fallDuration > CONFIG.FallTimeThreshold then
					if currentTime - state.lastLandTime > CONFIG.LandingCooldown then
						local material = getGroundMaterial(humanoidRootPart, character)
						if material then
							playLandingSound(material)
							state.lastLandTime = currentTime
							state.lastStepTime = currentTime -- Reset step timer after landing
						end
					end
				end
			elseif not isGrounded and state.wasGrounded then
				state.fallStartTime = currentTime
			end

			state.wasGrounded = isGrounded

			-- Regular footsteps
			if not isGrounded or not isMoving then return end

			local stepInterval = getStepInterval(speed)

			if currentTime - state.lastStepTime < stepInterval then return end

			local material = getGroundMaterial(humanoidRootPart, character)
			if not material then return end

			-- Calculate volume
			local volume = CONFIG.BaseVolume
			if isSprinting then
				volume = volume * CONFIG.SprintVolumeMultiplier
			end

			playFootstep(material, isSprinting, volume)
			state.lastStepTime = currentTime
		end)
	end

	function FootstepsSetup:Init()
		FootstepsSetup:Setup()
		player.CharacterAdded:Connect(function()
			FootstepsSetup.Respawn()
		end)
	end

	function FootstepsSetup.Respawn()
		if state.connection then
			state.connection:Disconnect()
			state.connection = nil
		end

		for _, sound in ipairs(state.sounds) do
			if sound and sound.Parent then
				sound:Destroy()
			end
		end

		state.sounds = {}
		FootstepsSetup:Setup()
	end

	return FootstepsSetup
end