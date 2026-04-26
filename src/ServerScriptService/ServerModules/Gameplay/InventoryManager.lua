local Server = require(script.Parent)

local Network = Server.Network
local LibraryInfo = Server.LibraryInfo
local WeldInfo = Server.WeldInfo
local ServerStorage = game:GetService('ServerStorage');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');
local HttpService = game:GetService("HttpService")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local ItemFolder = Kits.Storage.Items

local InventoryManager = {};
InventoryManager.__index = InventoryManager;

InventoryManager.new = function(Entity: {any})
	local self = setmetatable({
		
		Parent = Entity;
		SlotProfile = Entity.SlotProfile;
		EquippedItem = false;
		EquippedModel = false;
		Enabled = true;
		
		_Connections = {};
		_Cached = {};
		
	}, InventoryManager);
	
	return self;
end;

function InventoryManager:StarterPack()
	self.SlotProfile.packs["StarterPack"] = nil
	if not self.SlotProfile.packs["StarterPack"] then
		self.SlotProfile.packs["StarterPack"] = true
		self:AddItem("Watermelon", {Amount = 3})
		self:AddItem("Franky's Bolt", {})
	end
end


function InventoryManager:Execute()
	
	setmetatable(self.Parent.Data.Inventory, {
		__newindex = function(_, index, value)
			print(tostring(index) .. " has been added and set to " .. tostring(value))
		end
	})
	--[[
	task.wait(1)
	self.Parent.Data.Inventory[HttpService:GenerateGUID(false)] = {
		["Name"] = "Amulet of Imagination",
		["Type"] = "Relic",
		["Prestige"] = 0,
		["Equipped"] = false,
	}]]
end;

function InventoryManager:PlayerInventory()
	local InventoryFolder = Instance.new("Folder")
	InventoryFolder.Name = "InventoryFolder"
	InventoryFolder.Parent = self.Parent.player
	
	local ReservesFolder = Instance.new("Folder")
	ReservesFolder.Name = "ReservesFolder"
	ReservesFolder.Parent = InventoryFolder
	
	for i = 1,5 do
		local sectionFolder = Instance.new("Folder")
		sectionFolder.Name = i
		sectionFolder.Parent = ReservesFolder
	end
end

function InventoryManager:Setup()
	
end

function InventoryManager:FindFirstEmptyToolSlot()
	for i = 1,12 do
		if not self.SlotProfile.Toolbar[i] then
			return i
		end
	end
	
	return nil
end

function InventoryManager:ChangeItemSlot(itemId, slotnumber)
	
	local item = self:GetItemById(itemId)
	if not item then return end
	local ItemData = LibraryInfo[item.Name]
	if not ItemData then return end
	local oldSlot
	for i ,id in pairs(self.SlotProfile.Toolbar) do
		if id == itemId then
			oldSlot = i
			break
		end
	end
	if oldSlot then
		self.SlotProfile.Toolbar[oldSlot] = nil
	end
	
	if slotnumber == 0 then
		return
	end
	
	if self.SlotProfile.Toolbar[slotnumber] then
		local SwapSlotId = self.SlotProfile.Toolbar[slotnumber]
		self.SlotProfile.Toolbar[oldSlot] = SwapSlotId
	end
	
	self.SlotProfile.Toolbar[slotnumber] = item.Id
	print(self.SlotProfile.Toolbar)
end

function InventoryManager:EquipItem(itemInfo)
	local item = self:GetItemById(itemInfo.Id)
	if not item then return end
	local ItemData = LibraryInfo[item.Name]
	if not ItemData then return end
	self:UnequipItem()
	self.EquippedItem = item
	Network:post("ClientEvent",self.Parent.player,"EquipItem",item)

	local itemTemplate = ItemFolder[ItemData.Type]:FindFirstChild(item.Name)
	local WeldData = WeldInfo[item.Name] or WeldInfo.Default
	if itemTemplate then
		local itemModel = itemTemplate:Clone()
		itemModel.Parent = self.Parent.Character.ItemHolder
		local weldPart
		if itemModel:IsA("Model") then
			weldPart = itemModel.PrimaryPart
		elseif itemModel:IsA("BasePart") then
			weldPart = itemModel
		end
		
		local Motor = Instance.new("Motor6D")
		Motor.Part0 = self.Parent.Character.Rig[WeldData.Location]
		Motor.Part1 = weldPart
		Motor.C0 = WeldData.C0
		Motor.Parent = weldPart
		self.EquippedModel = itemModel
	end
