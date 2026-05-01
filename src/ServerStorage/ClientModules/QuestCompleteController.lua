return function(Client)
	local QuestCompleteController = {}

	local TweenService = game:GetService("TweenService")
	local SoundService = game:GetService("SoundService")

	local player = Client.player
	local PlayerGui = player:WaitForChild("PlayerGui")

	local CORNER_TOP_SIZE = UDim2.fromOffset(171, 19)
	local CORNER_BOT_SIZE = UDim2.fromOffset(195, 11)
	local CORNER_TOP_COLLAPSED = UDim2.fromOffset(29, 19)
	local CORNER_BOT_COLLAPSED = UDim2.fromOffset(28, 11)
	local HOLD_DURATION = 3.5

	local refs = nil
	local activeToken = 0
	local completeSound = nil

	local function ease(time, style, dir, delay)
		return TweenInfo.new(time, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out, 0, false, delay or 0)
	end

	local function play(instance, info, props)
		local tween = TweenService:Create(instance, info, props)
		tween:Play()
		return tween
	end

	local function findUI()
		if refs and refs.frame and refs.frame.Parent then return refs end

		local UI = PlayerGui:FindFirstChild("UI") or PlayerGui:FindFirstChild("HUD")
		if not UI then return nil end

		local frame = UI:FindFirstChild("questComplete", true)
		if not frame then return nil end

		refs = {
			frame = frame,
			topLeft = frame:FindFirstChild("topLeft"),
			topRight = frame:FindFirstChild("topRight"),
			topPart = frame:FindFirstChild("topPart"),
			bottomLeft = frame:FindFirstChild("bottomLeft"),
			bottomRight = frame:FindFirstChild("bottomRight"),
			bottomPart = frame:FindFirstChild("bottomPart"),
			rect = frame:FindFirstChild("rect"),
			captionText = frame:FindFirstChild("captionText"),
			questText = frame:FindFirstChild("questText"),
		}
		refs.rectLabel = refs.rect and refs.rect:FindFirstChildWhichIsA("TextLabel") or nil

		return refs
	end

	local function setHidden(r)
		r.frame.Visible = false

		for _, name in ipairs({ "topLeft", "topRight", "bottomLeft", "bottomRight", "topPart", "bottomPart", "rect" }) do
			local part = r[name]
			if part and part:IsA("ImageLabel") then
				part.ImageTransparency = 1
			end
		end

		if r.topLeft then r.topLeft.Size = CORNER_TOP_COLLAPSED end
		if r.topRight then r.topRight.Size = CORNER_TOP_COLLAPSED end
		if r.bottomLeft then r.bottomLeft.Size = CORNER_BOT_COLLAPSED end
		if r.bottomRight then r.bottomRight.Size = CORNER_BOT_COLLAPSED end

		if r.captionText and r.captionText:IsA("TextLabel") then r.captionText.TextTransparency = 1 end
		if r.questText and r.questText:IsA("TextLabel") then r.questText.TextTransparency = 1 end
		if r.rectLabel then r.rectLabel.TextTransparency = 1 end
	end

	local function openTween(r)
		r.frame.Visible = true

		if r.topLeft then
			play(r.topLeft, ease(0.6, Enum.EasingStyle.Linear), { ImageTransparency = 0 })
			play(r.topLeft, ease(1.4, Enum.EasingStyle.Quint), { Size = CORNER_TOP_SIZE })
		end
		if r.topRight then
			play(r.topRight, ease(0.6, Enum.EasingStyle.Linear), { ImageTransparency = 0 })
			play(r.topRight, ease(1.4, Enum.EasingStyle.Quint), { Size = CORNER_TOP_SIZE })
		end

		if r.bottomLeft then
			play(r.bottomLeft, ease(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.05), { ImageTransparency = 0 })
			play(r.bottomLeft, ease(1.6, Enum.EasingStyle.Quint), { Size = CORNER_BOT_SIZE })
		end
		if r.bottomRight then
			play(r.bottomRight, ease(0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0.05), { ImageTransparency = 0 })
			play(r.bottomRight, ease(1.6, Enum.EasingStyle.Quint), { Size = CORNER_BOT_SIZE })
		end

		task.delay(0.6, function()
			if r.topPart then
				play(r.topPart, ease(0.9, Enum.EasingStyle.Sine), { ImageTransparency = 0 })
			end
			if r.bottomPart then
				play(r.bottomPart, ease(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.1), { ImageTransparency = 0 })
			end
			if r.captionText and r.captionText:IsA("TextLabel") then
				play(r.captionText, ease(0.8, Enum.EasingStyle.Sine), { TextTransparency = 0 })
			end
			if r.questText and r.questText:IsA("TextLabel") then
				play(r.questText, ease(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.15), { TextTransparency = 0 })
			end
		end)

		task.delay(1.0, function()
			if r.rect then
				local final = TweenService:Create(r.rect, ease(0.5, Enum.EasingStyle.Sine), { ImageTransparency = 0 })
				final:Play()
				if r.rectLabel then
					final.Completed:Connect(function()
						play(r.rectLabel, ease(0.4, Enum.EasingStyle.Sine), { TextTransparency = 0 })
					end)
				end
			end
		end)
	end

	local function closeTween(r)
		if r.captionText and r.captionText:IsA("TextLabel") then
			play(r.captionText, ease(0.4, Enum.EasingStyle.Linear), { TextTransparency = 1 })
		end
		if r.questText and r.questText:IsA("TextLabel") then
			play(r.questText, ease(0.4, Enum.EasingStyle.Linear), { TextTransparency = 1 })
		end
		if r.topPart then
			play(r.topPart, ease(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.1), { ImageTransparency = 1 })
		end
		if r.bottomPart then
			play(r.bottomPart, ease(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0.15), { ImageTransparency = 1 })
		end
		if r.rect then
			play(r.rect, ease(0.4, Enum.EasingStyle.Sine), { ImageTransparency = 1 })
		end
		if r.rectLabel then
			play(r.rectLabel, ease(0.4, Enum.EasingStyle.Sine), { TextTransparency = 1 })
		end

		task.delay(0.3, function()
			if r.topLeft then
				play(r.topLeft, ease(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0.2), { ImageTransparency = 1 })
				play(r.topLeft, ease(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = CORNER_TOP_COLLAPSED })
			end
			if r.topRight then
				play(r.topRight, ease(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0.2), { ImageTransparency = 1 })
				play(r.topRight, ease(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = CORNER_TOP_COLLAPSED })
			end
			if r.bottomLeft then
				play(r.bottomLeft, ease(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0.25), { ImageTransparency = 1 })
				play(r.bottomLeft, ease(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = CORNER_BOT_COLLAPSED })
			end
			if r.bottomRight then
				play(r.bottomRight, ease(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0.25), { ImageTransparency = 1 })
				play(r.bottomRight, ease(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = CORNER_BOT_COLLAPSED })
			end
		end)
	end

	function QuestCompleteController:Show(questName, captionOverride)
		local r = findUI()
		if not r then
			warn("[QuestCompleteController] questComplete UI not found")
			return
		end

		activeToken += 1
		local token = activeToken

		setHidden(r)

		if r.captionText and r.captionText:IsA("TextLabel") then
			r.captionText.Text = (captionOverride or "QUEST COMPLETE"):upper()
		end
		if r.questText and r.questText:IsA("TextLabel") then
			r.questText.Text = tostring(questName or "")
		end

		if completeSound then
			completeSound:Stop()
			completeSound:Play()
		end

		openTween(r)

		task.delay(HOLD_DURATION, function()
			if token ~= activeToken then return end
			closeTween(r)
			task.delay(1.4, function()
				if token ~= activeToken then return end
				r.frame.Visible = false
			end)
		end)
	end

	function QuestCompleteController:SetSound(sound)
		completeSound = sound
	end

	function QuestCompleteController:Init()
		findUI()
	end

	return QuestCompleteController
end
