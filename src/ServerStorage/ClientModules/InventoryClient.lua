return function(Client)
	local InventoryClient = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local LibraryInfo = Client.LibraryInfo
	local TweenService = game:GetService('TweenService')
	local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
	local HttpService = game:GetService("HttpService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local GuiService = game:GetService("GuiService")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local ItemFrames = {}
	local Toolbox = {}
	local Inventory = {}
	local Categories = {}
	local conn = false
	local mouseDown = false
	local equipdebounce = false

	local mouse = player:GetMouse()

	local PlayerGui = player:WaitForChild('PlayerGui')

	function InventoryClient:EquipWeapon(weaponInfo)
		Client.Entity.EquippedWeapon = weaponInfo
	end

	function InventoryClient:EquipItem(itemInfo)
		Client.Entity.EquippedItem = itemInfo
	end
	function InventoryClient:UnequipItem()
		Client.Entity.EquippedItem = false
	end

	function InventoryClient:InventoryUpdate(data)
		Client.Entity.Inventory = data
	end

	function InventoryClient:ToolbarUpdate(toolbardata)
		Client.Entity.Toolbar = toolbardata
	end

	local SortTable = {"Ability","Weapon","Equipment","Material","Utility","Quest Item","Treasure"}
	local SortColors = {
		["Ability"] = Color3.fromRGB(255, 199, 57),
		["Weapon"] = Color3.fromRGB(255, 41, 34),
		["Equipment"] = Color3.fromRGB(79, 149, 255),
		["Material"] = Color3.fromRGB(100, 124, 117),
		["Utility"] = Color3.fromRGB(103, 255, 103),
		["Quest Item"] = Color3.fromRGB(112, 56, 255),
		["Treasure"] = Color3.fromRGB(255, 123, 71),
	}

	function InventoryClient:SetupCategories()
		local HUD = PlayerGui.HUD
		local UI = PlayerGui.UI
		local ToolboxFrame = UI.MainTab.ToolboxFrame
		local InventoryFrame = UI.MainTab.InventoryFrame
		local InvScroll = InventoryFrame.InvFrame.InvScroll

		for i = 1,#SortTable do 
			local Divider = InvScroll.DividerTemplate:Clone()
			local Category = InvScroll.CategoryTemplate:Clone()

			Category.Name = SortTable[i].."Category"
			Divider.Name = SortTable[i].."Divider"
			Category.LayoutOrder = i
			Divider.LayoutOrder = i

			Divider.fade.CategoryName.Text = SortTable[i]

			Divider.Parent = InventoryFrame.InvFrame.InvScroll
			Category.Parent = InventoryFrame.InvFrame.InvScroll

			Categories[SortTable[i]] = {Category = Category, Divider = Divider}

			local expandBtn = Divider.expandBtn
			local State = expandBtn.State
			expandBtn.MouseEnter:Connect(function()
				expandBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
			end)

			expandBtn.MouseLeave:Connect(function()
				expandBtn.ImageColor3 = Color3.fromRGB(220,220,220)
			end)

			expandBtn.Activated:Connect(function()
				if State.Value == true then
					State.Value = false
					expandBtn.down.Visible = true
					expandBtn.up.Visible = false
					local categorytween = TweenService:Create(Category,TweenInfo.new(0.25),{Size = UDim2.new(0.964,0,0,5)})
					categorytween:Play()
					categorytween.Completed:Wait()
				else
					State.Value = true
					expandBtn.down.Visible = false
					expandBtn.up.Visible = true
					local CellCount = Category.Items.UIGridLayout.AbsoluteCellCount
					local TargetY = CellCount.Y*78

					local categorytween = TweenService:Create(Category,TweenInfo.new(0.25),{Size = UDim2.new(0.964,0,0,TargetY)})
					categorytween:Play()
					categorytween.Completed:Wait()
				end
				InventoryClient:UpdateInvScroll()
			end)
		end
	end
	
	function InventoryClient:UpdateAllCategory()
		for i = 1,#SortTable do 
			InventoryClient:UpdateCategory(SortTable[i])
		end
	end

	function InventoryClient:UpdateCategory(Sort)
		local UI = PlayerGui.UI
		local InventoryFrame = UI.MainTab.InventoryFrame
		local InvScroll = InventoryFrame.InvFrame.InvScroll

		local Category = InvScroll[Sort.."Category"]
		local Divider = InvScroll[Sort.."Divider"]
		local CellCount = Category.Items.UIGridLayout.AbsoluteCellCount

		Category.Size = UDim2.new(Category.Size.X.Scale,0,0,(CellCount.Y*78))

		if (#Category:GetChildren()-1) <= 0 then
			Category.Visible = false
			Divider.Visible = false
		else
			Category.Visible = true
			Divider.Visible = true
		end
		self:UpdateInvScroll()
	end

	function InventoryClient:UpdateInvScroll()
		local UI = PlayerGui.UI
		local InventoryFrame = UI.MainTab.InventoryFrame
		local InvScroll = InventoryFrame.InvFrame.InvScroll

		local function UpdateCanvasSize(Canvas, Constraint)
			Canvas.CanvasSize = UDim2.new(0, 0, 0, Constraint.AbsoluteContentSize.Y+20)
		end
		UpdateCanvasSize(InvScroll, InvScroll.UIListLayout)
	end



	function InventoryClient:DragItem(itemFrame, itemInfo, x, y)
		local HUD = PlayerGui.HUD
		local UI = PlayerGui.UI
		local ToolboxFrame = UI.MainTab.ToolboxFrame
		local InventoryFrame = UI.MainTab.InventoryFrame
		if InventoryFrame.Visible == false then return end
		local function isHoveringOverObj(obj)
			local slotted = false
			for i = 1,13 do
				if i < 13 then
					if obj.Name == InventoryClient.ToolbarFrames[i].Name then continue end
					local tx = InventoryClient.ToolbarFrames[i].AbsolutePosition.X
					local ty = InventoryClient.ToolbarFrames[i].AbsolutePosition.Y
					local bx = tx + InventoryClient.ToolbarFrames[i].AbsoluteSize.X
					local by = ty + InventoryClient.ToolbarFrames[i].AbsoluteSize.Y
					if mouse.X >= tx and mouse.Y >= ty and mouse.X <= bx and mouse.Y <= by then
						slotted = true
						return true,"Toolbar Slot", InventoryClient.ToolbarFrames[i]
					end

				elseif i == 13 then
					local tx = InventoryFrame.AbsolutePosition.X
					local ty = InventoryFrame.AbsolutePosition.Y
					local bx = tx + InventoryFrame.AbsoluteSize.X
					local by = ty + InventoryFrame.AbsoluteSize.Y
					if mouse.X >= tx and mouse.Y >= ty and mouse.X <= bx and mouse.Y <= by then
						slotted = true
						return true, "Inventory Slot", InventoryFrame
					end
				end
			end
			if slotted == false then
				return false
			end
		end

		local initialPos = itemFrame.Position
		local initialParent = itemFrame.Parent
		local mousePos = Vector2.new(mouse.X, mouse.Y)
		local offset = mousePos - itemFrame.AbsolutePosition 

		itemFrame.Parent = UI

		while mouseDown do
			itemFrame.Position = UDim2.new(0, mouse.X - offset.X, 0, mouse.Y - offset.Y+GuiService:GetGuiInset().Y) 
			RunService.Heartbeat:Wait()
		end

		local placementSet = false

		local newSlot, slotType, slotobj = isHoveringOverObj(itemFrame)
		--add future slot checks for gear slots
		if newSlot then
			if slotType == "Toolbar Slot" then
				if Client.Entity.Toolbar[tonumber(initialParent.Parent.Name)] then
					Client.Entity.Toolbar[tonumber(initialParent.Parent.Name)] = nil
				end
				if Client.Entity.Toolbar[tonumber(slotobj.Name)] then
					local itemHoldSwap = (initialParent.Name == "ItemHolderFrame")
					local swapFrame = slotobj.ItemHolderFrame:FindFirstChild(Client.Entity.Toolbar[tonumber(slotobj.Name)])
					if swapFrame then
						swapFrame.Parent = (itemHoldSwap and initialParent) or InventoryFrame.InvFrame.InvScroll[swapFrame:GetAttribute("Sort").."Category"].Items
						if not itemHoldSwap then
							InventoryClient:UpdateCategory(swapFrame:GetAttribute("Sort")) 
						else
							Client.Entity.Toolbar[tonumber(initialParent.Parent.Name)] = swapFrame.Name
						end 
					end
				end
				
				itemFrame.Parent = slotobj.ItemHolderFrame
				Client.Entity.Toolbar[tonumber(slotobj.Name)] = itemFrame.Name
				--	local ItemChange = Network:get('PlayerData',"ChangeItemSlot",itemInfo.Id,tonumber(itemFrame.Parent.Parent.Name))
				Client.PacketLinks["ChangeItemSlot"]:Fire(itemInfo.Id,tonumber(itemFrame.Parent.Parent.Name))
			elseif slotType == "Inventory Slot" then
				if initialParent.Name == "ItemHolderFrame" then
					Client.Entity.Toolbar[initialParent.Parent.Name] = nil
					itemFrame.Parent = InventoryFrame.InvFrame.InvScroll[itemFrame:GetAttribute("Sort").."Category"].Items
					InventoryClient:UpdateCategory(itemFrame:GetAttribute("Sort")) 
				else
					itemFrame.Parent = initialParent
				end
					Client.PacketLinks["ChangeItemSlot"]:Fire(itemInfo.Id,0)
			end
		else
			itemFrame.Parent = initialParent
		end

		print(Client.Entity.Toolbar)
	end

	function InventoryClient:SelectTool(itemFrame, itemInfo)
		local Humanoid = player.Character.Humanoid
		local normalSize = UDim2.fromOffset(66,66)
		local growSize = UDim2.new(1.03,0,1.03,0)

		if equipdebounce then return end
		equipdebounce = true
		if Client.Entity.EquippedItem and Client.Entity.EquippedItem.Id == itemInfo.Id then
			Network:post("ServerEvent","UnequipItem")
			local borderTween = TweenService:Create(itemFrame.ImageButton,TweenInfo.new(0.2),{ImageColor3 = Color3.fromRGB(255, 255, 255)})
			borderTween:Play()
			itemFrame.ImageButton.Size = UDim2.new(1,0,1,0)
			itemFrame.ImageButton.Position = UDim2.new(0.5,0,0.5,0)
			itemFrame.selected.Visible = false
		else
			if Client.Entity.EquippedItem then
				local oldFrame = Inventory[Client.Entity.EquippedItem.Id]
				if oldFrame then
					local borderTween = TweenService:Create(oldFrame.ImageButton,TweenInfo.new(0.2),{ImageColor3 = Color3.fromRGB(255, 255, 255)})
					borderTween:Play()
					oldFrame.ImageButton.Size = UDim2.new(1,0,1,0)
					oldFrame.ImageButton.Position = UDim2.new(0.5,0,0.5,0)
					oldFrame.selected.Visible = false
				end
			end
			Network:post("ServerEvent","EquipItem",itemInfo)
			local borderTween = TweenService:Create(itemFrame.ImageButton,TweenInfo.new(0.2),{ImageColor3 = Color3.fromRGB(255, 202, 11)})
			borderTween:Play()
			itemFrame.ImageButton.Size = UDim2.new(1.03,0,1.03,0)
			itemFrame.ImageButton.Position = UDim2.new(0.5,0,0.5,0)
			itemFrame.selected.Visible = true
		end

		equipdebounce = false
	end

	function InventoryClient:newItem(itemInfo)
		local UI = PlayerGui.UI
		local InventoryFrame = UI.MainTab.InventoryFrame
		local InvScroll = InventoryFrame.InvFrame.InvScroll

		local itemData = LibraryInfo[itemInfo.Name]
		if not itemData then return end

		local itemFrame = InvScroll.CategoryTemplate.Items.ItemTemplate:Clone()
		itemFrame.Name = itemInfo.Id
		itemFrame.ItemLabel.Text = itemInfo.Name
		itemFrame:SetAttribute("Sort",itemData.Sort)

		local foundslot = false
		for i, Id in pairs(Client.Entity.Toolbar) do
			if Id == itemInfo.Id then
				itemFrame.Parent = InventoryClient.ToolbarFrames[tonumber(i)].ItemHolderFrame
				InventoryClient.ToolbarFrames[tonumber(i)].Visible = true
				foundslot = true
				break
			end
		end
		if not foundslot then
			itemFrame.Parent = InvScroll[itemData.Sort.."Category"].Items
			InventoryClient:UpdateCategory(itemData.Sort)
		end
		itemFrame.diamond.ImageColor3 = SortColors[itemData.Sort]
		Inventory[itemInfo.Id] = itemFrame

		if itemInfo.Amount then
			itemFrame.ItemQuantity.Visible = (itemInfo.Amount > 1 and true) or false
			itemFrame.ItemQuantity.Text = tostring(itemInfo.Amount).."x"
		end
		local dragEngage = 0.5
		itemFrame.ImageButton.MouseButton1Down:Connect(function(x,y)
			mouseDown = true
			local dragtick = tick()
			task.spawn(function()
				repeat 
					task.wait(0.1)
				until not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				if dragtick + dragEngage > tick() then
					InventoryClient:SelectTool(itemFrame, itemInfo)
				end
			end)
			InventoryClient:DragItem(itemFrame, itemInfo, x ,y)
		end)

		itemFrame.MouseEnter:Connect(function()
			itemFrame.ItemHolderFrame.BackgroundColor3 = Color3.fromRGB(255, 229, 167)
			itemFrame.HoverSelect.Visible = true
		end)
		itemFrame.MouseLeave:Connect(function()
			itemFrame.ItemHolderFrame.BackgroundColor3 = Color3.fromRGB(232, 207, 139)
			itemFrame.HoverSelect.Visible = false
		end)
		itemFrame.Visible = true
		table.insert(ItemFrames,itemFrame)
	end
	
	function InventoryClient:ItemChanged(itemInfo)
		for index, item in ipairs(Client.Entity.Inventory) do
			if item.Id == itemInfo.Id then
				Client.Entity.Inventory[index] = itemInfo
				break
			end
		end
		local itemFrame = Inventory[itemInfo.Id]
		if itemFrame then
			if itemInfo.Amount then
				itemFrame.ItemQuantity.Visible = (itemInfo.Amount > 1 and true) or false
				itemFrame.ItemQuantity.Text = tostring(itemInfo.Amount).."x"
			end
		end
		
	end

	function InventoryClient:RemoveItem(itemId)
		for i, item in ipairs(Inventory) do
			if item.Id == itemId then
				table.remove(Inventory, i)
				break
			end
		end

		local oldSlot
		for i ,id in pairs(Client.Entity.Toolbar) do
			if id == itemId then
				oldSlot = i
				break
			end
		end
		if oldSlot then
			Client.Entity.Toolbar[oldSlot] = nil
		end
		
		local itemFrame = Inventory[itemId]
		if itemFrame then
			itemFrame:Destroy()
			itemFrame = nil
		end

	end

	function InventoryClient:Init()
		InventoryClient:SetupCategories()
		repeat task.wait(0.1) until Client.Entity.Inventory
		print(Client.Entity.Inventory)
		
		Network:bindEvent("newItem", function(itemInfo)
			InventoryClient:newItem(itemInfo)
		end)

		local UI = PlayerGui.UI
		local ToolboxFrame = UI.MainTab.ToolboxFrame
		local InventoryFrame = UI.MainTab.InventoryFrame

		InventoryClient.ToolbarFrames = {
			ToolboxFrame["1"];
			ToolboxFrame["2"];
			ToolboxFrame["3"];
			ToolboxFrame["4"];
			ToolboxFrame["5"];
			ToolboxFrame["6"];
			ToolboxFrame["7"];
			ToolboxFrame["8"];
			ToolboxFrame["9"];
			ToolboxFrame["10"];
			ToolboxFrame["11"];
		--	ToolboxFrame["12"];
		}	

		InventoryClient.ToolbarKeys = {
			[Enum.KeyCode.One] = 1, 
			[Enum.KeyCode.Two] = 2, 
			[Enum.KeyCode.Three] = 3, 
			[Enum.KeyCode.Four] = 4, 
			[Enum.KeyCode.Five] = 5, 
			[Enum.KeyCode.Six] = 6, 
			[Enum.KeyCode.Seven] = 7, 
			[Enum.KeyCode.Eight] = 8, 
			[Enum.KeyCode.Nine] = 9, 
			[Enum.KeyCode.Zero] = 10,
			[Enum.KeyCode.Minus] = 11,
		--	[Enum.KeyCode.Equals] = 12,
		}	

		local equipdebounce = false

		for index, item in pairs(Client.Entity.Inventory) do
			InventoryClient:newItem(item)
		end

		conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if InventoryClient.ToolbarKeys[input.KeyCode] and Client.Entity.Toolbar[InventoryClient.ToolbarKeys[input.KeyCode]] then
				local iteminfo 
				for i, v in pairs (Client.Entity.Inventory) do
					if v.Id == Client.Entity.Toolbar[InventoryClient.ToolbarKeys[input.KeyCode]] then
						iteminfo = v
						break
					end
				end
				InventoryClient:SelectTool(Inventory[iteminfo.Id], iteminfo)
			end
		end)

		UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseDown = false
			end
		end)
		

		
	end

	function InventoryClient:VisibleToolbar(state)
		local UI = PlayerGui.UI
		local ToolboxFrame = UI.MainTab.ToolboxFrame

		if state == true then
			for i,Boxes in pairs(ToolboxFrame:GetChildren()) do
				if not Boxes:IsA("Frame") then continue end
				Boxes.Visible = true
			end
		else 
			for i,Boxes in pairs(ToolboxFrame:GetChildren()) do
				if not Boxes:IsA("Frame") then continue end
				Boxes.Visible = false
			end

			for i,BoxNum in pairs(Toolbox) do
				local Box = ToolboxFrame:FindFirstChild(i)
				if Box and Box:IsA("Frame") then
					Box.Visible = true
				end
			end

		end

	end
	


	return InventoryClient end




