return function(Client)
	local DeathClient = {}
	local player = Client.player

	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local Lighting = game:GetService("Lighting")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Debris = game:GetService("Debris")
	local ContentProvider = game:GetService("ContentProvider")
	local RunService = game:GetService("RunService")

	local camera = workspace.CurrentCamera

	local state = {
		character = nil,
		humanoid = nil,
		isAnimating = false,
		awaitingRespawn = false,
		lastDamageSource = "Unknown",
		lastKillerCharacter = nil,
		currentSong = nil,
		flipbookRunning = false,
		gui = nil,
		setupConnections = {},
	}

	local refs = {}
	local frames = {}
	local blur, cc

	local function findRefs(playerGui)
		local gui = playerGui:FindFirstChild("DeathScreen")
		if not gui then return false end

		local deathFrame = gui:FindFirstChild("DeathFrame")
		if not deathFrame then return false end

		refs.gui = gui
		refs.deathFrame = deathFrame
		refs.topEye = deathFrame:FindFirstChild("Top")
		refs.bottomEye = deathFrame:FindFirstChild("Bottom")
		refs.dark = deathFrame:FindFirstChild("Dark")
		refs.flipbook = deathFrame:FindFirstChild("Flipbook")
		refs.divLine = deathFrame:FindFirstChild("DivLine")
		refs.deathText = deathFrame:FindFirstChild("DeathText")
		refs.infoFrame = deathFrame:FindFirstChild("InfoFrame")
		refs.imageLabel = deathFrame:FindFirstChild("ImageLabel")
		refs.viewportFrame = deathFrame:FindFirstChild("ViewportFrame")

		if refs.infoFrame then
			refs.slainByLabel = refs.infoFrame:FindFirstChild("SlainedBy")
		end
		if refs.viewportFrame then
			refs.userKillerViewport = refs.viewportFrame:FindFirstChild("UserKiller")
			refs.userKilledByViewport = refs.viewportFrame:FindFirstChild("UserKilledBy")
		end

		state.gui = gui
		return true
	end

	local function ensureLightingEffects()
		blur = Lighting:FindFirstChild("DeathBlur")
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "DeathBlur"
			blur.Size = 0
			blur.Parent = Lighting
		end
		cc = Lighting:FindFirstChild("DeathCC")
		if not cc then
			cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "DeathCC"
			cc.Saturation = 0
			cc.Parent = Lighting
		end
	end

	local function buildFlipbookFrames()
		frames = {}
		if not refs.flipbook then return end
		for i = 0, 15 do
			local f = refs.flipbook:FindFirstChild(tostring(i))
			if f then table.insert(frames, f) end
		end
		task.spawn(function()
			pcall(function() ContentProvider:PreloadAsync(frames) end)
		end)
	end

	local function loadAssets()
		local sounds = ReplicatedStorage:FindFirstChild("Sounds")
		if sounds then
			refs.deathSound = sounds:FindFirstChild("DeathSound")
			refs.deathSong = sounds:FindFirstChild("DeathSong")
		end

		local stanceAnims = ReplicatedStorage:FindFirstChild("StanceAnimation")
		if stanceAnims then
			refs.killerStanceAnim = stanceAnims:FindFirstChild("KillerStance")
			refs.deathStanceAnim = stanceAnims:FindFirstChild("DeathStance")
		end

		local deathCharFolder = ReplicatedStorage:FindFirstChild("DeathCharacter")
		if deathCharFolder then
			refs.characterTemplate = deathCharFolder:FindFirstChild("CharacterModel")
		end

		refs.requestRespawn = ReplicatedStorage:WaitForChild("RequestRespawn", 10)
		refs.respawnReady = ReplicatedStorage:WaitForChild("RespawnReady", 10)
	end

	local function tween(obj, duration, props, style, direction)
		local t = TweenService:Create(
			obj,
			TweenInfo.new(duration, style or Enum.EasingStyle.Sine, direction or Enum.EasingDirection.Out),
			props
		)
		t:Play()
		return t
	end

	local function tweenEyelids(size, duration, style)
		if refs.topEye then
			tween(refs.topEye, duration, {Size = UDim2.new(1, 0, size, 0)}, style)
		end
		if refs.bottomEye then
			tween(refs.bottomEye, duration, {Size = UDim2.new(1, 0, size, 0)}, style)
		end
	end

	local function setEyelids(size)
		if refs.topEye then refs.topEye.Size = UDim2.new(1, 0, size, 0) end
		if refs.bottomEye then refs.bottomEye.Size = UDim2.new(1, 0, size, 0) end
	end

	local function flutterSequence()
		local flutters = {
			{close = 0.10, open = 0.02, closeTime = 0.06, openTime = 0.04, wait = 0.08},
			{close = 0.18, open = 0.06, closeTime = 0.08, openTime = 0.05, wait = 0.08},
			{close = 0.25, open = 0.12, closeTime = 0.10, openTime = 0.06, wait = 0.08},
			{close = 0.32, open = 0.20, closeTime = 0.10, openTime = 0.06, wait = 0.08},
			{close = 0.40, open = 0.28, closeTime = 0.12, openTime = 0.05, wait = 0.06},
			{close = 0.45, open = 0.38, closeTime = 0.10, openTime = 0.05, wait = 0.05},
		}
		for _, f in ipairs(flutters) do
			tweenEyelids(f.close, f.closeTime)
			task.wait(f.closeTime + 0.02)
			tweenEyelids(f.open, f.openTime)
			task.wait(f.wait)
		end
	end

	local function formatSlainText(killerName)
		return string.format('SLAIN BY <font color="rgb(200,50,50)">%s</font>', tostring(killerName):upper())
	end

	local function playDeathSounds()
		if refs.deathSound then
			local gong = refs.deathSound:Clone()
			gong.Parent = refs.deathFrame
			gong:Play()
			Debris:AddItem(gong, 5)
		end

		if refs.deathSong then
			local song = refs.deathSong:Clone()
			song.Volume = 0
			song.Parent = refs.deathFrame
			song:Play()
			state.currentSong = song
			task.spawn(function()
				while state.currentSong == song and song.Parent and song.Volume < 1 do
					song.Volume = math.min(song.Volume + 0.02, 1)
					task.wait(0.1)
				end
			end)
		end
	end

	local function stopDeathSounds()
		if state.currentSong then
			local song = state.currentSong
			state.currentSong = nil
			task.spawn(function()
				while song and song.Parent and song.Volume > 0 do
					song.Volume = math.max(song.Volume - 0.05, 0)
					task.wait(0.05)
				end
				if song and song.Parent then
					song:Stop()
					song:Destroy()
				end
			end)
		end
	end

	local function hideAllFrames()
		for _, f in ipairs(frames) do f.Visible = false end
	end

	local function playFlipbook()
		if #frames == 0 or not refs.flipbook then return end

		refs.flipbook.Visible = true
		refs.flipbook.BackgroundTransparency = 1

		for _, f in ipairs(frames) do
			f.Visible = false
			if f:IsA("ImageLabel") then f.ImageTransparency = 1 end
		end

		state.flipbookRunning = true
		task.spawn(function()
			local idx = 1
			hideAllFrames()
			frames[idx].Visible = true
			while state.flipbookRunning do
				task.wait(0.08)
				if not state.flipbookRunning then break end
				idx = (idx % #frames) + 1
				hideAllFrames()
				frames[idx].Visible = true
			end
		end)
	end

	local function fadeInFlipbook(duration)
		for _, f in ipairs(frames) do
			if f:IsA("ImageLabel") then
				tween(f, duration, {ImageTransparency = 0}, Enum.EasingStyle.Sine)
			end
		end
	end

	local function fadeOutFlipbook(duration)
		for _, f in ipairs(frames) do
			if f:IsA("ImageLabel") then
				tween(f, duration, {ImageTransparency = 1}, Enum.EasingStyle.Sine)
			end
		end
	end

	local function stopFlipbook()
		state.flipbookRunning = false
		task.defer(function()
			hideAllFrames()
			if refs.flipbook then refs.flipbook.Visible = false end
		end)
	end

	local function makeBlackSilhouette(model)
		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Accessory") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("BodyColors") then
				child:Destroy()
			end
		end
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				if desc.Name == "HumanoidRootPart" then
					desc.Transparency = 1
				else
					desc.BrickColor = BrickColor.new("Really black")
					desc.Color = Color3.fromRGB(0, 0, 0)
					desc.Material = Enum.Material.Neon
					desc.Reflectance = 0
					desc.Transparency = 0.3
				end
				for _, child in ipairs(desc:GetChildren()) do
					if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
						child:Destroy()
					end
				end
			elseif desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("SurfaceAppearance") then
				desc:Destroy()
			end
		end
	end

	local function setupSingleViewport(viewport, animationObj)
		if not viewport or not refs.characterTemplate then return end
		for _, child in ipairs(viewport:GetChildren()) do
			if not child:IsA("UIListLayout") then child:Destroy() end
		end

		local worldModel = Instance.new("WorldModel")
		worldModel.Parent = viewport

		local model = refs.characterTemplate:Clone()
		model.Parent = worldModel
		model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))

		makeBlackSilhouette(model)

		local cam = Instance.new("Camera")
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 2.5, 8), Vector3.new(0, 2.5, 0))
		cam.FieldOfView = 50
		cam.Parent = viewport
		viewport.CurrentCamera = cam

		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum and animationObj then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			task.spawn(function()
				task.wait(0.2)
				if not model.Parent then return end
				local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop() end
				local ok, err = pcall(function()
					local track = animator:LoadAnimation(animationObj)
					track.Looped = true
					track.Priority = Enum.AnimationPriority.Action4
					track:Play(0)
					track:AdjustSpeed(1)
				end)
				if not ok then warn("[DeathClient] viewport anim failed:", err) end
			end)
		end
		return model
	end

	local function setupViewports()
		if not refs.viewportFrame then return end
		setupSingleViewport(refs.userKillerViewport, refs.killerStanceAnim)
		setupSingleViewport(refs.userKilledByViewport, refs.deathStanceAnim)

		if refs.userKillerViewport then
			refs.userKillerViewport.AnchorPoint = Vector2.new(0.5, 0.5)
			refs.userKillerViewport.Position = UDim2.new(-0.5, 0, 0.5, 0)
			refs.userKillerViewport.ImageTransparency = 0
			refs.userKillerViewport.Visible = true
		end
		if refs.userKilledByViewport then
			refs.userKilledByViewport.AnchorPoint = Vector2.new(0.5, 0.5)
			refs.userKilledByViewport.Position = UDim2.new(1.5, 0, 0.5, 0)
			refs.userKilledByViewport.ImageTransparency = 0
			refs.userKilledByViewport.Visible = true
		end
		refs.viewportFrame.Visible = true
	end

	local function animateViewportsIn(duration)
		if refs.userKillerViewport then
			tween(refs.userKillerViewport, duration, {Position = UDim2.new(0.25, 0, 0.5, 0)}, Enum.EasingStyle.Quint)
		end
		if refs.userKilledByViewport then
			tween(refs.userKilledByViewport, duration, {Position = UDim2.new(0.75, 0, 0.5, 0)}, Enum.EasingStyle.Quint)
		end
	end

	local function fadeOutViewports(duration)
		if refs.userKillerViewport then
			tween(refs.userKillerViewport, duration, {ImageTransparency = 1}, Enum.EasingStyle.Sine)
		end
		if refs.userKilledByViewport then
			tween(refs.userKilledByViewport, duration, {ImageTransparency = 1}, Enum.EasingStyle.Sine)
		end
	end

	local function cleanupViewports()
		for _, viewport in ipairs({refs.userKillerViewport, refs.userKilledByViewport}) do
			if viewport then
				for _, child in ipairs(viewport:GetChildren()) do
					if not child:IsA("UIListLayout") then child:Destroy() end
				end
				viewport.ImageTransparency = 0
			end
		end
		if refs.viewportFrame then refs.viewportFrame.Visible = false end
	end

	local function resetUI()
		if refs.topEye then
			refs.topEye.Visible = true
			refs.topEye.AnchorPoint = Vector2.new(0.5, 0)
			refs.topEye.Position = UDim2.new(0.5, 0, 0, 0)
		end
		if refs.bottomEye then
			refs.bottomEye.Visible = true
			refs.bottomEye.AnchorPoint = Vector2.new(0.5, 1)
			refs.bottomEye.Position = UDim2.new(0.5, 0, 1, 0)
		end
		setEyelids(0)

		if refs.dark then
			refs.dark.Visible = false
			refs.dark.BackgroundTransparency = 1
		end
		if blur then blur.Size = 0 end
		if cc then cc.Saturation = 0 end

		state.flipbookRunning = false
		hideAllFrames()
		if refs.flipbook then refs.flipbook.Visible = false end

		if refs.infoFrame then refs.infoFrame.Visible = false end
		if refs.slainByLabel then refs.slainByLabel.TextTransparency = 1 end
		if refs.deathText then
			refs.deathText.Visible = false
			refs.deathText.TextTransparency = 1
		end
		if refs.divLine then
			refs.divLine.Visible = false
			refs.divLine.ImageTransparency = 1
		end
		if refs.imageLabel then refs.imageLabel.ImageTransparency = 1 end

		cleanupViewports()
		if refs.deathFrame then refs.deathFrame.Visible = false end
		if refs.gui then refs.gui.Enabled = false end
	end

	local function getKillerName()
		if state.character then
			local tag = state.character:FindFirstChild("CreatorTag") or state.character:FindFirstChild("creator")
			if tag and tag.Value then
				state.lastKillerCharacter = tag.Value.Character
				return tag.Value.Name
			end
			local damageTag = state.character:GetAttribute("LastDamageSource")
			if damageTag then return damageTag end
		end
		return state.lastDamageSource
	end

	local function trackDamage()
		if not state.character then return end
		state.lastDamageSource = "Unknown"
		state.lastKillerCharacter = nil

		for _, part in ipairs(state.character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Touched:Connect(function(hit)
					if hit:GetAttribute("DealsDamage") or hit.Name:lower():find("death") or hit.Name:lower():find("kill") then
						state.lastDamageSource = hit.Name
					end
					local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent) or Players:GetPlayerFromCharacter(hit.Parent.Parent)
					if hitPlayer and hitPlayer ~= player then
						state.lastDamageSource = hitPlayer.Name
						state.lastKillerCharacter = hitPlayer.Character
					end
				end)
			end
		end

		if state.humanoid then
			state.humanoid.HealthChanged:Connect(function(newHealth)
				if newHealth < state.humanoid.MaxHealth then
					local tag = state.character:FindFirstChild("CreatorTag") or state.character:FindFirstChild("creator")
					if tag and tag.Value then
						state.lastDamageSource = tag.Value.Name
						state.lastKillerCharacter = tag.Value.Character
					end
				end
			end)
		end
	end

	local function hideOtherGuis()
		state.hiddenGuiNames = {}
		local pg = state.gui and state.gui.Parent
		if not pg then return end
		for _, child in ipairs(pg:GetChildren()) do
			if child:IsA("ScreenGui") and child ~= state.gui and child.Enabled then
				state.hiddenGuiNames[child.Name] = true
				child.Enabled = false
			end
		end
	end

	local function restoreOtherGuis()
		if not state.hiddenGuiNames then return end
		local pg = state.gui and state.gui.Parent
		if pg then
			for _, child in ipairs(pg:GetChildren()) do
				if child:IsA("ScreenGui") and state.hiddenGuiNames[child.Name] then
					child.Enabled = true
				end
			end
		end
		state.hiddenGuiNames = nil
	end

	local function playRespawnTransition(newHumanoid)
		if state.cameraLockConn then
			state.cameraLockConn:Disconnect()
			state.cameraLockConn = nil
		end
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = newHumanoid

		stopFlipbook()
		cleanupViewports()
		stopDeathSounds()
		restoreOtherGuis()

		if refs.dark then tween(refs.dark, 1.0, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint) end
		if blur then tween(blur, 1.0, {Size = 0}, Enum.EasingStyle.Quad) end
		if cc then tween(cc, 1.0, {Saturation = 0}, Enum.EasingStyle.Quad) end
		tweenEyelids(0, 0.8, Enum.EasingStyle.Quint)

		task.wait(1.0)

		resetUI()
		state.awaitingRespawn = false
		state.isAnimating = false
	end

	local function onDeath()
		if state.isAnimating then return end
		state.isAnimating = true
		state.awaitingRespawn = true

		local killerName = getKillerName()
		if state.humanoid then
			state.humanoid.WalkSpeed = 0
			state.humanoid.JumpPower = 0
		end

		playDeathSounds()

		if refs.gui then refs.gui.Enabled = true end
		if refs.deathFrame then refs.deathFrame.Visible = true end
		hideOtherGuis()
		if refs.topEye then refs.topEye.Visible = true end
		if refs.bottomEye then refs.bottomEye.Visible = true end
		setEyelids(0)
		if refs.dark then
			refs.dark.Visible = true
			refs.dark.BackgroundTransparency = 1
		end

		playFlipbook()


		if refs.divLine then refs.divLine.Visible = false end
		if refs.deathText then refs.deathText.Visible = false end
		if refs.infoFrame then refs.infoFrame.Visible = false end
		if refs.imageLabel then refs.imageLabel.ImageTransparency = 1 end
		if refs.viewportFrame then refs.viewportFrame.Visible = false end

		if blur then tween(blur, 2, {Size = 24}, Enum.EasingStyle.Quad) end
		if cc then tween(cc, 2, {Saturation = -1}, Enum.EasingStyle.Linear) end

		flutterSequence()


		tweenEyelids(0.5, 0.4, Enum.EasingStyle.Quart)
		if refs.dark then tween(refs.dark, 0.4, {BackgroundTransparency = 0}, Enum.EasingStyle.Quad) end

		task.wait(0.5)

		local folder = workspace:FindFirstChild("startscreenFolder")
		local camPart = folder and folder:FindFirstChild("camPart")
		if camPart then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = camPart.CFrame
			if state.cameraLockConn then state.cameraLockConn:Disconnect() end
			state.cameraLockConn = RunService.RenderStepped:Connect(function()
				if camPart and camPart.Parent then
					camera.CFrame = camPart.CFrame
				end
			end)
		end

		setupViewports()


		if refs.slainByLabel then
			refs.slainByLabel.RichText = true
			refs.slainByLabel.Text = formatSlainText(killerName)
			refs.slainByLabel.TextTransparency = 1
			refs.slainByLabel.Visible = true
		end
		if refs.infoFrame then refs.infoFrame.Visible = true end

		if refs.divLine then
			refs.divLine.Visible = true
			if refs.divLine:IsA("ImageLabel") then refs.divLine.ImageTransparency = 1 end
		end
		if refs.deathText then
			refs.deathText.Visible = true
			refs.deathText.TextTransparency = 1
		end

		task.wait(0.3)

		local fadeIn = 1.5

		if refs.dark then tween(refs.dark, 2, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint) end
		if refs.imageLabel then tween(refs.imageLabel, 0.4, {ImageTransparency = 0}, Enum.EasingStyle.Quad) end
		if blur then tween(blur, 2, {Size = 0}, Enum.EasingStyle.Quad) end
		if cc then tween(cc, 2, {Saturation = 0}, Enum.EasingStyle.Quad) end
		tweenEyelids(0, fadeIn, Enum.EasingStyle.Quint)

		if refs.divLine and refs.divLine:IsA("ImageLabel") then
			tween(refs.divLine, fadeIn, {ImageTransparency = 0}, Enum.EasingStyle.Sine)
		end
		if refs.deathText then tween(refs.deathText, fadeIn, {TextTransparency = 0}, Enum.EasingStyle.Sine) end
		if refs.slainByLabel then tween(refs.slainByLabel, fadeIn, {TextTransparency = 0}, Enum.EasingStyle.Sine) end
		fadeInFlipbook(fadeIn)

		animateViewportsIn(8)

		task.wait(6)


		local fadeOut = 1
		if refs.divLine and refs.divLine:IsA("ImageLabel") then
			tween(refs.divLine, fadeOut, {ImageTransparency = 1}, Enum.EasingStyle.Sine)
		end
		if refs.deathText then tween(refs.deathText, fadeOut, {TextTransparency = 1}, Enum.EasingStyle.Sine) end
		if refs.slainByLabel then tween(refs.slainByLabel, fadeOut, {TextTransparency = 1}, Enum.EasingStyle.Sine) end
		if refs.imageLabel then tween(refs.imageLabel, fadeOut, {ImageTransparency = 1}, Enum.EasingStyle.Sine) end
		fadeOutFlipbook(fadeOut)
		fadeOutViewports(fadeOut)
		stopDeathSounds()

		task.wait(fadeOut + 0.1)

		stopFlipbook()
		cleanupViewports()
		if refs.divLine then refs.divLine.Visible = false end
		if refs.deathText then refs.deathText.Visible = false end
		if refs.infoFrame then refs.infoFrame.Visible = false end

		tweenEyelids(0.5, 0.6, Enum.EasingStyle.Quart)
		if refs.dark then tween(refs.dark, 0.6, {BackgroundTransparency = 0}, Enum.EasingStyle.Quad) end
		if blur then tween(blur, 0.6, {Size = 20}, Enum.EasingStyle.Quad) end

		task.wait(0.7)


		if refs.requestRespawn then
			refs.requestRespawn:FireServer()
		else
			warn("[DeathClient] RequestRespawn missing")
		end
	end

	local function setupCharacter(char)
		state.character = char
		state.humanoid = char:WaitForChild("Humanoid", 10)
		if not state.humanoid then return end

		if state.awaitingRespawn then
			playRespawnTransition(state.humanoid)
		else
			resetUI()
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = state.humanoid
		end

		trackDamage()

		local fired = false
		local function fireOnce()
			if fired then return end
			fired = true
			onDeath()
		end

		state.humanoid.Died:Once(fireOnce)

		if char:GetAttribute("Dead") then
			fireOnce()
		end
		state.setupConnections.dead = char:GetAttributeChangedSignal("Dead"):Connect(function()
			if char:GetAttribute("Dead") then fireOnce() end
		end)
	end

	function DeathClient:Init()
		local playerGui = player:WaitForChild("PlayerGui", 30)
		if not playerGui then warn("[DeathClient] PlayerGui not found") return end

		ensureLightingEffects()

		local StarterGui = game:GetService("StarterGui")
		if not playerGui:FindFirstChild("DeathScreen") then
			local source = StarterGui:FindFirstChild("DeathScreen")
			if source then
				print("[DeathClient] Cloning DeathScreen from StarterGui into PlayerGui")
				source:Clone().Parent = playerGui
			else
				warn("[DeathClient] DeathScreen not in StarterGui either")
			end
		end

		local function tryFinishSetup()
			if not findRefs(playerGui) then return false end
			buildFlipbookFrames()
			loadAssets()

			if player.Character then
				setupCharacter(player.Character)
			end
			state.setupConnections.charAdded = player.CharacterAdded:Connect(setupCharacter)

			print("[DeathClient] Initialized — DeathScreen found and listeners active")
			return true
		end

		if tryFinishSetup() then return end

		warn("[DeathClient] DeathScreen not in PlayerGui yet — watching for it")
		local conn
		conn = playerGui.ChildAdded:Connect(function(child)
			if child.Name == "DeathScreen" then
				task.wait()
				if tryFinishSetup() and conn then
					conn:Disconnect()
				end
			end
		end)
	end

	return DeathClient
end
