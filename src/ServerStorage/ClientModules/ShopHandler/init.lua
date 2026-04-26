return function(Client)
	local player = Client.player
	local Network = Client.Network
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService('ReplicatedStorage')
	local SoundService = game:GetService("SoundService")

	local ShopAssets = ReplicatedStorage:WaitForChild('Kits').UI
	local ItemStorage = ReplicatedStorage:WaitForChild('Kits'):WaitForChild('Storage'):WaitForChild('Items')
	local SpecTemplate = ReplicatedStorage:WaitForChild('Kits'):WaitForChild('UI'):WaitForChild('spec')
	local UISounds = ReplicatedStorage:WaitForChild('Kits'):WaitForChild('Sounds'):WaitForChild('UI')
	local PlayerGui = player:WaitForChild("PlayerGui")

	local ShopHandler = {
		shopOpened = false,
		shopConnections = {},
		currentShop = nil,
		currentNPC = nil,
		currentShopType = nil,
		currentShopSlogan = nil,
		viewportRotation = nil,
		viewportData = nil,
		specConnection = nil,
		activeSpecs = {}
	}

	local STAT_SLOT_ORDER = {"1", "2", "3", "4", "5", "6"}
	local FADE_DURATION = 0.25
	local STAGGER_DELAY = 0.08

	local SPEC_CONFIG = {
		maxSpecs = 20,
		spawnInterval = 0.1,
		minSpeed = 0.15,
		maxSpeed = 0.3,
		fadeStartPercent = 0,
	}

	local SKIP_FADE = {
		["itemFrame"] = true,
		["itemBtn"] = true,
		["overlay"] = true,
	}

	local function playSound(soundName)
		local sound = UISounds:FindFirstChild(soundName)
		if sound then
			local clone = sound:Clone()
			clone.Parent = SoundService
			clone:Play()
			clone.Ended:Once(function()
				clone:Destroy()
			end)
		end
	end

	local function clearSpecs(specEffect)
		if ShopHandler.specConnection then
			ShopHandler.specConnection:Disconnect()
			ShopHandler.specConnection = nil
		end

		for _, specData in ipairs(ShopHandler.activeSpecs) do
			if specData.instance and specData.instance.Parent then
				specData.instance:Destroy()
			end
		end
		ShopHandler.activeSpecs = {}
	end

	local function spawnSpec(specEffect)
		if #ShopHandler.activeSpecs >= SPEC_CONFIG.maxSpecs then return end

		local spec = SpecTemplate:Clone()

		local startY = math.random(5, 95) / 100
		local speed = SPEC_CONFIG.minSpeed + math.random() * (SPEC_CONFIG.maxSpeed - SPEC_CONFIG.minSpeed)

		spec.Position = UDim2.new(0, 0, startY, 0)
		spec.AnchorPoint = Vector2.new(0, 0.5)
		spec.ImageTransparency = 0.3 + math.random() * 0.4
		spec.Parent = specEffect

		local specData = {
			instance = spec,
			progress = 0,
			speed = speed,
			fadeStart = SPEC_CONFIG.fadeStartPercent + (math.random(-15, 15) / 100),
			baseTransparency = spec.ImageTransparency
		}

		table.insert(ShopHandler.activeSpecs, specData)
	end

	local function updateSpecs(dt)
		local toRemove = {}

		for i, specData in ipairs(ShopHandler.activeSpecs) do
			specData.progress = specData.progress + (dt * specData.speed)

			if specData.progress >= 1 then
				table.insert(toRemove, i)
			else
				specData.instance.Position = UDim2.new(specData.progress, 0, specData.instance.Position.Y.Scale, 0)

				if specData.progress > specData.fadeStart then
					local fadeProgress = (specData.progress - specData.fadeStart) / (1 - specData.fadeStart)
					specData.instance.ImageTransparency = specData.baseTransparency + (1 - specData.baseTransparency) * fadeProgress
				end
			end
		end

		for i = #toRemove, 1, -1 do
			local index = toRemove[i]
			local specData = ShopHandler.activeSpecs[index]
			if specData.instance and specData.instance.Parent then
				specData.instance:Destroy()
			end
			table.remove(ShopHandler.activeSpecs, index)
		end
	end

	local function startSpecEffect(shopUI)
		local specEffect = shopUI:FindFirstChild("specEffect")
		if not specEffect then return end

		clearSpecs(specEffect)

		local lastSpawn = 0

		ShopHandler.specConnection = RunService.RenderStepped:Connect(function(dt)
			if not ShopHandler.shopOpened then return end

			lastSpawn = lastSpawn + dt
			if lastSpawn >= SPEC_CONFIG.spawnInterval then
				spawnSpec(specEffect)
				lastSpawn = 0
			end

			updateSpecs(dt)
		end)
	end

	local function prepareItemForFade(itemHolder)
		local elementsToFade = {}

		for _, desc in ipairs(itemHolder:GetDescendants()) do
			if SKIP_FADE[desc.Name] then
				continue
			end

			local fadeData = nil

			if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
				local original = desc.TextTransparency
				if original < 1 then
					desc.TextTransparency = 1
					fadeData = {instance = desc, property = "TextTransparency", target = original}
				end
			elseif desc:IsA("ViewportFrame") then
				local original = desc.ImageTransparency
				desc.ImageTransparency = 1
				fadeData = {instance = desc, property = "ImageTransparency", target = original}
			elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
				local original = desc.ImageTransparency
				if original < 1 then
					desc.ImageTransparency = 1
					fadeData = {instance = desc, property = "ImageTransparency", target = original}
				end
			end

			if fadeData then
				table.insert(elementsToFade, fadeData)
			end
		end

		return elementsToFade
	end

	local function fadeInElements(elementsToFade)
		local tweenInfo = TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

		for _, data in ipairs(elementsToFade) do
			local tween = TweenService:Create(data.instance, tweenInfo, {[data.property] = data.target})
			tween:Play()
		end
	end

	local function clearViewport(viewport)
		for _, child in ipairs(viewport:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Camera") then
				child:Destroy()
			end
		end
	end

	local function clearMainViewport(viewport)
		if ShopHandler.viewportRotation then
			ShopHandler.viewportRotation:Disconnect()
			ShopHandler.viewportRotation = nil
		end
		ShopHandler.viewportData = nil
		clearViewport(viewport)
	end

	local function setupIconViewport(viewport, itemName, shopType)
		clearViewport(viewport)

		if not shopType then return end

		local folder = ItemStorage:FindFirstChild(shopType)
		if not folder then return end

		local itemModel = folder:FindFirstChild(itemName)
		if not itemModel then return end

		local clone

		if itemModel:IsA("Tool") then
			local handle = itemModel:FindFirstChild("Handle")
			if handle then
				clone = handle:Clone()
			else
				return
			end
		elseif itemModel:IsA("Model") then
			clone = itemModel:Clone()
		elseif itemModel:IsA("BasePart") then
			clone = itemModel:Clone()
		else
			return
		end

		if not clone then return end

		local cf, size

		if clone:IsA("Model") then
			clone:PivotTo(CFrame.new(0, 0, 0))
			cf, size = clone:GetBoundingBox()
		elseif clone:IsA("BasePart") then
			clone.CFrame = CFrame.new(0, 0, 0)
			cf = clone.CFrame
			size = clone.Size
		else
			clone:Destroy()
			return
		end

		clone.Parent = viewport

		local camera = Instance.new("Camera")
		camera.FieldOfView = 90
		camera.Parent = viewport
		viewport.CurrentCamera = camera

		local maxSize = math.max(size.X, size.Y, size.Z)
		local distance = maxSize * 0.9

		camera.CFrame = CFrame.new(
			cf.Position + Vector3.new(distance * 0.5, distance * 0.3, distance * 0.5),
			cf.Position
		)
	end

	local function setupMainViewport(viewport, itemName, shopType)
		clearMainViewport(viewport)

		if not shopType then return end

		local folder = ItemStorage:FindFirstChild(shopType)
		if not folder then return end

		local itemModel = folder:FindFirstChild(itemName)
		if not itemModel then return end

		local clone

		if itemModel:IsA("Tool") then
			local handle = itemModel:FindFirstChild("Handle")
			if handle then
				clone = handle:Clone()
			else
				return
			end
		elseif itemModel:IsA("Model") then
			clone = itemModel:Clone()
		elseif itemModel:IsA("BasePart") then
			clone = itemModel:Clone()
		else
			return
		end

		if not clone then return end

		local cf, size

		if clone:IsA("Model") then
			clone:PivotTo(CFrame.new(0, 0, 0))
			cf, size = clone:GetBoundingBox()
		elseif clone:IsA("BasePart") then
			clone.CFrame = CFrame.new(0, 0, 0)
			cf = clone.CFrame
			size = clone.Size
		else
			clone:Destroy()
			return
		end

		clone.Parent = viewport

		local camera = Instance.new("Camera")
		camera.Parent = viewport
		viewport.CurrentCamera = camera

		local maxSize = math.max(size.X, size.Y, size.Z)
		local distance = maxSize * 1.5

		ShopHandler.viewportData = {
			camera = camera,
			center = cf.Position,
			distance = distance,
			angle = 0
		}

		camera.CFrame = CFrame.new(
			cf.Position + Vector3.new(distance, distance * 0.5, distance),
			cf.Position
		)

		if not ShopHandler.viewportRotation then
			ShopHandler.viewportRotation = RunService.RenderStepped:Connect(function(dt)
				local data = ShopHandler.viewportData
				if not data or not data.camera or not data.camera.Parent then return end

				data.angle = data.angle + (dt * 0.5)

				local x = math.cos(data.angle) * data.distance
				local z = math.sin(data.angle) * data.distance
				local y = data.distance * 0.5

				data.camera.CFrame = CFrame.new(
					data.center + Vector3.new(x, y, z),
					data.center
				)
			end)
		end
	end

	local function flashOverlay(overlay, success)
		if not overlay then return end

		local flashColor = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		local originalColor = overlay.ImageColor3

		overlay.ImageColor3 = flashColor
		overlay.ImageTransparency = 0

		TweenService:Create(overlay, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 1,
			ImageColor3 = originalColor
		}):Play()
	end

	local function enterButton(itemHolder)
		local itemFrame = itemHolder:FindFirstChild("itemFrame")
		if not itemFrame then return end

		playSound("UIHover")

		local overlay = itemFrame:FindFirstChild("overlay")
		if overlay then
			TweenService:Create(overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageTransparency = 0
			}):Play()
		end

		TweenService:Create(itemHolder, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = itemHolder.Size + UDim2.new(0.01, 0, 0, 0)
		}):Play()
	end

	local function leaveButton(itemHolder)
		local itemFrame = itemHolder:FindFirstChild("itemFrame")
		if not itemFrame then return end

		local overlay = itemFrame:FindFirstChild("overlay")
		if overlay then
			TweenService:Create(overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				ImageTransparency = 1
			}):Play()
		end

		TweenService:Create(itemHolder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = itemHolder:GetAttribute("OriginalSize") or itemHolder.Size
		}):Play()
	end

	local function closeAllButtons(shopUI)
		local choiceHolder = shopUI:FindFirstChild("ChoiceHolder")
		if not choiceHolder then return end

		local choiceFrame = choiceHolder:FindFirstChild("ChoiceFrame")
		if not choiceFrame then return end

		for _, itemHolder in ipairs(choiceFrame:GetChildren()) do
			if itemHolder:IsA("Frame") then
				leaveButton(itemHolder)
			end
		end
	end

	local function showStatInfo(shopUI, itemInfo, itemName)
		local itemBox = shopUI:FindFirstChild("itemBox")
		if not itemBox then return end

		local statFrame = itemBox:FindFirstChild("StatFrame")
		if statFrame then
			for _, slotName in ipairs(STAT_SLOT_ORDER) do
				local slot = statFrame:FindFirstChild(slotName)
				if slot then
					slot.Visible = false
				end
			end

			local stats = itemInfo.Stats or {}
			local statList = {}

			for statName, statValue in pairs(stats) do
				table.insert(statList, {name = statName, value = statValue})
			end

			for i, statData in ipairs(statList) do
				local slotName = STAT_SLOT_ORDER[i]
				if not slotName then break end

				local slot = statFrame:FindFirstChild(slotName)
				if slot then
					slot.Visible = true

					local valueName = slot:FindFirstChild("value")
					if valueName then
						valueName.Text = (statData.name .. " // " .. statData.value):upper()
					end
				end
			end

			statFrame.Visible = true

			local itemTitle = itemBox:FindFirstChild("itemTitle")
			if itemTitle then
				local itemTitleName = itemTitle:FindFirstChild("itemTitleName")
				if itemTitleName then
					itemTitleName.Text = itemName:upper()
				end
			end

			local itemImage = itemBox:FindFirstChild("itemImage")
			if itemImage then
				itemImage.Visible = true

				local viewport = itemImage:FindFirstChild("viewport")
				if viewport then
					setupMainViewport(viewport, itemName, ShopHandler.currentShopType)
				end
			end
		end
	end

	local function clearStatInfo(shopUI)
		local itemBox = shopUI:FindFirstChild("itemBox")
		if not itemBox then return end

		local statFrame = itemBox:FindFirstChild("StatFrame")
		if statFrame then
			for _, slotName in ipairs(STAT_SLOT_ORDER) do
				local slot = statFrame:FindFirstChild(slotName)
				if slot then
					slot.Visible = false
				end
			end

			statFrame.Visible = false

			local itemTitle = itemBox:FindFirstChild("itemTitle")
			if itemTitle then
				local itemTitleName = itemTitle:FindFirstChild("itemTitleName")
				if itemTitleName then
					itemTitleName.Text = "..."
				end
			end

			local itemImage = itemBox:FindFirstChild("itemImage")
			if itemImage then
				itemImage.Visible = false

				local viewport = itemImage:FindFirstChild("viewport")
				if viewport then
					clearMainViewport(viewport)
				end
			end
		end
	end

	local function setNPCText(shopUI, text)
		local titleFrame = shopUI:FindFirstChild("TitleFrame")
		if not titleFrame then return end

		local titles = titleFrame:FindFirstChild("Titles")
		if not titles then return end

		local npcText = titles:FindFirstChild("NPCText")
		if npcText then
			npcText.Text = text
		end
	end

	local function setShopName(shopUI, shopName, shopSlogan, npcName)
		local titleFrame = shopUI:FindFirstChild("TitleFrame")
		if not titleFrame then return end

		local titles = titleFrame:FindFirstChild("Titles")
		if not titles then return end

		local npcNameLabel = titles:FindFirstChild("NPCName")
		if npcNameLabel then
			npcNameLabel.Text = (shopName or npcName or "Shop"):upper()
		end

		local shopDesc = titles:FindFirstChild("shopDesc")
		if shopDesc then
			shopDesc.Text = (shopSlogan or ""):upper()
		end
	end

	function ShopHandler.closeShop(shopUI)
		shopUI = shopUI or ShopHandler.currentShop
		if not shopUI then return end
		
		ShopHandler.currentShop.Beli.Parent = PlayerGui:FindFirstChild("HUD")

		for _, connection in ipairs(ShopHandler.shopConnections) do
			if typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			end
		end
		ShopHandler.shopConnections = {}

		if ShopHandler.viewportRotation then
			ShopHandler.viewportRotation:Disconnect()
			ShopHandler.viewportRotation = nil
		end
		ShopHandler.viewportData = nil

		local specEffect = shopUI:FindFirstChild("specEffect")
		if specEffect then
			clearSpecs(specEffect)
		end

		closeAllButtons(shopUI)
		clearStatInfo(shopUI)

		TweenService:Create(shopUI, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()

		task.delay(0.01, function()
			shopUI.Visible = false
		end)

		ShopHandler.shopOpened = false
		ShopHandler.currentShop = nil
		ShopHandler.currentNPC = nil
		ShopHandler.currentShopType = nil
		ShopHandler.currentShopDesc = nil
	end

	function ShopHandler.openShop(shopUI, NPC, shopData)
		if ShopHandler.shopOpened then
			ShopHandler.closeShop()
			task.wait(0.1)
		end

		if not shopData then return end

		ShopHandler.shopOpened = true
		ShopHandler.currentShop = shopUI
		ShopHandler.currentNPC = NPC
		ShopHandler.shopConnections = {}

		local details = shopData.Details or {}
		local stock = shopData.Stock or {}
		
		local HUD = PlayerGui:WaitForChild("HUD")
		HUD.Beli.Parent = ShopHandler.currentShop

		local shopName = details.ShopName or NPC.Name
		local shopType = details.ShopType or nil
		local shopSlogan = details.ShopSlogan or nil
		ShopHandler.currentShopType = shopType

		setShopName(shopUI, shopName, shopSlogan, NPC.Name)

		local choiceHolder = shopUI:FindFirstChild("ChoiceHolder")
		if not choiceHolder then return end

		local choiceFrame = choiceHolder:FindFirstChild("ChoiceFrame")
		if not choiceFrame then return end

		for _, child in ipairs(choiceFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local itemsToFade = {}

		for itemName, itemInfo in pairs(stock) do
			local itemHolder = ShopAssets.itemHolder:Clone()
			itemHolder:SetAttribute("OriginalSize", itemHolder.Size)

			local itemFrame = itemHolder:FindFirstChild("itemFrame")
			if itemFrame then
				local mainName = itemFrame:FindFirstChild("mainName")
				if mainName then
					mainName.Text = itemName:upper()
				end

				local itemDesc = itemFrame:FindFirstChild("desc")
				if itemDesc then
					itemDesc.Text = tostring(itemInfo.Desc):upper()
				end

				local itemPrice = itemFrame:FindFirstChild("value")
				if itemPrice then
					itemPrice.Text = ("$" .. tostring(itemInfo.Price) .. " BELI"):upper()
				end

				local overlay = itemFrame:FindFirstChild("overlay")
				if overlay then
					overlay.ImageTransparency = 1
				end

				local icon = itemFrame:FindFirstChild("icon")
				if icon then
					local iconViewport = icon:FindFirstChild("iconViewport")
					if iconViewport then
						setupIconViewport(iconViewport, itemName, shopType)
					end
				end

				local itemBtn = itemFrame:FindFirstChild("itemBtn")

				if itemBtn then
					local enterConn = itemBtn.MouseEnter:Connect(function()
						showStatInfo(shopUI, itemInfo, itemName)
						enterButton(itemHolder)
					end)
					table.insert(ShopHandler.shopConnections, enterConn)

					local leaveConn = itemBtn.MouseLeave:Connect(function()
						leaveButton(itemHolder)
						clearStatInfo(shopUI)
					end)
					table.insert(ShopHandler.shopConnections, leaveConn)

					local clickConn = itemBtn.MouseButton1Click:Connect(function()
						local success, message = Network:get('Shop', NPC, itemName)

						if success then
							setNPCText(shopUI, "Purchased " .. itemName .. "!")
							playSound("HackConfirm")
							flashOverlay(overlay, true)
						else
							setNPCText(shopUI, message or "Purchase failed!")
							playSound("DullPluck")
							flashOverlay(overlay, false)
						end

						task.delay(1, function()
							if shopUI.Visible and ShopHandler.shopOpened then
								setNPCText(shopUI, "I sell the finest weapons around young one... What peeks your interest?")
							end
						end)
					end)
					table.insert(ShopHandler.shopConnections, clickConn)
				end
			end

			local elementsToFade = prepareItemForFade(itemHolder)
			table.insert(itemsToFade, elementsToFade)

			itemHolder.Parent = choiceFrame
		end

		for i, elementsToFade in ipairs(itemsToFade) do
			task.delay((i - 1) * STAGGER_DELAY, function()
				fadeInElements(elementsToFade)
			end)
		end

		local endBtn = shopUI:FindFirstChild("End")
		if endBtn then
			local endConn = endBtn.MouseButton1Click:Connect(function()
				ShopHandler.closeShop(shopUI)
			end)
			table.insert(ShopHandler.shopConnections, endConn)
		end

		setNPCText(shopUI, "I sell the finest weapons around young one... What peeks your interest?")
		shopUI.Visible = true

		playSound("UISWIPE")
		startSpecEffect(shopUI)
	end

	function ShopHandler.checkDistance()
		if not ShopHandler.shopOpened or not ShopHandler.currentNPC then
			return true
		end

		local npcHRP = ShopHandler.currentNPC:FindFirstChild("HumanoidRootPart")
		local character = player.Character
		local playerHRP = character and character:FindFirstChild("HumanoidRootPart")

		if not npcHRP or not playerHRP then
			return true
		end

		local distance = (npcHRP.Position - playerHRP.Position).Magnitude
		return distance <= 50
	end

	function ShopHandler.Respawn()
		if ShopHandler.shopOpened then
			ShopHandler.closeShop()
		end

		ShopHandler.shopOpened = false
		ShopHandler.currentShop = nil
		ShopHandler.currentNPC = nil
		ShopHandler.currentShopType = nil
	end

	return ShopHandler
end