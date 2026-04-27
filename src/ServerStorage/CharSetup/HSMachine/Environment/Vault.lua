-- State// Vault
-- Parkour hop over fences and low walls, faithful to the original game's
-- BodyVelocity-driven pattern (no anchoring → no character tilt). Detection
-- is the original two-ray check: a forward ray to find the obstacle face and
-- an overhead ray to confirm there's clearance to vault through. Plays one
-- of three Vault animations at random, falling back to a direct LoadAnimation
-- if the AnimHandler isn't preloaded for this name.

return function(Client)
	local State = {}
	local player = Client.player

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local Debris = game:GetService("Debris")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local ScalingConfig = require(ReplicatedStorage.Kits.Nodes.Data.ScalingConfig)
	local Cfg = ScalingConfig.Vault

	local cooldownUntil = 0
	local active = false

	local function getEntity()
		return Client.Entity
	end

	local function combatLocked(Entity)
		for _, flag in ipairs(ScalingConfig.BlockingStates) do
			if Entity.CombatData and Entity.CombatData[flag] then return true end
		end
		if Entity.Character and Entity.Character:GetAttribute("Stunned") then return true end
		return false
	end

	local function highestY(part)
		return part.Position.Y + (part.Size.Y / 2)
	end

	local function buildRayParams(character)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {character, workspace.CurrentCamera}
		rp.IgnoreWater = true
		return rp
	end

	-- Original detection (improved): a forward ray from slightly below HRP
	-- center finds the obstacle's near face; an overhead ray confirms there's
	-- nothing to bonk on the way through. The obstacle's top must sit within
	-- the configured height window relative to HRP's vertical center.
	local function detectVaultable(character)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local head = character:FindFirstChild("Head")
		if not hrp or not head then return nil end

		local rp = buildRayParams(character)
		local lowOrigin = hrp.Position - Vector3.new(0, 1, 0)
		local frontRay = workspace:Raycast(lowOrigin, hrp.CFrame.LookVector * Cfg.ForwardReach, rp)
		if not frontRay then return nil end

		local part = frontRay.Instance
		if part:GetAttribute("NoVault") then return nil end
		if part:GetAttribute("NoClimb") then return nil end

		-- Overhead clearance: from above the head, a forward ray. If something
		-- blocks (a ceiling, an awning, a tall wall extension), we can't vault.
		local highOrigin = head.Position + Vector3.new(0, 1, 0)
		local overheadRay = workspace:Raycast(highOrigin, head.CFrame.LookVector * (Cfg.ForwardReach + 0.5), rp)
		if overheadRay then return nil end

		-- Height check: top of obstacle relative to HRP center.
		-- Original rule: highestY(part) - HRP.Y < 1.
		-- Generalised here to a window so we can refuse curbs (too low) or
		-- chest-high walls that would belong to the Mantle path.
		local heightAboveCenter = highestY(part) - hrp.Position.Y
		-- HRP center -> feet is ~3 studs; convert MinHeight/MaxHeight (above
		-- feet) into the same frame as heightAboveCenter (above HRP center).
		local minAboveCenter = Cfg.MinHeight - 3
		local maxAboveCenter = Cfg.MaxHeight - 3
		if heightAboveCenter < minAboveCenter or heightAboveCenter > maxAboveCenter then
			return nil
		end

		return {
			part = part,
			heightAboveCenter = heightAboveCenter,
		}
	end

	-- Animation tracks. Loaded once per Animator (re-loaded after respawn) and
	-- kept alive by parenting the Animation Instances to the Animator so
	-- Roblox can't GC them mid-playback. Priority is Action3 to ensure we
	-- override the Humanoid's default Jump/FreeFalling animations (which in
	-- this game's AnimationData are set to id=1 placeholders that render as
	-- the broken "limbs in torso" pose).
	local cachedTracks = nil
	local cachedAnimator = nil

	local function loadVaultTracks(Entity)
		local character = Entity.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not animator then return nil end

		-- Re-load if the animator changed (character respawn invalidates cache).
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
				anim.Parent = animator  -- keeps the Animation alive for the track
				local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
				if ok and track then
					track.Priority = Enum.AnimationPriority.Action3
					table.insert(tracks, track)
				end
			end
		end

		cachedTracks = #tracks > 0 and tracks or nil
		return cachedTracks
	end

	local function playVaultAnim(Entity)
		local tracks = loadVaultTracks(Entity)
		if not tracks or #tracks == 0 then
			warn("[Vault] No vault animations could be loaded — check Client.AnimationData.General.Vault1/2/3 IDs")
			return
		end

		local track = tracks[math.random(1, #tracks)]
		-- If the same track is replayed before the previous play has ended,
		-- Stop(0) it first so Play() restarts cleanly.
		if track.IsPlaying then
			track:Stop(0)
		end
		track:Play()
		track:AdjustSpeed(Cfg.AnimSpeed)
	end

	local function runVault(Entity, target)
		local character = Entity.Character
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		active = true
		Entity:SetState("Vaulting", true)
		character:SetAttribute("Vaulting", true)

		-- Clear any conflicting velocity (existing dashes etc.).
		local existing = hrp:FindFirstChild("DashVelocity")
		if existing then existing:Destroy() end

		-- Reset accumulated angular velocity and snap upright on the
		-- horizontal plane. We deliberately don't touch Humanoid.AutoRotate
		-- — this framework drives that property from a character attribute
		-- (CharacterHandler) and any direct manipulation gets overwritten,
		-- which previously left AutoRotate stuck off after a vault.
		hrp.AssemblyAngularVelocity = Vector3.zero
		local lookVec = hrp.CFrame.LookVector
		local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z)
		if flatLook.Magnitude > 0.01 then
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flatLook.Unit)
		end

		-- Pre-clear the obstacle. When the player is very close to the wall,
		-- the upper half of HRP collides with the wall top and the collision
		-- resolution torque tumbles them forward (the "45° tilt" symptom).
		-- Snap up so the whole HRP sits above the top before forward velocity.
		local heightAboveCenter = (target and target.heightAboveCenter) or 0
		local preClear = Cfg.PreClearOffset or 1.5
		local snapUp = math.max(0, heightAboveCenter + preClear)
		if snapUp > 0 then
			hrp.CFrame = hrp.CFrame + Vector3.new(0, snapUp, 0)
		end

		-- BodyVelocity hop. Matches the original game's tuning: forward push
		-- + upward pop, lasts long enough to clear a fence then physics takes
		-- over for the landing.
		local vaultVel = Instance.new("BodyVelocity")
		vaultVel.Name = "VaultVelocity"
		vaultVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		vaultVel.Velocity = hrp.CFrame.LookVector * Cfg.ForwardImpulse
			+ Vector3.new(0, Cfg.UpwardImpulse, 0)
		vaultVel.Parent = hrp
		Debris:AddItem(vaultVel, Cfg.VelocityDuration)

		-- Hold orientation against in-flight torque. Moderate force absorbs
		-- collision tumble without locking so rigidly that landing physics
		-- break. Self-cleans via Debris just past the velocity window.
		local vaultGyro = Instance.new("BodyGyro")
		vaultGyro.Name = "VaultGyro"
		vaultGyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
		vaultGyro.P = 3000
		vaultGyro.D = 500
		vaultGyro.CFrame = hrp.CFrame
		vaultGyro.Parent = hrp
		Debris:AddItem(vaultGyro, Cfg.VelocityDuration + 0.1)

		playVaultAnim(Entity)

		-- Clear vault flags after the velocity window. Belt-and-suspenders
		-- destroys the constraints in case Debris hasn't gotten to them yet.
		task.delay(Cfg.VelocityDuration + 0.05, function()
			if vaultVel and vaultVel.Parent then vaultVel:Destroy() end
			if vaultGyro and vaultGyro.Parent then vaultGyro:Destroy() end
			active = false
			cooldownUntil = tick() + Cfg.Cooldown
			Entity:SetState("Vaulting", nil)
			if character.Parent then
				character:SetAttribute("Vaulting", false)
			end
		end)
	end

	local function hasForwardInput(character)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then return true end
		local hum = character:FindFirstChildOfClass("Humanoid")
		local moveDir = hum and hum.MoveDirection or Vector3.zero
		if moveDir.Magnitude < 0.1 then return false end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end
		return moveDir:Dot(hrp.CFrame.LookVector) > 0.5
	end

	State["TryVault"] = function(self, Params)
		local Entity = getEntity()
		if not Entity or not Entity.Character then return false end
		if active then return false end
		if tick() < cooldownUntil then return false end
		if combatLocked(Entity) then return false end
		if Entity.Character:GetAttribute("Climbing") then return false end
		if Entity.Character:GetAttribute("Mantling") then return false end

		if not hasForwardInput(Entity.Character) then return false end

		local target = detectVaultable(Entity.Character)
		if not target then return false end

		runVault(Entity, target)
		return true
	end

	State["Enter"] = function(self, Params) end
	State["Update"] = function(self, Params) end
	State["Exit"] = function(self, Params) end

	return State
end
