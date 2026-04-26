return function(Client)
	local player = Client.player
	local Lighting = game:GetService("Lighting")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local TimeConfig = nil
	local configLoaded = false
	local AudioDirector = nil

	local TimeController = {
		currentTime = 8,
		currentDay = 1,
		currentMoonPhase = "Full",
		currentTimeState = "Day", -- NEW: Track Day/Night/Dawn/Dusk

		atmosphere = nil,
		sky = nil,
		colorCorrection = nil,
		bloom = nil,
		sunRays = nil,

		remotes = nil,
		updateConnection = nil,
		initialized = false,
	}

	-- NEW: Get time state from clock time
	local function getTimeState(clockTime)
		if clockTime >= 5 and clockTime < 7 then
			return "Dawn"
		elseif clockTime >= 7 and clockTime < 18 then
			return "Day"
		elseif clockTime >= 18 and clockTime < 20 then
			return "Dusk"
		else
			return "Night"
		end
	end

	local function lerpColor(a, b, t)
		return Color3.new(
			a.R + (b.R - a.R) * t,
			a.G + (b.G - a.G) * t,
			a.B + (b.B - a.B) * t
		)
	end

	local function lerpNumber(a, b, t)
		return a + (b - a) * t
	end

	local function getInterpolatedValue(config, time, property)
		local keys = {}
		for k, _ in pairs(config) do
			table.insert(keys, k)
		end
		table.sort(keys)

		local lowerKey, upperKey
		for i, key in ipairs(keys) do
			if time >= key then
				lowerKey = key
			end
			if time < key and not upperKey then
				upperKey = key
				break
			end
		end

		if not upperKey then upperKey = keys[1] end
		if not lowerKey then lowerKey = keys[#keys] end

		local lowerValue = config[lowerKey] and config[lowerKey][property]
		local upperValue = config[upperKey] and config[upperKey][property]

		if not lowerValue or not upperValue then
			return lowerValue or upperValue
		end

		local range
		if upperKey > lowerKey then
			range = upperKey - lowerKey
		else
			range = (24 - lowerKey) + upperKey
		end

		local progress
		if time >= lowerKey then
			progress = (time - lowerKey) / range
		else
			progress = ((24 - lowerKey) + time) / range
		end

		progress = math.clamp(progress, 0, 1)

		if typeof(lowerValue) == "Color3" then
			return lerpColor(lowerValue, upperValue, progress)
		else
			return lerpNumber(lowerValue, upperValue, progress)
		end
	end

	local function setupLightingEffects()
		TimeController.atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if not TimeController.atmosphere then
			TimeController.atmosphere = Instance.new("Atmosphere")
			TimeController.atmosphere.Parent = Lighting
		end

		TimeController.sky = Lighting:FindFirstChildOfClass("Sky")
		if not TimeController.sky then
			TimeController.sky = Instance.new("Sky")
			TimeController.sky.Parent = Lighting
		end

		TimeController.colorCorrection = Lighting:FindFirstChild("ColorCorrection")
		if not TimeController.colorCorrection then
			TimeController.colorCorrection = Instance.new("ColorCorrectionEffect")
			TimeController.colorCorrection.Name = "ColorCorrection"
			TimeController.colorCorrection.Parent = Lighting
		end

		TimeController.bloom = Lighting:FindFirstChild("Bloom")
		if not TimeController.bloom then
			TimeController.bloom = Instance.new("BloomEffect")
			TimeController.bloom.Name = "Bloom"
			TimeController.bloom.Parent = Lighting
		end

		TimeController.sunRays = Lighting:FindFirstChild("SunRays")
		if not TimeController.sunRays then
			TimeController.sunRays = Instance.new("SunRaysEffect")
			TimeController.sunRays.Name = "SunRays"
			TimeController.sunRays.Intensity = 0.1
			TimeController.sunRays.Spread = 0.5
			TimeController.sunRays.Parent = Lighting
		end
	end

	local function updateLighting(time)
		if not configLoaded then return end

		local config = TimeConfig.Lighting.TimeOfDay

		local moonBrightness = 1
		if TimeConfig:IsNightTime(time) then
			moonBrightness = TimeConfig.Moon.PhaseBrightness[TimeController.currentMoonPhase] or 1
		end

		Lighting.ClockTime = time
		Lighting.Ambient = getInterpolatedValue(config, time, "Ambient")
		Lighting.OutdoorAmbient = getInterpolatedValue(config, time, "OutdoorAmbient")
		Lighting.ColorShift_Top = getInterpolatedValue(config, time, "ColorShift_Top")
		Lighting.ColorShift_Bottom = getInterpolatedValue(config, time, "ColorShift_Bottom")
		Lighting.FogColor = getInterpolatedValue(config, time, "FogColor")
		Lighting.FogEnd = getInterpolatedValue(config, time, "FogEnd")
		Lighting.FogStart = getInterpolatedValue(config, time, "FogStart")

		local baseBrightness = getInterpolatedValue(config, time, "Brightness")
		Lighting.Brightness = baseBrightness * moonBrightness

		local atmosConfig = TimeConfig.Lighting.Atmosphere
		if TimeController.atmosphere then
			TimeController.atmosphere.Density = getInterpolatedValue(atmosConfig, time, "Density")
			TimeController.atmosphere.Offset = getInterpolatedValue(atmosConfig, time, "Offset")
			TimeController.atmosphere.Haze = getInterpolatedValue(atmosConfig, time, "Haze")
			TimeController.atmosphere.Glare = getInterpolatedValue(atmosConfig, time, "Glare")
			TimeController.atmosphere.Decay = getInterpolatedValue(atmosConfig, time, "Decay")
		end

		local ccConfig = TimeConfig.Lighting.ColorCorrection
		if TimeController.colorCorrection then
			TimeController.colorCorrection.Saturation = getInterpolatedValue(ccConfig, time, "Saturation")
			TimeController.colorCorrection.Contrast = getInterpolatedValue(ccConfig, time, "Contrast")
			TimeController.colorCorrection.TintColor = getInterpolatedValue(ccConfig, time, "TintColor")
		end

		if TimeController.sunRays then
			local isDay = TimeConfig:IsDayTime(time)
			TimeController.sunRays.Intensity = isDay and 0.1 or 0
		end
	end

	-- NEW: Check for time state changes and notify AudioDirector
	local function checkTimeStateChange(time)
		local newTimeState = getTimeState(time)

		if newTimeState ~= TimeController.currentTimeState then
			TimeController.currentTimeState = newTimeState

			-- Set attribute for other systems to read
			player:SetAttribute("TimeState", newTimeState)

			-- Notify AudioDirector
			if AudioDirector then
				pcall(function()
					AudioDirector:SetTimeState(newTimeState)
				end)
			end
		end
	end

	local function update(delta)
		if not configLoaded then return end

		local timeIncrement = (delta / 60) * TimeConfig.Time.TimeScale / 60
		TimeController.currentTime = (TimeController.currentTime + timeIncrement) % 24

		updateLighting(TimeController.currentTime)
		checkTimeStateChange(TimeController.currentTime)
	end

	local function onTimeSync(data)
		if data.type == "TimeSync" then
			TimeController.currentTime = data.time
			TimeController.currentDay = data.day
			TimeController.currentMoonPhase = data.moonPhase
			checkTimeStateChange(data.time)
		elseif data.type == "NewDay" then
			TimeController.currentDay = data.day
			TimeController.currentMoonPhase = data.moonPhase
		end
	end

	function TimeController:Init()
		if TimeController.initialized then return end

		local success, err = pcall(function()
			TimeConfig = require(ReplicatedStorage.Kits.Nodes.Gameplay.TimeConfig)
			configLoaded = true
		end)

		if not success then
			warn("[TimeController] Failed to load config:", err)
			return
		end

		-- Try to get AudioDirector reference
		pcall(function()
			AudioDirector = require(ReplicatedStorage.Kits.Audio.AudioDirector)
		end)

		setupLightingEffects()

		local folder = ReplicatedStorage:WaitForChild("TimeRemotes", 30)
		if not folder then
			warn("[TimeController] Remotes not found!")
			return
		end

		TimeController.remotes = {
			TimeSync = folder:WaitForChild("TimeSync"),
			RequestState = folder:WaitForChild("RequestState"),
		}

		TimeController.remotes.TimeSync.OnClientEvent:Connect(onTimeSync)

		local initialState = TimeController.remotes.RequestState:InvokeServer()
		if initialState then
			TimeController.currentTime = initialState.time
			TimeController.currentDay = initialState.day
			TimeController.currentMoonPhase = initialState.moonPhase
		end

		-- Set initial time state
		TimeController.currentTimeState = getTimeState(TimeController.currentTime)
		player:SetAttribute("TimeState", TimeController.currentTimeState)

		TimeController.updateConnection = RunService.Heartbeat:Connect(function(delta)
			update(delta)
		end)

		TimeController.initialized = true
	end

	function TimeController:GetCurrentTime()
		return TimeController.currentTime
	end

	function TimeController:GetCurrentDay()
		return TimeController.currentDay
	end

	function TimeController:IsNight()
		return configLoaded and TimeConfig:IsNightTime(TimeController.currentTime)
	end

	function TimeController:IsDay()
		return configLoaded and TimeConfig:IsDayTime(TimeController.currentTime)
	end

	function TimeController:GetTimePeriod()
		return configLoaded and TimeConfig:GetTimePeriod(TimeController.currentTime) or "Unknown"
	end

	-- NEW: Get current time state (Day/Night/Dawn/Dusk)
	function TimeController:GetTimeState()
		return TimeController.currentTimeState
	end

	return TimeController
end