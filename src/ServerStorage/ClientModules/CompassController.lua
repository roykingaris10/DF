return function(Client)
	local CompassController = {}

	local player = Client.player
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local PlayerGui = player:WaitForChild("PlayerGui")
	local UI = PlayerGui:WaitForChild("UI")
	local CompassFrame = UI:WaitForChild("CompassFrame")
	local ScrollingFrame = CompassFrame:WaitForChild("ScrollingFrame")
	local RegionIcon = CompassFrame:FindFirstChild("regionIcon")
	local NameDistance = CompassFrame:FindFirstChild("namedistance")

	local RegionConfig = require(ReplicatedStorage.Kits.Nodes.Data.RegionConfig)

	-- Direction labels
	local DIRECTION_ORDER = {"NW", "N", "NE", "E", "SE", "S", "SW", "W", "NW2", "N2", "NE2"}
	local DIRECTION_DEGREES = {
		N = 0, NE = 45, E = 90, SE = 135,
		S = 180, SW = 225, W = 270, NW = 315,
		N2 = 360, NE2 = 405, NW2 = -45,
	}

	-- Settings
	local REGION_DETECTION_RANGE = 400
	local COMPASS_HALF_WIDTH = 180
	local SMOOTH_FACTOR = 15
	local CENTER_SCALE = 1.15
	local EDGE_SCALE = 0.75
	local CENTER_ALPHA = 1
	local EDGE_ALPHA = 0.3
	local DEFAULT_VERTICAL_LENIENCY = 500
	local REGION_PRIORITY = {"Special", "Minor", "Major"}

	-- State
	local currentHeading = 0
	local directionLabels = {}
	local regionParts = {}
	local trackedRegion = nil
	local currentRegionName = nil
	local regionMarker = nil
	local heartbeatConn = nil
	local tickMarkPool = {}

	local function normalizeAngle(angle)
		while angle > 180 do angle = angle - 360 end
		while angle < -180 do angle = angle + 360 end
		return angle
	end

	local function normalizeAngle360(angle)
		while angle >= 360 do angle = angle - 360 end
		while angle < 0 do angle = angle + 360 end
		return angle
	end
	
	local function openCompass()
		local CompassFrame = UI:WaitForChild("CompassFrame")
		CompassFrame.Visible = true
	end

	local function lerpAngle(from, to, t)
		local diff = normalizeAngle(to - from)
		return from + diff * t
	end

	local function getCameraHeading()
		local camera = workspace.CurrentCamera
		if not camera then return 0 end
		local look = camera.CFrame.LookVector
		local heading = math.deg(math.atan2(look.X, look.Z))
		return normalizeAngle360(-heading)
	end

	local function getPlayerPosition()
		local char = player.Character
		if not char then return nil end
		local root = char:FindFirstChild("HumanoidRootPart")
		return root and root.Position or nil
	end

	-- Horizontal-first containment: matches RegionService server logic.
	-- Y is generous by default so regions on hills/elevated terrain still detect.
	-- Set the part's "Bounded3D" attribute to require strict 3D containment,
	-- or "VerticalLeniency" (number) to override the default tolerance.
	local function isPointInPart(point, part)
		local relative = part.CFrame:PointToObjectSpace(point)
		local size = part.Size / 2

		if math.abs(relative.X) > size.X or math.abs(relative.Z) > size.Z then
			return false
		end

		if part:GetAttribute("Bounded3D") then
			return math.abs(relative.Y) <= size.Y
		end

		local leniency = part:GetAttribute("VerticalLeniency") or DEFAULT_VERTICAL_LENIENCY
		return math.abs(relative.Y) <= size.Y + leniency
	end

	-- Horizontal distance (XZ plane) to the box outline. Returns 0 if inside in XZ.
	-- Compass cares about heading + ground-plane distance, not vertical separation.
	local function getDistanceToBox(playerPos, part)
		local relative = part.CFrame:PointToObjectSpace(playerPos)
		local size = part.Size / 2

		local dx = math.max(0, math.abs(relative.X) - size.X)
		local dz = math.max(0, math.abs(relative.Z) - size.Z)

		return math.sqrt(dx * dx + dz * dz)
	end

	local function cacheRegionParts()
		regionParts = {}
		local regionsFolder = workspace:FindFirstChild("Regions")
		if not regionsFolder then return end

		for _, typeName in ipairs(REGION_PRIORITY) do
			local typeFolder = regionsFolder:FindFirstChild(typeName)
			if typeFolder then
				for _, part in ipairs(typeFolder:GetChildren()) do
					if not part:IsA("BasePart") then
						warn(("[CompassController] %s/%s is %s, expected BasePart — skipping"):format(typeName, part.Name, part.ClassName))
						continue
					end
					local config = RegionConfig:GetRegion(typeName, part.Name)
					if not config then
						warn(("[CompassController] No config for %s/%q — check spelling/case in RegionConfig"):format(typeName, part.Name))
						continue
					end
					-- Type-prefixed key prevents same-named regions across
					-- types from silently overwriting each other.
					local key = typeName .. "/" .. part.Name
					regionParts[key] = {
						name = part.Name,
						part = part,
						config = config,
						regionType = typeName,
					}
				end
			end
		end
	end

	local function setupDirectionLabels()
		directionLabels = {}
		for _, name in ipairs(DIRECTION_ORDER) do
			local label = ScrollingFrame:FindFirstChild(name)
			if label and label:IsA("TextLabel") then
				label.AnchorPoint = Vector2.new(0.5, 0.5)
				directionLabels[name] = {
					label = label,
					degrees = DIRECTION_DEGREES[name] or 0,
					baseSize = label.TextSize or 14,
				}
			end
		end
	end

	local function createRegionMarker()
		if regionMarker then return regionMarker end

		local holder = Instance.new("Frame")
		holder.Name = "RegionMarker"
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Size = UDim2.new(0, 80, 0, 40)
		holder.BackgroundTransparency = 1
		holder.Visible = false
		holder.Parent = ScrollingFrame

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.AnchorPoint = Vector2.new(0.5, 1)
		icon.Position = UDim2.new(0.5, 0, 0.45, 0)
		icon.Size = UDim2.new(0, 10, 0, 10)
		icon.BackgroundTransparency = 1
		icon.Image = "rbxassetid://7733715400"
		icon.ImageColor3 = Color3.fromRGB(255, 200, 100)
		icon.Parent = holder

		local distLabel = Instance.new("TextLabel")
		distLabel.Name = "DistanceLabel"
		distLabel.AnchorPoint = Vector2.new(0.5, 0)
		distLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		distLabel.Size = UDim2.new(1, 0, 0.5, 0)
		distLabel.BackgroundTransparency = 1
		distLabel.Text = "0m"
		distLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		distLabel.Font = Enum.Font.GothamBold
		distLabel.TextSize = 10
		distLabel.Parent = holder

		regionMarker = holder
		return holder
	end

	local function updateCompass(dt)
		local targetHeading = getCameraHeading()
		currentHeading = lerpAngle(currentHeading, targetHeading, math.min(1, dt * SMOOTH_FACTOR))

		local frameWidth = ScrollingFrame.AbsoluteSize.X
		local centerX = frameWidth / 2
		local pixelsPerDegree = frameWidth / (COMPASS_HALF_WIDTH * 2)

		-- Update direction labels
		for name, data in pairs(directionLabels) do
			local label = data.label
			local degrees = data.degrees

			local diff = normalizeAngle(degrees - currentHeading)
			local posX = centerX + (diff * pixelsPerDegree)

			if math.abs(diff) <= COMPASS_HALF_WIDTH then
				label.Visible = true
				label.Position = UDim2.new(0, posX, 0.5, 0)

				local t = math.abs(diff) / COMPASS_HALF_WIDTH
				local scale = CENTER_SCALE - (CENTER_SCALE - EDGE_SCALE) * t
				local alpha = CENTER_ALPHA - (CENTER_ALPHA - EDGE_ALPHA) * t

				label.TextSize = data.baseSize * scale
				label.TextTransparency = 1 - alpha
			else
				label.Visible = false
			end
		end

		-- Reposition pooled tick marks instead of recreating every frame.
		-- Skip degrees that have direction labels (every 45°).
		local tickIndex = 0
		for deg = 0, 359, 15 do
			if deg % 45 == 0 then
				continue
			end

			local diff = normalizeAngle(deg - currentHeading)
			if math.abs(diff) <= COMPASS_HALF_WIDTH then
				tickIndex = tickIndex + 1
				local tick = tickMarkPool[tickIndex]
				local posX = centerX + (diff * pixelsPerDegree)
				local t = math.abs(diff) / COMPASS_HALF_WIDTH
				tick.Position = UDim2.new(0, posX, 0.5, 0)
				tick.BackgroundTransparency = t * 0.7
				tick.Visible = true
			end
		end

		for i = tickIndex + 1, #tickMarkPool do
			tickMarkPool[i].Visible = false
		end
	end

	local function setupTickMarks()
		for _, child in ipairs(ScrollingFrame:GetChildren()) do
			if child.Name == "TickMark" then
				child:Destroy()
			end
		end
		tickMarkPool = {}

		-- 16 non-cardinal slots across 360° at 15° spacing.
		for i = 1, 16 do
			local tick = Instance.new("Frame")
			tick.Name = "TickMark"
			tick.AnchorPoint = Vector2.new(0.5, 0)
			tick.BorderSizePixel = 0
			tick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			tick.Size = UDim2.new(0, 1, 0.12, 0)
			tick.Visible = false
			tick.Parent = ScrollingFrame
			tickMarkPool[i] = tick
		end
	end

	local function updateRegionTracking()
		local playerPos = getPlayerPosition()
		if not playerPos then
			trackedRegion = nil
			currentRegionName = nil
			if regionMarker then regionMarker.Visible = false end
			if NameDistance then NameDistance.Visible = false end
			if RegionIcon then RegionIcon.Visible = false end
			return
		end

		-- Determine current region in priority order (Special > Minor > Major)
		-- so the client matches RegionService's server-side resolution.
		currentRegionName = nil
		local currentRegionKey = nil
		for _, typeName in ipairs(REGION_PRIORITY) do
			for key, data in pairs(regionParts) do
				if data.regionType == typeName and isPointInPart(playerPos, data.part) then
					currentRegionName = data.name
					currentRegionKey = key
					break
				end
			end
			if currentRegionKey then break end
		end

		-- Find closest region we're not inside (used for the directional marker)
		local closest = nil
		local closestDist = math.huge

		for key, data in pairs(regionParts) do
			if key == currentRegionKey then
				continue
			end

			local dist = getDistanceToBox(playerPos, data.part)

			if dist < closestDist and dist <= REGION_DETECTION_RANGE then
				closestDist = dist
				closest = {
					name = data.name,
					displayName = data.config.DisplayName or data.name,
					distance = dist,
					part = data.part,
					position = data.part.Position,
					config = data.config,
					regionType = data.regionType,
				}
			end
		end

		trackedRegion = closest

		-- Update top display
		if trackedRegion then
			local color = Color3.fromRGB(255, 255, 255)
			if trackedRegion.config.UIStyle and trackedRegion.config.UIStyle.PrimaryColor then
				color = trackedRegion.config.UIStyle.PrimaryColor
			end

			if NameDistance then
				NameDistance.Text = trackedRegion.displayName .. "  " .. math.floor(trackedRegion.distance) .. "m"
				NameDistance.TextColor3 = color
				NameDistance.Visible = true
			end

			if RegionIcon then
				if trackedRegion.config.UIStyle and trackedRegion.config.UIStyle.Icon and trackedRegion.config.UIStyle.Icon ~= "rbxassetid://" then
					RegionIcon.Image = trackedRegion.config.UIStyle.Icon
					RegionIcon.ImageColor3 = color
					RegionIcon.Visible = true
				else
					RegionIcon.Visible = false
				end
			end
		else
			if NameDistance then NameDistance.Visible = false end
			if RegionIcon then RegionIcon.Visible = false end
		end
	end

	local function updateRegionMarker()
		if not regionMarker then return end
		if not trackedRegion then
			regionMarker.Visible = false
			return
		end

		local playerPos = getPlayerPosition()
		if not playerPos then
			regionMarker.Visible = false
			return
		end

		-- Calculate direction to region center
		local direction = (trackedRegion.position - playerPos)
		local regionHeading = math.deg(math.atan2(direction.X, direction.Z))
		regionHeading = normalizeAngle360(-regionHeading)

		local diff = normalizeAngle(regionHeading - currentHeading)

		local frameWidth = ScrollingFrame.AbsoluteSize.X
		local centerX = frameWidth / 2
		local pixelsPerDegree = frameWidth / (COMPASS_HALF_WIDTH * 2)

		if math.abs(diff) <= COMPASS_HALF_WIDTH - 10 then
			local posX = centerX + (diff * pixelsPerDegree)
			local t = math.abs(diff) / COMPASS_HALF_WIDTH

			regionMarker.Position = UDim2.new(0, posX, 0.65, 0)
			regionMarker.Visible = true

			local color = Color3.fromRGB(255, 200, 100)
			if trackedRegion.config.UIStyle and trackedRegion.config.UIStyle.PrimaryColor then
				color = trackedRegion.config.UIStyle.PrimaryColor
			end

			local icon = regionMarker:FindFirstChild("Icon")
			local distLabel = regionMarker:FindFirstChild("DistanceLabel")

			if icon then
				icon.ImageColor3 = color
				icon.ImageTransparency = t * 0.5
			end

			if distLabel then
				distLabel.Text = math.floor(trackedRegion.distance) .. "m"
				distLabel.TextColor3 = color
				distLabel.TextTransparency = t * 0.5
			end
		else
			regionMarker.Visible = false
		end
	end

	local frameCounter = 0
	local function mainLoop(dt)
		frameCounter = frameCounter + 1

		updateCompass(dt)
		updateRegionMarker()

		if frameCounter % 10 == 0 then
			updateRegionTracking()
		end
	end
	
	function CompassController.Open()
		local CompassFrame = UI:WaitForChild("CompassFrame")
		CompassFrame.Visible = true
	end
	
	function CompassController.Close()
		local CompassFrame = UI:WaitForChild("CompassFrame")
		CompassFrame.Visible = false
	end

	function CompassController:Init()
		ScrollingFrame.ClipsDescendants = true
		ScrollingFrame.ScrollingEnabled = false
		ScrollingFrame.ScrollBarThickness = 0

		cacheRegionParts()
		setupDirectionLabels()
		setupTickMarks()
		createRegionMarker()

		currentHeading = getCameraHeading()

		heartbeatConn = RunService.Heartbeat:Connect(mainLoop)
		
		openCompass()

		print("[CompassController] Initialized")
	end

	function CompassController:Cleanup()
		if heartbeatConn then
			heartbeatConn:Disconnect()
			heartbeatConn = nil
		end
		if regionMarker then
			regionMarker:Destroy()
			regionMarker = nil
		end
		for _, tick in ipairs(tickMarkPool) do
			tick:Destroy()
		end
		tickMarkPool = {}
	end

	return CompassController
end