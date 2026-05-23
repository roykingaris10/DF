return function(Client)
	local InnerDialogueClient = {}

	local player = Client.player
	local Network = Client.Network

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")

	local fired = false

	local function findTarget()
		local PlayerGui = player:WaitForChild("PlayerGui")
		local UI = PlayerGui:WaitForChild("UI", 10)
		if not UI then return nil end
		local node = UI:FindFirstChild("InnerDialogue", true)
			or UI:FindFirstChild("Inner Dialogue", true)
			or UI:FindFirstChild("innerdialogue", true)
		if not node then return nil end
		if node:IsA("TextLabel") then return node, node.Parent end
		local label = node:FindFirstChildOfClass("TextLabel")
		if not label then label = node:FindFirstChild("TextLabel", true) end
		if label then return label, node end
		return nil
	end

	local function display(text)
		local label, container = findTarget()
		if not label then
			warn("[InnerDialogue] UI target not found under PlayerGui.UI")
			return
		end

		label.Text = text
		label.TextTransparency = 1
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Transparency = 1 end
		if container then container.Visible = true end

		local fadeIn = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(label, fadeIn, { TextTransparency = 0 }):Play()
		if stroke then TweenService:Create(stroke, fadeIn, { Transparency = 0 }):Play() end

		task.wait(5.5)

		local fadeOut = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(label, fadeOut, { TextTransparency = 1 }):Play()
		if stroke then TweenService:Create(stroke, fadeOut, { Transparency = 1 }):Play() end
		task.wait(1.25)
		if container then container.Visible = false end
	end

	local function tryFire()
		if fired then return end
		local text = player:GetAttribute("PendingInnerDialogue")
		if not text or text == "" then return end
		fired = true

		while not Client.loaded do task.wait(0.1) end

		local conn
		conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			local kc = input.KeyCode
			if kc ~= Enum.KeyCode.W and kc ~= Enum.KeyCode.A
				and kc ~= Enum.KeyCode.S and kc ~= Enum.KeyCode.D then return end
			conn:Disconnect()
			task.wait(0.35)
			task.spawn(display, text)
			Network:post("InnerDialogueSeen")
		end)
	end

	function InnerDialogueClient:Init()
		if player:GetAttribute("PendingInnerDialogue") then
			task.spawn(tryFire)
		end
		player:GetAttributeChangedSignal("PendingInnerDialogue"):Connect(tryFire)
	end

	return InnerDialogueClient
end
