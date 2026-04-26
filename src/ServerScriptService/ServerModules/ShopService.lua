local Server = require(script.Parent)
local Network = Server.Network

local ShopService = {}

local ShopInfo = Server.ShopInfo
local LibraryInfo = Server.LibraryInfo

local function validatePurchase(player, NPC, itemName)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return false, "Character not loaded"
	end

	if not NPC or not NPC:FindFirstChild("HumanoidRootPart") then
		return false, "Invalid NPC"
	end

	local distance = (player.Character.HumanoidRootPart.Position - NPC.HumanoidRootPart.Position).Magnitude
	if distance > 50 then
		return false, "Too far from shop"
	end

	if not ShopInfo[NPC.Name] then
		return false, "Shop not found"
	end

	local stock = ShopInfo[NPC.Name].Stock
	if not stock or not stock[itemName] then
		return false, "Item not in this shop"
	end

	if not LibraryInfo[itemName] then
		return false, "Item data not found"
	end

	return true
end

function ShopService.BuyItem(player, NPC, itemName)
	local valid, errorMsg = validatePurchase(player, NPC, itemName)
	if not valid then
		return false, errorMsg
	end

	local entity = Server.EntityService.Find(player)
	if not entity then
		return false, "Entity not found"
	end

	local profile = entity.SlotProfile
	local stock = ShopInfo[NPC.Name].Stock
	local itemBuyInfo = stock[itemName]
	local itemLibrary = LibraryInfo[itemName]

	if profile.UserData.Beli < itemBuyInfo.Price then
		return false, `Not enough Beli (Need ${itemBuyInfo.Price}, Have ${profile.UserData.Beli})`
	end

	local oldBeli = profile.UserData.Beli

	profile.UserData.Beli = profile.UserData.Beli - itemBuyInfo.Price
	player:SetAttribute('Beli', profile.UserData.Beli)

	if player:FindFirstChild("StatFolder") then
		local userFolder = player.StatFolder:FindFirstChild("UserFolder")
		if userFolder then
			userFolder:SetAttribute('Beli', profile.UserData.Beli)
		end
	end

	Network:post("BeliUpdate", player, oldBeli, profile.UserData.Beli, itemBuyInfo.Price)

	local amount = itemLibrary.PickupAmount or 1
	local newItem = entity.InventoryManager:AddItem(itemName, {Amount = amount})

	if not newItem then
		profile.UserData.Beli = profile.UserData.Beli + itemBuyInfo.Price
		player:SetAttribute('Beli', profile.UserData.Beli)
		if player:FindFirstChild("StatFolder") then
			local userFolder = player.StatFolder:FindFirstChild("UserFolder")
			if userFolder then
				userFolder:SetAttribute('Beli', profile.UserData.Beli)
			end
		end
		Network:post("BeliUpdate", player, profile.UserData.Beli - itemBuyInfo.Price, profile.UserData.Beli, 0)
		return false, "Failed to add item to inventory"
	end

	return true, `Purchased {itemName}!`
end

Network:bindFunction('Shop', function(player, NPC, itemName)
	return ShopService.BuyItem(player, NPC, itemName)
end)

return ShopService