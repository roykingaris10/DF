return function(Client)
	local StartScreenClient = {}
	local player = Client.player
	local TweenService = game:GetService("TweenService")
	local PlayerGui = player:WaitForChild("PlayerGui")

	local hoverConnections = {}

	local FADE_IN = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local FADE_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	local DIV_DELAY = 0.08

	local function tweenTransparency(obj, info, target)
		if not obj then return end
		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			TweenService:Create(obj, info, {ImageTransparency = target}):Play()
		elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
			TweenService:Create(obj, info, {TextTransparency = target}):Play()
		elseif obj:IsA("Frame") then
			TweenService:Create(obj, info, {BackgroundTransparency = target}):Play()
		end
	end

	local function hideAll(playFrame)
		local fade = playFrame:FindFirstChild("FADE")
		local divs = playFrame:FindFirstChild("Divs")
		if fade then
			tweenTransparency(fade, FADE_OUT, 1)
		end
		if divs then
			local left = divs:FindFirstChild("left")
			local right = divs:FindFirstChild("right")
			if left then
				for _, child in ipairs(left:GetChildren()) do
					if not child:IsA("UIBase") then tweenTransparency(child, FADE_OUT, 1) end
				end
				tweenTransparency(left, FADE_OUT, 1)
			end
			if right then
				for _, child in ipairs(right:GetChildren()) do
					if not child:IsA("UIBase") then tweenTransparency(child, FADE_OUT, 1) end
				end
				tweenTransparency(right, FADE_OUT, 1)
			end
		end
	end

	local function setInvisible(playFrame)
		local fade = playFrame:FindFirstChild("FADE")
		local divs = playFrame:FindFirstChild("Divs")
		if fade then
			if fade:IsA("ImageLabel") or fade:IsA("ImageButton") then
				fade.ImageTransparency = 1
			elseif fade:IsA("Frame") then
				fade.BackgroundTransparency = 1
			end
		end
		if divs then
			for _, side in ipairs({divs:FindFirstChild("left"), divs:FindFirstChild("right")}) do
				if side then
					if side:IsA("ImageLabel") or side:IsA("ImageButton") then
						side.ImageTransparency = 1
					elseif side:IsA("Frame") then
						side.BackgroundTransparency = 1
					end
					for _, child in ipairs(side:GetChildren()) do
						if child:IsA("ImageLabel") or child:IsA("ImageButton") then
							child.ImageTransparency = 1
						elseif child:IsA("TextLabel") or child:IsA("TextButton") then
							child.TextTransparency = 1
						elseif child:IsA("Frame") then
							child.BackgroundTransparency = 1
						end
					end
				end
			end
		end
	end

	local function setupButton(playFrame)
		local btn = playFrame:FindFirstChild("btn")
		local fade = playFrame:FindFirstChild("FADE")
		local divs = playFrame:FindFirstChild("Divs")
		if not btn then return end

		setInvisible(playFrame)

		local enterConn = btn.MouseEnter:Connect(function()
			if fade then
				tweenTransparency(fade, FADE_IN, 0)
			end

			if divs then
				local left = divs:FindFirstChild("left")
				local right = divs:FindFirstChild("right")
				task.delay(DIV_DELAY, function()
					if left then
						tweenTransparency(left, FADE_IN, 0)
						for _, child in ipairs(left:GetChildren()) do
							if not child:IsA("UIBase") then tweenTransparency(child, FADE_IN, 0) end
						end
					end
					if right then
						tweenTransparency(right, FADE_IN, 0)
						for _, child in ipairs(right:GetChildren()) do
							if not child:IsA("UIBase") then tweenTransparency(child, FADE_IN, 0) end
						end
					end
				end)
			end
		end)
		table.insert(hoverConnections, enterConn)

		local leaveConn = btn.MouseLeave:Connect(function()
			hideAll(playFrame)
		end)
		table.insert(hoverConnections, leaveConn)
	end

	function StartScreenClient:Init()
		local startScreen = PlayerGui:WaitForChild("StartScreen")
		local startFrame = startScreen:WaitForChild("StartFrame")
		local btnFrame = startFrame:WaitForChild("BtnFrame")

		for _, child in ipairs(btnFrame:GetChildren()) do
			if child.Name == "Play" then
				setupButton(child)
			end
		end
	end

	return StartScreenClient
end
