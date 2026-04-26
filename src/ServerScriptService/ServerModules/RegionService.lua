local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RegionService = {
	playerRegions = {},
	regionParts = {},
	checkInterval = 0.5,
}

local DEFAULT_VERTICAL_LENIENCY = 500

local function isPointInPart(point, part)
	local relative = part.CFrame:PointToObjectSpace(point)
	local size = part.Size / 2

	if math.abs(relative.X) > size.X or math.abs(relative.Z) > size.Z then
		return false
	end

	if part:GetAttribute("Bounded3D") then
		return math.abs(relative.Y) <= size.Y
	end

	local leniency = part:GetAttribute("VerticalLeniency") or DEFAULT_VERTICAL_LENIENCY
	return math.abs(relative.Y) <= size.Y + leniency
end

local function getRegionAtPosition(position)
	local priorityOrder = {"Special", "Minor", "Major"}

	for _, regionType in ipairs(priorityOrder) do
		local regions = RegionService.regionParts[regionType]
		if regions then
			for regionName, part in pairs(regions) do
				if isPointInPart(position, part) then
					return regionName, regionType
				end
			end
		end
	end
	return nil, nil
end

local RegionConfig = require(ReplicatedStorage:WaitForChild("Kits"):WaitForChild("Nodes"):WaitForChild("Data"):WaitForChild("RegionConfig"))

local function registerRegionPart(typeName, part)
	if not part:IsA("BasePart") then
		return
	end
	if not RegionConfig:GetRegion(typeName, part.Name) then
		warn(("[RegionService] No config for %s/%q — check spelling/case in RegionConfig"):format(typeName, part.Name))
	end
	part.Transparency = 1
	part.CanCollide = false
	RegionService.regionParts[typeName] = RegionService.regionParts[typeName] or {}
	RegionService.regionParts[typeName][part.Name] = part
end

local function unregisterRegionPart(typeName, part)
	if RegionService.regionParts[typeName] then
		RegionService.regionParts[typeName][part.Name] = nil
	end
end

local function watchTypeFolder(typeFolder)
	RegionService.regionParts[typeFolder.Name] = RegionService.regionParts[typeFolder.Name] or {}
	for _, child in ipairs(typeFolder:GetChildren()) do
		registerRegionPart(typeFolder.Name, child)
	end
	typeFolder.ChildAdded:Connect(function(child)
		registerRegionPart(typeFolder.Name, child)
	end)
	typeFolder.ChildRemoved:Connect(function(child)
		unregisterRegionPart(typeFolder.Name, child)
	end)
end

-- Live cache: region parts that arrive after the service initializes
-- (replication, runtime spawning, edits in Studio) get picked up too.
local function loadRegionParts()
	local regionsFolder = workspace:FindFirstChild("Regions")
	if not regionsFolder then
		warn("[RegionService] No Regions folder found in workspace")
		return
	end

	for _, typeFolder in ipairs(regionsFolder:GetChildren()) do
		if typeFolder:IsA("Folder") then
			watchTypeFolder(typeFolder)
		end
	end

	regionsFolder.ChildAdded:Connect(function(child)
		if child:IsA("Folder") then
			watchTypeFolder(child)
		end
	end)
end

local function checkPlayerRegion(player)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local regionName, regionType = getRegionAtPosition(rootPart.Position)
	local currentData = RegionService.playerRegions[player.UserId]
	local currentRegion = currentData and currentData.region or nil

	if regionName ~= currentRegion then
		local oldRegion = currentRegion
		local oldType = currentData and currentData.regionType or nil

		if regionName then
			RegionService.playerRegions[player.UserId] = {
				region = regionName,
				regionType = regionType,
				enteredAt = tick(),
			}
			player:SetAttribute("CurrentRegion", regionName)
			player:SetAttribute("CurrentRegionType", regionType)
		else
			RegionService.playerRegions[player.UserId] = nil
			player:SetAttribute("CurrentRegion", nil)
			player:SetAttribute("CurrentRegionType", nil)
		end

		RegionService:OnRegionChanged(player, oldRegion, oldType, regionName, regionType)
	end
end

function RegionService:OnRegionChanged(player, oldRegion, oldType, newRegion, newType)
	if newRegion then
		print(string.format("[RegionService] %s entered %s (%s)", player.Name, newRegion, newType))
	elseif oldRegion then
		print(string.format("[RegionService] %s left %s (%s)", player.Name, oldRegion, oldType))
	end
end

function RegionService:GetPlayerRegion(player)
	local data = self.playerRegions[player.UserId]
	if data then
		return data.region, data.regionType
	end
	return nil, nil
end

function RegionService:GetPlayersInRegion(regionName)
	local playersInRegion = {}
	for userId, data in pairs(self.playerRegions) do
		if data.region == regionName then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				table.insert(playersInRegion, player)
			end
		end
	end
	return playersInRegion
end

function RegionService:IsPlayerInRegion(player, regionName)
	local data = self.playerRegions[player.UserId]
	return data and data.region == regionName
end

function RegionService:IsPlayerInRegionType(player, regionType)
	local data = self.playerRegions[player.UserId]
	return data and data.regionType == regionType
end

function RegionService:Init()
	loadRegionParts()

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			checkPlayerRegion(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		RegionService.playerRegions[player.UserId] = nil
	end)

	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= RegionService.checkInterval then
			accumulator = 0
			for _, player in pairs(Players:GetPlayers()) do
				checkPlayerRegion(player)
			end
		end
	end)
end

RegionService:Init()

return RegionService