-- State// Mantle
-- Auto-pull-up when the player jumps into a low ledge. Pure animation/CFrame
-- traversal; no networking dependencies. Triggers from Inputter on jump.

return function(Client)
	local State = {}
	local player = Client.player

	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local ScalingConfig = require(ReplicatedStorage.Kits.Nodes.Data.ScalingConfig)
	local Surfaces = ScalingConfig.Surfaces
	local Cfg = ScalingConfig.Mantle

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

	-- Cast forward and find a ledge: a wall in front + clear space above it
	-- between MinHeight and MaxHeight off the player's feet.
	local function detectLedge(character)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		local rp = buildRaycastParams(character)
		local origin = hrp.Position
		local forward = hrp.CFrame.LookVector
		-- Approx feet level: HRP is centered, so feet are ~3 below.
		local feetY = origin.Y - 3

		local wallHit = workspace:Raycast(origin, forward * Cfg.ForwardReach, rp)
		if not wallHit then return nil end
		if not isPartClimbable(wallHit.Instance) then return nil end

		-- Wall must be roughly vertical.
		if math.abs(wallHit.Normal.Y) > 0.5 then return nil end

		-- Cast straight down from above the wall to find the top surface.
		local topProbeStart = wallHit.Position
			+ forward * 0.5
			+ Vector3.new(0, Cfg.MaxHeight + 2, 0)
		local topHit = workspace:Raycast(topProbeStart, Vector3.new(0, -(Cfg.MaxHeight + 4), 0), rp)
		if not topHit then return nil end

		local ledgeHeight = topHit.Position.Y - feetY
		if ledgeHeight < Cfg.MinHeight or ledgeHeight > Cfg.MaxHeight then
			return nil
		end

		-- Confirm the top has clearance to stand on.
		local clearStart = topHit.Position + Vector3.new(0, 0.5, 0)
		local clearHit = workspace:Raycast(clearStart, forward * Cfg.TopClearance, rp)
		if clearHit then return nil end

		return {
			topPosition = topHit.Position,
			wallNormal = wallHit.Normal,
			height = ledgeHeight,
		}
	end

	State["TryMantle"] = function(self, Params)
		local Entity = getEntity()
		if not Entity or not Entity.Character then return false end
		local character = Entity.Character

		-- Combat lock-outs.
		for _, flag in ipairs(ScalingConfig.BlockingStates) do
			if Entity.CombatData and Entity.CombatData[flag] then return false end
		end
		if character:GetAttribute("Mantling") then return false end

		-- Stamina gate.
		Entity.ScalingStamina = Entity.ScalingStamina or ScalingConfig.Stamina.Max
		if Entity.ScalingStamina < ScalingConfig.Stamina.MantleCost then return false end

		local ledge = detectLedge(character)
		if not ledge then return false end

		Entity.ScalingStamina = math.max(0, Entity.ScalingStamina - ScalingConfig.Stamina.MantleCost)
		Entity:SetState("Mantling", true)
		character:SetAttribute("Mantling", true)

		Entity.StateMachine:ChangeState("Environment", "Mantle")
		State.Run(self, ledge)
		return true
	end

	State["Run"] = function(self, ledge)
		local Entity = getEntity()
		if not Entity then return end
		local character = Entity.Character
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- Lock movement during the tween.
		if Entity.MovementHandler then
			Entity.MovementHandler:SetAbsolute("Mantle", {
				WalkSpeed = 0,
				JumpPower = 0,
				Priority = 5,
			}, Cfg.Duration + 0.1)
		end

		-- Animation hook (silently no-ops if the asset isn't set).
		local mantleAnim
		if Entity.AnimHandler and Entity.AnimHandler.Fetch then
			pcall(function()
				mantleAnim = Entity.AnimHandler:Fetch("Environment/Mantle")
			end)
			if mantleAnim then
				mantleAnim.Priority = Enum.AnimationPriority.Action4
				pcall(function() mantleAnim:Play() end)
			end
		end

		-- Tween HRP from current position up onto the ledge top.
		local forward = -ledge.wallNormal
		local landPos = ledge.topPosition + forward * Cfg.LandForwardOffset + Vector3.new(0, 3, 0)
		local landCFrame = CFrame.new(landPos, landPos + forward)

		-- Anchor briefly so the tween isn't fought by physics, then release.
		hrp.Anchored = true
		local tween = TweenService:Create(
			hrp,
			TweenInfo.new(Cfg.Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = landCFrame }
		)
		tween:Play()

		task.spawn(function()
			tween.Completed:Wait()
			if hrp and hrp.Parent then
				hrp.Anchored = false
			end
			if mantleAnim then
				pcall(function() mantleAnim:Stop(0.15) end)
			end
			Entity:SetState("Mantling", nil)
			if character and character.Parent then
				character:SetAttribute("Mantling", false)
			end
		end)
	end

	State["Enter"] = function(self, Params)
		-- Stateless aside from what TryMantle/Run set up.
	end

	State["Exit"] = function(self, Params)
	end

	State["Update"] = function(self, Params)
	end

	return State
end