end

function InventoryManager:UnequipItem()
	if not self.EquippedItem then return end
	if self.EquippedModel then
		self.EquippedModel:Destroy()
		self.EquippedModel = false
	end
	self.EquippedItem = false

	Network:post("ClientEvent",self.Parent.player,"UnequipItem")
end

function InventoryManager:AddItem(Name: string, CustomData: {any}?)
	local ItemData = LibraryInfo[Name]
	if not ItemData then return warn("MISSING ITEM INFO//"..Name) end;
	local itemId = "Item_"..game.HttpService:GenerateGUID(false)
	
	local newItem = {
		Name = Name;
		Id = itemId
	}
	
	if ItemData.Type == "Weapon" then
		
	elseif ItemData.Type == "Food" then
		newItem.Amount = (CustomData and ItemData.Stackable) and CustomData.Amount or 1
	end
	
	if ItemData.Stackable then
		local existingItem = self:GetItemByName(Name)
		if existingItem then
			existingItem.Amount = math.clamp(existingItem.Amount+ newItem.Amount,0,ItemData.MaxStack)
			return existingItem
		end
	elseif not ItemData.Stackable then
		local existingItem = self:GetItemByName(Name)
		if existingItem then return existingItem end -- maybe make it drop?
	end
	table.insert(self.SlotProfile.Inventory, newItem)

	local slot = self:FindFirstEmptyToolSlot()
	if slot then
		self.SlotProfile.Toolbar[slot] = itemId
	end
	
	Network:post("ClientEvent", self.Parent.player, "newItem", newItem)
	
	return newItem
end

function InventoryManager:UpdateItem(itemId, newProperties)
	
	for _, item in ipairs(self.SlotProfile.Inventory) do
		if item.Id == itemId then

			-- Update only the changed fields
			for key, value in pairs(newProperties) do
				item[key] = value
			end

		--	ItemChangedEvent:FireClient(player, item)
			Network:post("ClientEvent",self.Parent.player,"ItemChanged",item)

			return item
		end
	end

	return nil
end


function InventoryManager:RemoveItem(itemId)
	local inv = self.SlotProfile.Inventory
	for i, item in ipairs(inv) do
		if item.Id == itemId then
			table.remove(inv, i)
			local oldSlot
			for i ,id in pairs(self.SlotProfile.Toolbar) do
				if id == itemId then
					oldSlot = i
					break
				end
			end
			if self.EquippedItem.Id == itemId then
				self:UnequipItem()
			end
			if oldSlot then
				self.SlotProfile.Toolbar[oldSlot] = nil
			end
			Network:post("ClientEvent",self.Parent.player,"RemoveItem",itemId)
			break
		end
	end
end
function InventoryManager:GetItemById(itemId: string)
	local item = false
	
	for i, iteminfo in pairs(self.SlotProfile.Inventory) do
		if iteminfo.Id == itemId then
			item = iteminfo
			break
		end
	end
	
	return item
end

function InventoryManager:GetItemByName(itemName: string)
	local item = false

	for i, iteminfo in pairs(self.SlotProfile.Inventory) do
		if iteminfo.Name == itemName then
			item = iteminfo
			break
		end
	end

	return item
end

function InventoryManager:GetEquippedSlotInfo(GearType: string)
	local itemId = self.SlotProfile.equipped[GearType]
	if not itemId then warn("NO ITEM IN THAT SLOT") return false end
	
	local itemInfo = self:GetItemById(itemId)
	return itemInfo
end

function InventoryManager:FindStackableSlot(itemName, newItem)
	local ItemData = LibraryInfo[itemName]
	if not ItemData then return warn("MISSING ITEM INFO//"..itemName) end;
	for slot, item in pairs(self.SlotProfile.Inventory) do
		if item and item.Name == itemName and ItemData.Stackable then
			-- Check if stats match (for items with variable stats)
			if self:CanStackItems(item, newItem) and item.Amount < ItemData.MaxStack then
				return slot
			end
		end
	end
	return nil
end

function InventoryManager:Destroy()
	for _,v:RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;
end;

return InventoryManager;