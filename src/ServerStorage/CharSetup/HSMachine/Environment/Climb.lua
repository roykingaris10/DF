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
	-- Casts a small cone (center + 4 chest-level offsets) so a thin part or
	-- a slight rotation gap can still hold the climb. If `lockedPart` is
	-- given, only accept hits on that exact part — prevents the climb from
	-- silently switching to a nearby surface mid-session.
	local function probeWall(character, lockedPart)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		local rp = buildRaycastParams(character)
		local origin = hrp.Position
		local forward = hrp.CFrame.LookVector
		local right = hrp.CFrame.RightVector
		local up = hrp.CFrame.UpVector

		local offsets = {
			Vector3.zero,
			right * 0.6,
			-right * 0.6,
			up * 0.6,
			-up * 0.6,
		}

		local best
		for _, offset in ipairs(offsets) do
			local hit = workspace:Raycast(origin + offset, forward * Cfg.GripRange, rp)
			if hit then
				local accept = lockedPart and (hit.Instance == lockedPart) or isPartClimbable(hit.Instance)
				if accept then
					local horizontalMag = math.sqrt(hit.Normal.X * hit.Normal.X + hit.Normal.Z * hit.Normal.Z)
					if horizontalMag >= Cfg.WallVerticalThreshold then
						if not best or hit.Distance < best.distance then
							best = {
								point = hit.Position,
								normal = hit.Normal,
								part = hit.Instance,
								distance = hit.Distance,
							}
						end
					end
				end
			end
		end

		return best
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

		print(("[Climb] release(%s)"):format(reason or "?"))

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

		if Entity.ScalingStamina < StaminaCfg.MinToCling then
			print("[Climb] start refused: stamina too low")
			return false
		end
		if combatLocked(Entity) then
			print("[Climb] start refused: combat locked")
			return false
		end

		local character = Entity.Character
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid then return false end

		-- Position the character clinging to the wall: face into the wall,
		-- offset back by ClingOffset so we're not embedded in the part.
		-- intoWall must be flattened to the horizontal plane: if the wall
		-- is even slightly tilted off-vertical, intoWall has a Y component
		-- and CFrame.new(lookAt) ends up tilting the character to match the
		-- wall slope (the "45° lean while climbing" symptom).
		local intoWall = -wallInfo.normal
		local horizInto = Vector3.new(intoWall.X, 0, intoWall.Z)
		horizInto = horizInto.Magnitude > 0.01 and horizInto.Unit or Vector3.new(0, 0, 1)
		local clingPos = wallInfo.point + wallInfo.normal * Cfg.ClingOffset
		clingPos = Vector3.new(clingPos.X, hrp.Position.Y, clingPos.Z)
		local clingCFrame = CFrame.new(clingPos, clingPos + horizInto)

		-- Anchor HRP for the entire climb. We move via CFrame each frame; this
		-- avoids fighting gravity, Humanoid auto-rotation, and collision
		-- resolution. AutoRotate gets disabled too as a belt-and-suspenders.
		hrp.Anchored = true
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = clingCFrame
		humanoid.AutoRotate = false

		local animateScript = character:FindFirstChild("Animate")
		local restoreAnimate = false
		if animateScript and (animateScript:IsA("LocalScript") or animateScript:IsA("Script")) and not animateScript.Disabled then
			animateScript.Disabled = true
			restoreAnimate = true
		end

		local stateBlocks = {
			Enum.HumanoidStateType.Freefall,
			Enum.HumanoidStateType.Jumping,
			Enum.HumanoidStateType.Climbing,
			Enum.HumanoidStateType.FallingDown,
			Enum.HumanoidStateType.Ragdoll,
			Enum.HumanoidStateType.GettingUp,
		}
		local restoreStates = {}
		for _, st in ipairs(stateBlocks) do
			restoreStates[st] = humanoid:GetStateEnabled(st)
			humanoid:SetStateEnabled(st, false)
		end
		humanoid:ChangeState(Enum.HumanoidStateType.Running)

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
			humanoid = humanoid,
			wallPart = wallInfo.part,
			wallNormal = wallInfo.normal,
			clingAnim = clingAnim,
			trove = trove,
			lastProgressTime = tick(),
			lastPos = hrp.Position,
			missStreak = 0,
		}

		trove:Add(function()
			if humanoid and humanoid.Parent then
				humanoid.AutoRotate = true
				for state, wasEnabled in pairs(restoreStates) do
					humanoid:SetStateEnabled(state, wasEnabled)
				end
			end
			if restoreAnimate and animateScript and animateScript.Parent then
				animateScript.Disabled = false
			end
		end)

		print(("[Climb] start: wall=%s normal=%s"):format(wallInfo.part:GetFullName(), tostring(wallInfo.normal)))

		trove:Connect(RunService.Heartbeat, function(dt)
			if not session then return end
			if not character or not character.Parent then release("dead") return end
			if combatLocked(Entity) then release("combat") return end

			-- Re-probe each tick so leaving the wall (corner, doorway, end of
			-- a wall section) auto-releases the climb. Allow a few consecutive
			-- misses before giving up — a single missed tick during a snap or
			-- a thin face shouldn't drop the climb. Locked to the original
			-- wall part so the cone-cast can't drift to nearby slopes.
			local probe = probeWall(character, session.wallPart)
			if not probe then
				session.missStreak = session.missStreak + 1
				if session.missStreak == 1 then
					print(("[Climb] probe miss #%d at %s look=%s"):format(
						session.missStreak,
						tostring(hrp.Position),
						tostring(hrp.CFrame.LookVector)))
				end
				if session.missStreak >= 6 then
					release("nowall") return
				end
				-- Hold position and wait for the wall to come back into range.
				return
			end
			session.missStreak = 0
			session.wallNormal = probe.normal
			session.wallPart = probe.part

			-- Drain stamina based on whether the player is actively moving.
			local upInput, sideInput = readMoveInput()
			local moving = upInput ~= 0 or sideInput ~= 0
			local drain = moving and StaminaCfg.ClimbDrainPerSecond or StaminaCfg.ClingDrainPerSecond
			Entity.ScalingStamina = math.max(0, Entity.ScalingStamina - drain * dt)
			if Entity.ScalingStamina <= 0 then
				release("exhausted") return
			end

			-- Build wall-plane axes and step the position. We're CFrame-driven
			-- and HRP stays anchored, so this never fights physics.
			local wallUp, wallRight = buildClimbBasis(session.wallNormal)
			local verticalSpeed = scaleVerticalSpeed(upInput)
			local sideSpeed = sideInput * Cfg.SidewaysSpeed
			local stepDelta = (wallUp * verticalSpeed + wallRight * sideSpeed) * dt

			-- Step along the wall plane, then snap normal-distance to ClingOffset.
			--   Goal: (newPos - probe.point) · wallNormal == ClingOffset
			--   currentDot = (newPos - probe.point) · wallNormal
			--   delta = ClingOffset - currentDot
			--   newPos := newPos + wallNormal * delta
			local newPos = hrp.Position + stepDelta
			local currentDot = (newPos - probe.point):Dot(session.wallNormal)
			newPos = newPos + session.wallNormal * (Cfg.ClingOffset - currentDot)

			-- Face into the wall, but only on the horizontal plane. Tilted
			-- walls have a wall normal with a Y component; using it directly
			-- in CFrame.new would lean the character to match the wall slope.
			local intoWall2 = -session.wallNormal
			local horizInto2 = Vector3.new(intoWall2.X, 0, intoWall2.Z)
			horizInto2 = horizInto2.Magnitude > 0.01 and horizInto2.Unit or Vector3.new(0, 0, 1)
			hrp.CFrame = CFrame.new(newPos, newPos + horizInto2)

			-- Stuck detection: holding input but not moving means we're against
			-- a ceiling or the wall ends here — drop after a timeout.
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
		if not Entity or not Entity.Character then
			print("[Climb] StartClimb: no Entity/Character")
			return false
		end
		ensureStamina(Entity)

		if session then
			print("[Climb] StartClimb: already in a climb session")
			return false
		end
		if combatLocked(Entity) then
			print("[Climb] StartClimb: combat-locked")
			return false
		end
		if Entity.ScalingStamina < StaminaCfg.MinToCling then
			print(("[Climb] StartClimb: stamina %.1f < %d"):format(Entity.ScalingStamina, StaminaCfg.MinToCling))
			return false
		end

		local probe = probeWall(Entity.Character)
		if not probe then
			print("[Climb] StartClimb: no climbable wall in front")
			return false
		end

		-- Honor regrip cooldown after a wall-jump on the same wall.
		if regripCooldownPart == probe.part and tick() < regripCooldownUntil then
			print("[Climb] StartClimb: regrip cooldown active on this wall")
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

		-- Compute impulse before release (we still need session.wallNormal).
		-- Bias the away-direction by side input so the player can chain
		-- wall-jumps sideways across a wall.
		local _, sideInput = readMoveInput()
		local wallUp, wallRight = buildClimbBasis(session.wallNormal)
		local awayDir = (session.wallNormal + wallRight * sideInput * 0.4).Unit
		local impulse = awayDir * WallJumpCfg.HorizontalImpulse + wallUp * WallJumpCfg.VerticalImpulse

		-- Release first (un-anchors HRP); only then can AssemblyLinearVelocity
		-- actually take effect.
		release("walljump")
		hrp.AssemblyLinearVelocity = impulse

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
