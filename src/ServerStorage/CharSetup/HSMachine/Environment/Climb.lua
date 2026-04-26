-- State// Climb
-- Wall cling + directional climb + wall-jump release.
-- Hold the climb input near a climbable wall to grip it. Movement keys then
-- drive vertical/horizontal motion along the wall plane. Stamina drains while
-- engaged; running out auto-disengages. Press jump to wall-jump off.

return function(Client)
	local State = {}
	local player = Client.player

	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Trove = require(ReplicatedStorage.Kits.Nodes.Utility.Trove)
	local ScalingConfig = require(ReplicatedStorage.Kits.Nodes.Data.ScalingConfig)

	local Surfaces = ScalingConfig.Surfaces
	local Cfg = ScalingConfig.Climb
	local StaminaCfg = ScalingConfig.Stamina
	local WallJumpCfg = ScalingConfig.WallJump

	-- Module-scoped session state. The local player only ever has one climb
	-- session at a time; this lives outside any single state-machine
	-- invocation so wall-jump regrip cooldowns survive session boundaries.
	local session = nil
	local regripCooldownPart = nil
	local regripCooldownUntil = 0

	local function getEntity()
		return Client.Entity
	end

	local function isPartClimbable(part)
		if not part then return false end
		if part:GetAttribute("NoClimb") then return false end
		if part:GetAttribute("Climbable") then return true end
		for _, ignoreName in ipairs(Surfaces.IgnoreFolders) do
			if part:FindFirstAncestor(ignoreName) then return false end
		end
		return Surfaces.WhitelistedMaterials[part.Material] == true
	end

	local function buildRaycastParams(character)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {character, workspace.CurrentCamera}
		rp.IgnoreWater = true
		return rp
	end

	-- Look forward for a climbable wall whose normal is roughly vertical.
	local function probeWall(character)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		local rp = buildRaycastParams(character)
		local origin = hrp.Position
		local forward = hrp.CFrame.LookVector
		local hit = workspace:Raycast(origin, forward * Cfg.GripRange, rp)
		if not hit then return nil end
		if not isPartClimbable(hit.Instance) then return nil end

		-- Wall normal must be mostly horizontal (i.e., the surface is vertical).
		-- WallVerticalThreshold is the minimum |XZ-component|; a perfectly
		-- vertical wall has normal.Y ≈ 0, |XZ| ≈ 1.
		local horizontalMag = math.sqrt(hit.Normal.X * hit.Normal.X + hit.Normal.Z * hit.Normal.Z)
		if horizontalMag < Cfg.WallVerticalThreshold then return nil end

		return {
			point = hit.Position,
			normal = hit.Normal,
			part = hit.Instance,
		}
	end

	local function combatLocked(Entity)
		for _, flag in ipairs(ScalingConfig.BlockingStates) do
			if Entity.CombatData and Entity.CombatData[flag] then return true end
		end
		if Entity.Character and Entity.Character:GetAttribute("Stunned") then return true end
		return false
	end

	local function ensureStamina(Entity)
		if Entity.ScalingStamina == nil then
			Entity.ScalingStamina = StaminaCfg.Max
		end
	end

	-- Drive the character along the wall plane each Heartbeat. Reads input
	-- directly off UserInputService to avoid coupling to any specific input
	-- binding scheme — Inputter just toggles the state on/off.
	local function buildClimbBasis(wallNormal)
		-- Up axis is world-up projected onto the wall plane.
		local worldUp = Vector3.new(0, 1, 0)
		local wallUp = (worldUp - wallNormal * worldUp:Dot(wallNormal)).Unit
		local wallRight = wallUp:Cross(wallNormal).Unit
		return wallUp, wallRight
	end

	local function readMoveInput()
		local up = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
			- (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
		local side = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
			- (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
		return up, side
	end

	local function scaleVerticalSpeed(verticalInput)
		if verticalInput > 0 then return Cfg.UpSpeed * verticalInput end
		return Cfg.DownSpeed * verticalInput  -- negative
	end

	local function release(reason)
		if not session then return end
		local Entity = getEntity()
		local character = session.character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")

		session.trove:Destroy()

		if hrp then
			hrp.Anchored = false
		end
		if Entity and Entity.MovementHandler then
			Entity.MovementHandler:RemoveAbsolute("Climb")
		end
		if Entity then
			Entity:SetState("Climbing", nil)
			if Entity.Character and Entity.Character.Parent then
				Entity.Character:SetAttribute("Climbing", false)
			end
		end
		if session.clingAnim then
			pcall(function() session.clingAnim:Stop(0.15) end)
		end

		-- Cooldown to prevent immediate regrip on the same wall during a wall-jump.
		if reason == "walljump" and session.wallPart then
			regripCooldownPart = session.wallPart
			regripCooldownUntil = tick() + WallJumpCfg.NoRegripTime
		end

		local lastSession = session
		session = nil
		return lastSession
	end

	local function startClimb(self, wallInfo)
		local Entity = getEntity()
		if not Entity or not Entity.Character then return false end
		ensureStamina(Entity)

		if Entity.ScalingStamina < StaminaCfg.MinToCling then return false end
		if combatLocked(Entity) then return false end

		local character = Entity.Character
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end

		-- Position the character clinging to the wall: face into the wall,
		-- offset back by ClingOffset so we're not embedded in the part.
		local intoWall = -wallInfo.normal
		local clingPos = wallInfo.point + wallInfo.normal * Cfg.ClingOffset
			-- Keep current Y; we'll let the user move vertically.
		clingPos = Vector3.new(clingPos.X, hrp.Position.Y, clingPos.Z)
		local clingCFrame = CFrame.new(clingPos, clingPos + intoWall)

		-- Anchor briefly while we attach so the snap doesn't get fought by
		-- physics. Released on first climb tick.
		hrp.Anchored = true
		hrp.CFrame = clingCFrame

		if Entity.MovementHandler then
			Entity.MovementHandler:SetAbsolute("Climb", {
				WalkSpeed = 0,
				JumpPower = 0,
				Priority = 5,
			})
		end
		Entity:SetState("Climbing", true)
		character:SetAttribute("Climbing", true)

		local clingAnim
		if Entity.AnimHandler and Entity.AnimHandler.Fetch then
			pcall(function()
				clingAnim = Entity.AnimHandler:Fetch("Environment/ClingIdle")
			end)
			if clingAnim then
				clingAnim.Priority = Enum.AnimationPriority.Action3
				pcall(function() clingAnim:Play() end)
			end
		end

		local trove = Trove.new()
		session = {
			character = character,
			wallPart = wallInfo.part,
			wallNormal = wallInfo.normal,
			clingAnim = clingAnim,
			trove = trove,
			lastProgressTime = tick(),
			lastPos = hrp.Position,
			attachedAt = tick(),
		}

		trove:Connect(RunService.Heartbeat, function(dt)
			if not session then return end
			if not character or not character.Parent then release("dead") return end
			if combatLocked(Entity) then release("combat") return end

			-- After AttachTime, hand control back from the anchor.
			if hrp.Anchored and tick() - session.attachedAt >= Cfg.AttachTime then
				hrp.Anchored = false
			end

			-- Re-probe the wall: if we've drifted off (e.g., end of the wall,
			-- door, gap), drop.
			local probe = probeWall(character)
			if not probe or not isPartClimbable(probe.part) then
				release("nowall") return
			end
			session.wallNormal = probe.normal
			session.wallPart = probe.part

			-- Drain stamina based on whether we're actively moving.
			local upInput, sideInput = readMoveInput()
			local moving = upInput ~= 0 or sideInput ~= 0
			local drain = moving and StaminaCfg.ClimbDrainPerSecond or StaminaCfg.ClingDrainPerSecond
			Entity.ScalingStamina = math.max(0, Entity.ScalingStamina - drain * dt)
			if Entity.ScalingStamina <= 0 then
				release("exhausted") return
			end

			-- Compute movement along the wall plane.
			local wallUp, wallRight = buildClimbBasis(session.wallNormal)
			local verticalSpeed = scaleVerticalSpeed(upInput)
			local sideSpeed = sideInput * Cfg.SidewaysSpeed
			local desired = wallUp * verticalSpeed + wallRight * sideSpeed

			if hrp.Anchored then
				-- During attach window, slide via direct CFrame.
				hrp.CFrame = hrp.CFrame + desired * dt
			else
				-- Hold position against the wall via direct velocity assignment.
				-- Cancels gravity (we're clinging), sets desired wall-plane velocity.
				hrp.AssemblyLinearVelocity = desired
			end

			-- Re-snap to maintain ClingOffset along the wall normal.
			local toWall = probe.point - hrp.Position
			local distanceAlongNormal = toWall:Dot(session.wallNormal)
			local desiredOffset = -distanceAlongNormal + Cfg.ClingOffset
			if math.abs(desiredOffset) > 0.05 then
				hrp.CFrame = hrp.CFrame + session.wallNormal * desiredOffset
			end
			-- Face into the wall.
			local intoWall2 = -session.wallNormal
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + intoWall2)

			-- Stuck detection: if the user has been holding input but hasn't
			-- moved meaningfully, drop after a timeout (likely up against a
			-- ceiling or wall edge).
			if moving then
				local progress = (hrp.Position - session.lastPos).Magnitude
				if progress > 0.15 then
					session.lastProgressTime = tick()
					session.lastPos = hrp.Position
				elseif tick() - session.lastProgressTime > Cfg.StuckTimeout then
					release("stuck") return
				end
			else
				session.lastPos = hrp.Position
				session.lastProgressTime = tick()
			end
		end)

		return true
	end

	-- Public API actions

	State["StartClimb"] = function(self, Params)
		local Entity = getEntity()
		if not Entity or not Entity.Character then return false end
		ensureStamina(Entity)

		if session then return false end  -- already climbing
		if combatLocked(Entity) then return false end
		if Entity.ScalingStamina < StaminaCfg.MinToCling then return false end

		local probe = probeWall(Entity.Character)
		if not probe then return false end

		-- Honor regrip cooldown after a wall-jump on the same wall.
		if regripCooldownPart == probe.part and tick() < regripCooldownUntil then
			return false
		end

		Entity.StateMachine:ChangeState("Environment", "Climb")
		return startClimb(self, probe)
	end

	State["Release"] = function(self, Params)
		release("input")
	end

	State["WallJump"] = function(self, Params)
		if not session then return false end
		local Entity = getEntity()
		local character = session.character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then release("dead") return false end
		if Entity.ScalingStamina < StaminaCfg.WallJumpCost then
			release("exhausted") return false
		end
		Entity.ScalingStamina = math.max(0, Entity.ScalingStamina - StaminaCfg.WallJumpCost)

		-- Pick an away-from-wall jump direction biased by player input. If no
		-- side input, push straight off the wall.
		local _, sideInput = readMoveInput()
		local wallUp, wallRight = buildClimbBasis(session.wallNormal)
		local awayDir = (session.wallNormal + wallRight * sideInput * 0.4).Unit
		local impulse = awayDir * WallJumpCfg.HorizontalImpulse + wallUp * WallJumpCfg.VerticalImpulse

		hrp.AssemblyLinearVelocity = impulse

		release("walljump")

		if Entity.AnimHandler and Entity.AnimHandler.Fetch then
			local anim
			pcall(function()
				anim = Entity.AnimHandler:Fetch("Environment/WallJump")
			end)
			if anim then
				anim.Priority = Enum.AnimationPriority.Action4
				pcall(function() anim:Play() end)
			end
		end

		return true
	end

	-- Background regen tick: regenerates stamina when grounded and not climbing.
	-- Connected once per Climb state instantiation, lives for the player's
	-- session.
	do
		local last = tick()
		RunService.Heartbeat:Connect(function()
			local Entity = getEntity()
			if not Entity or not Entity.Character then return end
			ensureStamina(Entity)

			local now = tick()
			local dt = now - last
			last = now

			if session then return end  -- drains handled in main loop
			if Entity.ScalingStamina >= StaminaCfg.Max then return end

			local hum = Entity.Character:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			local grounded = hum.FloorMaterial ~= Enum.Material.Air
			local rate = grounded and StaminaCfg.RegenPerSecond
				or StaminaCfg.RegenPerSecond * StaminaCfg.AirRegenMultiplier
			Entity.ScalingStamina = math.min(StaminaCfg.Max, Entity.ScalingStamina + rate * dt)
		end)
	end

	State["Enter"] = function(self, Params) end
	State["Update"] = function(self, Params) end
	State["Exit"] = function(self, Params)
		if session then release("statechange") end
	end

	return State
end
