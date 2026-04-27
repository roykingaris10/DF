-- State// Vault
-- Smooth parkour-style hop over fences, railings, and low walls. Triggered
-- automatically on JumpRequest when a vault-able obstacle is in front of the
-- player and they're holding forward. Anchored CFrame arc (quadratic Bezier
-- through an apex) for a clean visual, then un-anchors with forward velocity
-- so momentum carries on landing. One of three random Vault animation
-- variants plays for visual variety.

return function(Client)
	local State = {}
	local player = Client.player

	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
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

	local function buildRaycastParams(character)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {character, workspace.CurrentCamera}
		rp.IgnoreWater = true
		return rp
	end

	-- Forward + downward probe for a vault-able obstacle. Returns a table with
	-- the geometry needed to plan the arc, or nil if no candidate.
	local function detectVaultTarget(character)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local rp = buildRaycastParams(character)

		local origin = hrp.Position
		local forward = hrp.CFrame.LookVector
		local feetY = origin.Y - 3  -- HRP center is ~3 studs above the feet plane

		-- 1) Forward ray at hip height to find the obstacle's near face.
		local frontHit = workspace:Raycast(origin, forward * Cfg.ForwardReach, rp)
		if not frontHit then return nil end

		-- Reject if the obstacle is tagged NoClimb (treat as a hard wall).
		if frontHit.Instance:GetAttribute("NoClimb") then return nil end

		-- 2) Top probe: cast straight down from above the front face to find
		-- the top surface of the obstacle.
		local topProbeOrigin = frontHit.Position
			+ forward * 0.3
			+ Vector3.new(0, Cfg.MaxHeight + 2, 0)
		local topHit = workspace:Raycast(topProbeOrigin, Vector3.new(0, -(Cfg.MaxHeight + 4), 0), rp)
		if not topHit then return nil end
		if topHit.Instance ~= frontHit.Instance and topHit.Instance:GetAttribute("NoClimb") then
			return nil
		end

		local topY = topHit.Position.Y
		local height = topY - feetY
		if height < Cfg.MinHeight or height > Cfg.MaxHeight then
			return nil
		end

		-- 3) Thickness check: from the obstacle top, walk forward and probe
		-- down. The first point at which the probe finds nothing (or hits
		-- something significantly lower) is the far edge.
		local farEdge
		local farEdgeY
		for d = 0.5, Cfg.MaxThickness, 0.5 do
			local probeStart = topHit.Position + forward * d + Vector3.new(0, 1, 0)
			local probe = workspace:Raycast(probeStart, Vector3.new(0, -3, 0), rp)
			if not probe or math.abs(probe.Position.Y - topY) > 1.0 then
				farEdge = topHit.Position + forward * d
				break
			end
		end
		if not farEdge then return nil end

		-- 4) Landing check: from past the far edge at takeoff height, probe
		-- straight down to find the landing surface and confirm reasonable
		-- drop distance + lateral clearance.
		local landingProbeStart = farEdge + forward * Cfg.FarSideClearance + Vector3.new(0, 1, 0)
		local landingHit = workspace:Raycast(landingProbeStart, Vector3.new(0, -(Cfg.MaxLandingDrop + 4), 0), rp)
		if not landingHit then return nil end
		local landingY = landingHit.Position.Y
		if feetY - landingY > Cfg.MaxLandingDrop then return nil end

		-- 5) Lateral clearance: nothing in the way past the far edge at
		-- takeoff height (the player needs to physically fit there).
		local clearanceCheck = workspace:Raycast(farEdge + Vector3.new(0, 1.5, 0), forward * Cfg.FarSideClearance, rp)
		if clearanceCheck then return nil end

		return {
			obstacle = frontHit.Instance,
			frontFace = frontHit.Position,
			top = topHit.Position,
			farEdge = farEdge,
			landingPos = landingHit.Position,
			forward = forward,
			height = height,
		}
	end

	-- Quadratic Bezier through an apex.
	local function arcPos(p0, p1, p2, t)
		local a = p0:Lerp(p1, t)
		local b = p1:Lerp(p2, t)
		return a:Lerp(b, t)
	end

	local function pickVaultAnim(Entity)
		if not (Entity.AnimHandler and Entity.AnimHandler.Fetch) then return nil end
		local variant = math.random(1, 3)
		local track
		pcall(function()
			track = Entity.AnimHandler:Fetch("General/Vault" .. variant)
		end)
		return track
	end

	local function runVault(Entity, target)
		local character = Entity.Character
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid then return end

		active = true
		Entity:SetState("Vaulting", true)
		character:SetAttribute("Vaulting", true)

		-- Freeze normal movement during the arc.
		if Entity.MovementHandler then
			Entity.MovementHandler:SetAbsolute("Vault", {
				WalkSpeed = 0,
				JumpPower = 0,
				Priority = 5,
			}, Cfg.Duration + 0.2)
		end

		local autoRotateBefore = humanoid.AutoRotate
		humanoid.AutoRotate = false
		hrp.Anchored = true
		hrp.AssemblyLinearVelocity = Vector3.zero

		-- Arc control points: start, apex above the obstacle, land on far side.
		local startPos = hrp.Position
		local apex = Vector3.new(
			(target.frontFace.X + target.farEdge.X) / 2,
			target.top.Y + Cfg.ApexClearance + 2,  -- +2 because HRP center is ~2 above feet
			(target.frontFace.Z + target.farEdge.Z) / 2
		)
		local landPos = target.landingPos + Vector3.new(0, 3, 0)  -- HRP above feet

		local lookForward = target.forward
		local function cframeAt(pos)
			return CFrame.new(pos, pos + lookForward)
		end

		-- Animation hook (one of three variants).
		local anim = pickVaultAnim(Entity)
		if anim then
			anim.Priority = Enum.AnimationPriority.Action4
			pcall(function()
				anim:Play()
				-- Match anim playback length roughly to vault duration.
				if anim.Length and anim.Length > 0 then
					anim:AdjustSpeed(anim.Length / Cfg.Duration)
				end
			end)
		end

		-- Drive the arc with a Heartbeat loop.
		local elapsed = 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			local t = math.clamp(elapsed / Cfg.Duration, 0, 1)
			-- Ease in/out for a more natural hop.
			local eased = TweenService:GetValue(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			hrp.CFrame = cframeAt(arcPos(startPos, apex, landPos, eased))

			if t >= 1 then
				conn:Disconnect()

				hrp.Anchored = false
				hrp.AssemblyLinearVelocity = lookForward * Cfg.ExitVelocity
				humanoid.AutoRotate = autoRotateBefore

				if anim then
					pcall(function() anim:Stop(0.15) end)
				end

				active = false
				cooldownUntil = tick() + Cfg.Cooldown
				Entity:SetState("Vaulting", nil)
				if character.Parent then
					character:SetAttribute("Vaulting", false)
				end
				if Entity.MovementHandler then
					Entity.MovementHandler:RemoveAbsolute("Vault")
				end
			end
		end)
	end

	State["TryVault"] = function(self, Params)
		local Entity = getEntity()
		if not Entity or not Entity.Character then return false end
		if active then return false end
		if tick() < cooldownUntil then return false end
		if combatLocked(Entity) then return false end
		if Entity.Character:GetAttribute("Climbing") then return false end
		if Entity.Character:GetAttribute("Mantling") then return false end

		-- Forward-input gate. Don't vault unless the player is actually
		-- moving forward (W on keyboard or a positive forward MoveDirection
		-- on gamepad/mobile).
		local hasForwardInput = UserInputService:IsKeyDown(Enum.KeyCode.W)
		if not hasForwardInput then
			local hum = Entity.Character:FindFirstChildOfClass("Humanoid")
			local moveDir = hum and hum.MoveDirection or Vector3.zero
			if moveDir.Magnitude > 0.1 then
				local hrp = Entity.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local forwardness = moveDir:Dot(hrp.CFrame.LookVector)
					if forwardness > 0.5 then hasForwardInput = true end
				end
			end
		end
		if not hasForwardInput then return false end

		local target = detectVaultTarget(Entity.Character)
		if not target then return false end

		runVault(Entity, target)
		return true
	end

	State["Enter"] = function(self, Params) end
	State["Update"] = function(self, Params) end
	State["Exit"] = function(self, Params) end

	return State
end
