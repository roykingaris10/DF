return function(Client)
	local State = {}
	local player = Client.player

	local UserInputService = game:GetService("UserInputService")
	local Debris = game:GetService("Debris")
	local TweenService = game:GetService("TweenService")
	local ContentProvider = game:GetService("ContentProvider")
	local SoundService = game:GetService("SoundService")

	local CFG = {
		MinHeight = 0.4,
		MaxHeight = 6.0,
		ForwardReach = 9.0,
		OverheadReachExtra = 0.0,
		OverheadClearance = 2.5,
		ForwardImpulse = 40,
		UpwardImpulse = 22,
		VelocityDuration = 0.2,
		AnimSpeed = 1.2,
		Cooldown = 1.7,

		ForwardInputThreshold = -0.3,

		FOVKickAmount = 4,
		FOVKickIn = 0.12,
		FOVKickOut = 0.35,

		LandingWalkSpeed = 24,
		LandingBoostDuration = 0.7,

		SoundId = "rbxassetid://87293838054174",
		SoundVolume = 0.5,
	}

	local function playVaultSound(hrp)
		if not hrp then return end
		if not CFG.SoundId or CFG.SoundId == "" or CFG.SoundId == "rbxassetid://0" then return end

		local existing = hrp:FindFirstChild("VaultSound")
		if existing then existing:Destroy() end

		local vaultSound = Instance.new("Sound")
		vaultSound.Name = "VaultSound"
		vaultSound.SoundId = CFG.SoundId
		vaultSound.Volume = CFG.SoundVolume
		vaultSound.Parent = hrp
		vaultSound:Play()
		Debris:AddItem(vaultSound, 5)
	end

	local BLOCKING = {"CurrentlyAttacking", "Dashing", "Blocking", "Sliding", "Stunned", "Aerial"}

	local COOLDOWN_KEY = "Vault"

	local active = false

	local cachedTracks = nil
	local cachedAnimator = nil

	local function isOnCooldown(Entity)
		if not Entity or not Entity.Cooldowns or not Entity.Cooldowns.cooldownData then return false end
		local entry = Entity.Cooldowns.cooldownData[COOLDOWN_KEY]
		if not entry then return false end
		if typeof(entry) == "number" then
			return os.clock() < entry
		end
		return entry == true
	end

	local function startCooldown(Entity)
		if not Entity or not Entity.Cooldowns then return end
		Entity.Cooldowns:Add(COOLDOWN_KEY, CFG.Cooldown)
		if Entity.Cooldowns.DisplayCooldown then
			pcall(function()
				Entity.Cooldowns:DisplayCooldown({ Name = COOLDOWN_KEY, Time = CFG.Cooldown })
			end)
		end
	end

	local function highestY(part)
		return part.Position.Y + (part.Size.Y / 2)
	end

	local function isCharacterPart(part)
		local model = part:FindFirstAncestorOfClass("Model")
		while model do
			if model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("HumanoidRootPart") then
				return true
			end
			model = model:FindFirstAncestorOfClass("Model")
		end
		return false
	end

	local function buildRayParams(character)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {character, workspace.CurrentCamera}
		rp.IgnoreWater = true
		return rp
	end

	local function castForward(rp, origin, look)
		return workspace:Raycast(origin, look * CFG.ForwardReach, rp)
	end

	local function detectVaultable(character)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local head = character:FindFirstChild("Head")
		if not hrp or not head then return nil end

		local rp = buildRayParams(character)
		local look = hrp.CFrame.LookVector

		local result
		for _, dy in ipairs({ -1, 0.5, 2 }) do
			local origin = hrp.Position + Vector3.new(0, dy, 0)
			local hit = castForward(rp, origin, look)
			if hit then
				result = hit
				break
			end
		end

		if not result then return nil end

		local part = result.Instance
		if part:GetAttribute("NoVault") then return nil end
		if isCharacterPart(part) then return nil end

		local topY = highestY(part)
		local clearOrigin = result.Position + Vector3.new(0, CFG.OverheadClearance, 0)
		local clearRay = workspace:Raycast(clearOrigin, look * (CFG.ForwardReach + CFG.OverheadReachExtra), rp)
		if clearRay and (clearRay.Instance ~= part) then
			return nil
		end

		local heightAboveCenter = topY - hrp.Position.Y
		if heightAboveCenter < (CFG.MinHeight - 3) or heightAboveCenter > (CFG.MaxHeight - 3) then
			return nil
		end

		return { part = part, heightAboveCenter = heightAboveCenter }
	end

	local function loadVaultTracks(humanoid)
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then return nil end

		if cachedAnimator ~= animator then
			cachedTracks = nil
			cachedAnimator = animator
		end
		if cachedTracks then return cachedTracks end

		local data = Client.AnimationData and Client.AnimationData.General
		if not data then return nil end

		local tracks = {}
		for i = 1, 3 do
			local id = data["Vault" .. i]
			if id then
				local anim = Instance.new("Animation")
				anim.Name = "Vault" .. i
				anim.AnimationId = "rbxassetid://" .. tostring(id)
				anim.Parent = animator
				local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
				if ok and track then
					track.Priority = Enum.AnimationPriority.Action2
					table.insert(tracks, track)
				end
			end
		end

		cachedTracks = #tracks > 0 and tracks or nil
		return cachedTracks
	end

	local function playVaultAnim(humanoid)
		local tracks = loadVaultTracks(humanoid)
		if not tracks or #tracks == 0 then return end
		local track = tracks[math.random(1, #tracks)]
		if track.IsPlaying then track:Stop(0) end
		track:Play()
		track:AdjustSpeed(CFG.AnimSpeed)
	end

	local function combatLocked(Entity)
		for _, flag in ipairs(BLOCKING) do
			if Entity.CombatData and Entity.CombatData[flag] then return true end
		end
		if Entity.Character and Entity.Character:GetAttribute("Stunned") then return true end
		return false
	end

	local function hasForwardInput(character)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then return true end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then return true end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then return true end
		local hum = character:FindFirstChildOfClass("Humanoid")
		local moveDir = hum and hum.MoveDirection or Vector3.zero
		if moveDir.Magnitude < 0.05 then return false end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end
		return moveDir:Dot(hrp.CFrame.LookVector) > CFG.ForwardInputThreshold
	end

	State["TryVault"] = function(self, Params)
		local Entity = Client.Entity
		if not Entity or not Entity.Character then return false end
		if active then return false end
		if isOnCooldown(Entity) then return false end
		if combatLocked(Entity) then return false end
		if not hasForwardInput(Entity.Character) then return false end

		local target = detectVaultable(Entity.Character)
		if not target then return false end

		local character = Entity.Character
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid then return false end

		active = true
		startCooldown(Entity)
		Entity:SetState("Vaulting", true)
		character:SetAttribute("Vaulting", true)

		local existing = hrp:FindFirstChild("DashVelocity")
		if existing then existing:Destroy() end

		playVaultSound(hrp)

		local vaultVel = Instance.new("BodyVelocity")
		vaultVel.Name = "VaultVelocity"
		vaultVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		vaultVel.Velocity = hrp.CFrame.LookVector * CFG.ForwardImpulse + Vector3.new(0, CFG.UpwardImpulse, 0)
		vaultVel.Parent = hrp
		Debris:AddItem(vaultVel, CFG.VelocityDuration)

		playVaultAnim(humanoid)

		local camera = workspace.CurrentCamera
		if camera then
			local baseFOV = camera.FieldOfView
			TweenService:Create(camera, TweenInfo.new(CFG.FOVKickIn, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				FieldOfView = baseFOV + CFG.FOVKickAmount,
			}):Play()
			task.delay(CFG.FOVKickIn, function()
				if camera and camera.Parent then
					TweenService:Create(camera, TweenInfo.new(CFG.FOVKickOut, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
						FieldOfView = baseFOV,
					}):Play()
				end
			end)
		end

		task.delay(CFG.VelocityDuration, function()
			if Entity.MovementHandler then
				Entity.MovementHandler:SetAbsolute("VaultBoost", {
					WalkSpeed = CFG.LandingWalkSpeed,
					Priority = 3,
				}, CFG.LandingBoostDuration)
			end
			active = false
			Entity:SetState("Vaulting", nil)
			if character.Parent then
				character:SetAttribute("Vaulting", false)
			end
		end)

		return true
	end

	State["Enter"] = function(self) end
	State["Update"] = function(self) end
	State["Exit"] = function(self) end

	return State
end
