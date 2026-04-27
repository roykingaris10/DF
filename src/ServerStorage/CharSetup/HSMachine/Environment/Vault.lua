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

	-- Animation loading. Try AnimHandler first for consistency with the rest
	-- of the framework; if the Animation instance for Vault1/2/3 isn't in the
	-- Animations folder, fall back to creating + loading from the asset ID
	-- directly. The fallback keeps the system working even if the Animations
	-- folder hasn't been populated for these tracks yet.
	local loadedAnims = {}  -- cache: variant index -> AnimationTrack

	local function getVaultAnim(Entity, variant)
		if loadedAnims[variant] then return loadedAnims[variant] end

		local track
		if Entity.AnimHandler and Entity.AnimHandler.Fetch then
			pcall(function()
				track = Entity.AnimHandler:Fetch("General/Vault" .. variant)
			end)
		end

		if not track and Client.AnimationData and Client.AnimationData.General then
			local id = Client.AnimationData.General["Vault" .. variant]
			local humanoid = Entity.Character and Entity.Character:FindFirstChildOfClass("Humanoid")
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			if id and animator then
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. tostring(id)
				local ok, result = pcall(function() return animator:LoadAnimation(anim) end)
				if ok then track = result end
			end
		end

		loadedAnims[variant] = track
		return track
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

		-- Random anim variant for visual variety.
		local variant = math.random(1, 3)
		local anim = getVaultAnim(Entity, variant)
		if anim then
			anim.Priority = Enum.AnimationPriority.Action2
			pcall(function()
				anim:Play()
				anim:AdjustSpeed(Cfg.AnimSpeed)
			end)
		end

		-- Release the active flag after the velocity finishes; cooldown runs
		-- from there.
		task.delay(Cfg.VelocityDuration, function()
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
