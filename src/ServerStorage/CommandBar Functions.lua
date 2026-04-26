--[[

Command bar functions 

-- Changes all keyframes for each keyframe sequence from an old part name to a new part name (EX: changing animations with Handle to NotHandle)
for _, keyFrameSeq in pairs(workspace.SwordRig1.AnimSaves:GetChildren()) do 
	if not keyFrameSeq:IsA("KeyframeSequence") then continue end 
	for _, keyFrame in pairs(keyFrameSeq:GetDescendants()) do keyFrame.Name = keyFrame.Name == 'Handle' and 'NotHandle' or keyFrame.Name end 
end

-- Copying Animation based on id
game:GetObjects("rbxassetid://" .. ID)[1].Parent = workspace

-- Converting animation to sequences
for _, v in pairs(game.ReplicatedFirst.Assets:GetDescendants()) do if v:IsA('Animation') then print('Converting '..v.Name) local animSeq = game:GetObjects(v.AnimationId)[1] animSeq.Name = v.Name animSeq.Parent = v.Parent v:Destroy() end
task.wait() end print('Completed Conversion')



-- Deletes everything inside all datastores in a game
local DSS = game:GetService("DataStoreService")
local DataStorePages = DSS:ListDataStoresAsync()
while true do
	local CurrentStoresPage = DataStorePages:GetCurrentPage()
	for i, DataStoreInfo in pairs(CurrentStoresPage) do
		local DataStore = DSS:GetDataStore(DataStoreInfo.DataStoreName)
		local KeysPages = DataStore:ListKeysAsync()
		while true do
			local CurrentKeysPage = KeysPages:GetCurrentPage()
			for j, Key in pairs(CurrentKeysPage) do
				local KeyStore = DataStore:GetAsync(Key.KeyName)

				print("deleting " .. Key.KeyName .. "...")

				DataStore:RemoveAsync(Key.KeyName)
			end
			if KeysPages.IsFinished then break end
			KeysPages:AdvanceToNextPageAsync()
		end
	end
	if DataStorePages.IsFinished then break end
	DataStorePages:AdvanceToNextPageAsync()
	task.wait() --you dont need this line if your data isnt too big
end
print("done deleting data")

--visualize ray gotta change some stuff up like origin and ray1
	local distance = (origin - ray1.Position).Magnitude
			local p = Instance.new("Part")
			p.Parent = workspace
			p.Anchored = true
			p.CanCollide = false
			p.Size = Vector3.new(0.1, 0.1, distance)
			p.CFrame = CFrame.lookAt(origin, ray1.Position)*CFrame.new(0, 0, -distance/2)
]]