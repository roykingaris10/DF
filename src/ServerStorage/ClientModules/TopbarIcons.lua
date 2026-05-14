return function(Client)
	local TopbarIcons = {}

	local player = Client.player
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local StarterPlayer = game:GetService("StarterPlayer")
	local Players = game:GetService("Players")
	local Stats = game:GetService("Stats")

	local Icon = nil
	local fpsIcon = nil
	local pingIcon = nil
	local weatherIcon = nil
	local frameSamples = {}
	local FPS_WINDOW = 0.5
	local connections = {}

	local WEATHER_EMOJI = {
		Day = "☀",
		Night = "🌙",
		Dawn = "🌅",
		Dusk = "🌆",
		Storm = "⛈",
		Rain = "🌧",
		Cloudy = "☁",
		Fog = "🌫",
		Snow = "❄",
	}

	local WEATHER_LABEL = {
		Day = "Clear",
		Night = "Clear",
		Dawn = "Dawn",
		Dusk = "Dusk",
		Storm = "Stormy",
		Rain = "Rainy",
		Cloudy = "Cloudy",
		Fog = "Foggy",
		Snow = "Snowing",
	}

	local TIME_LABEL = {
		Day = "Day",
		Night = "Night",
		Dawn = "Dawn",
		Dusk = "Dusk",
	}

	local function deepFindModule(root, depth)
		if not root or depth > 6 then return nil end
		local direct = root:FindFirstChild("Icon")
		if direct and direct:IsA("ModuleScript") then return direct end
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("Folder") or child:IsA("ModuleScript") then
				if child:IsA("ModuleScript") and child.Name == "Icon" then
					return child
				end
				local nested = deepFindModule(child, depth + 1)
				if nested then return nested end
			end
		end
		return nil
	end

	local function locateIconModule()
		local guesses = {
			ReplicatedStorage:FindFirstChild("Icon"),
			ReplicatedStorage:FindFirstChild("TopbarPlus"),
			ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Icon"),
			ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("TopbarPlus"),
			ReplicatedStorage:FindFirstChild("Kits") and ReplicatedStorage.Kits:FindFirstChild("TopbarPlus"),
			StarterPlayer.StarterPlayerScripts:FindFirstChild("Icon"),
			StarterPlayer.StarterPlayerScripts:FindFirstChild("TopbarPlus"),
		}

		for _, candidate in ipairs(guesses) do
			if candidate then
				if candidate:IsA("ModuleScript") and candidate.Name == "Icon" then
					return candidate
				end
				local nested = deepFindModule(candidate, 0)
				if nested then return nested end
			end
		end

		local fromRS = deepFindModule(ReplicatedStorage, 0)
		if fromRS then return fromRS end

		local fromSP = deepFindModule(StarterPlayer.StarterPlayerScripts, 0)
		if fromSP then return fromSP end

		return nil
	end

	local function loadIcon()
		local mod = locateIconModule()
		if not mod then
			warn("[TopbarIcons] TopbarPlus Icon ModuleScript not found anywhere under ReplicatedStorage or StarterPlayerScripts")
			return nil
		end
		local ok, result = pcall(require, mod)
		if not ok then
			warn("[TopbarIcons] Failed to require Icon module:", result)
			return nil
		end
		return result
	end

	local function callMethod(obj, name, ...)
		local method = obj[name]
		if type(method) ~= "function" then return nil end
		local ok, result = pcall(method, obj, ...)
		if not ok then return nil end
		return result or obj
	end

	local function setIconLabel(icon, text)
		if not icon then return end
		callMethod(icon, "setLabel", text)
	end

	local function setIconName(icon, name)
		if not icon then return end
		callMethod(icon, "setName", name)
	end

	local function setIconOrder(icon, order)
		if not icon then return end
		callMethod(icon, "setOrder", order)
	end

	local function setIconLeft(icon)
		if not icon then return end
		if not callMethod(icon, "align", "Left") then
			callMethod(icon, "setLeft")
		end
	end

	local function setIconCaption(icon, text)
		if not icon then return end
		callMethod(icon, "setCaption", text)
	end

	local function removeExampleIcons()
		local ok, icons = pcall(function()
			if Icon and type(Icon.getIcons) == "function" then
				return Icon.getIcons()
			end
			return nil
		end)
		if not ok or type(icons) ~= "table" then return end
		for _, existing in pairs(icons) do
			if existing and existing ~= fpsIcon and existing ~= pingIcon and existing ~= weatherIcon then
				pcall(function() existing:destroy() end)
			end
		end
	end

	local function createIcon(name, order, initialLabel)
		local icon = Icon.new()
		setIconName(icon, name)
		setIconLabel(icon, initialLabel)
		setIconOrder(icon, order)
		setIconLeft(icon)
		return icon
	end

	local function setupFPS()
		table.insert(connections, RunService.RenderStepped:Connect(function()
			local now = os.clock()
			table.insert(frameSamples, now)
			while frameSamples[1] and now - frameSamples[1] > FPS_WINDOW do
				table.remove(frameSamples, 1)
			end
		end))

		task.spawn(function()
			while fpsIcon do
				task.wait(0.25)
				local fps = math.floor(#frameSamples / FPS_WINDOW + 0.5)
				setIconLabel(fpsIcon, fps .. " FPS")
			end
		end)
	end

	local function getPingMs()
		local ok, ms = pcall(function()
			local net = Stats:FindFirstChild("Network")
			local serverStats = net and net:FindFirstChild("ServerStatsItem")
			local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")
			if dataPing then
				return math.floor(dataPing:GetValue() + 0.5)
			end
			return nil
		end)
		if ok and type(ms) == "number" and ms > 0 then
			return ms
		end

		local ok2, fallback = pcall(function()
			return math.floor(player:GetNetworkPing() * 1000 + 0.5)
		end)
		if ok2 and type(fallback) == "number" then
			return fallback
		end
		return 0
	end

	local function setupPing()
		task.spawn(function()
			while pingIcon do
				task.wait(1)
				local ms = getPingMs()
				setIconLabel(pingIcon, ms .. " MS")
			end
		end)
	end

	local function refreshWeather()
		if not weatherIcon then return end
		local weather = player:GetAttribute("Weather")
		local timeState = player:GetAttribute("TimeState") or "Day"
		local emoji = (weather and WEATHER_EMOJI[weather]) or WEATHER_EMOJI[timeState] or "☀"
		setIconLabel(weatherIcon, emoji)

		local timeText = TIME_LABEL[timeState] or timeState or "Day"
		local weatherText = (weather and WEATHER_LABEL[weather]) or "Clear"
		setIconCaption(weatherIcon, timeText .. " · " .. weatherText)
	end

	local function setupWeather()
		refreshWeather()
		table.insert(connections, player:GetAttributeChangedSignal("TimeState"):Connect(refreshWeather))
		table.insert(connections, player:GetAttributeChangedSignal("Weather"):Connect(refreshWeather))
	end

	function TopbarIcons:Init()
		Icon = loadIcon()
		if not Icon then return end

		local okF, fps = pcall(createIcon, "FPSIcon", 1, "-- FPS")
		if okF then fpsIcon = fps end

		local okP, ping = pcall(createIcon, "PingIcon", 2, "-- MS")
		if okP then pingIcon = ping end

		local okW, weather = pcall(createIcon, "WeatherIcon", 3, "☀")
		if okW then weatherIcon = weather end

		removeExampleIcons()

		if fpsIcon then setupFPS() end
		if pingIcon then setupPing() end
		if weatherIcon then setupWeather() end
	end

	function TopbarIcons:Cleanup()
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		connections = {}

		for _, icon in ipairs({ fpsIcon, pingIcon, weatherIcon }) do
			if icon then
				pcall(function() icon:destroy() end)
			end
		end
		fpsIcon, pingIcon, weatherIcon = nil, nil, nil
	end

	return TopbarIcons
end
