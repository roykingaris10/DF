local module = {}

local ContentProvider = game:GetService("ContentProvider")

function module.GetImageSequences()
	local ImageSequencesArray = {}

	for i,v in pairs(script.ImageSequences:GetChildren()) do
		table.insert(ImageSequencesArray, v)
	end

	return ImageSequencesArray
end

function module.PreloadAsyncImageSequence(Base, Image, Property)
	--print(Image)

	local PreloadArray = {}

	for i,v in pairs(script.ImageSequences:GetDescendants()) do
		if v.ClassName == "Decal" then
			table.insert(PreloadArray, v)	
		end
	end

	print(PreloadArray)

	local startTime = os.clock()
	ContentProvider:PreloadAsync(PreloadArray)
	local deltaTime = os.clock() - startTime
	print(("Preloading complete, took %.2f seconds"):format(deltaTime))
end

function module.PlayPreloadImageSequence(Base, ImageSequence, Image, Property, FPS)

	local Array = {}

	for i,v in pairs(script.ImageSequences[ImageSequence]:GetChildren()) do
		table.insert(Array, v.Texture)
	end

	for i = 1, #Array do
		task.wait(1/FPS)
		Image[Property] = script.ImageSequences[ImageSequence][i].Texture
	end

end


function module.PreloadImageSequence(Base, ImageSequence, Image, Property, Lifetime)

	local startTime = os.clock()

	for i,v in pairs(script.ImageSequences[ImageSequence]:GetDescendants()) do
		if v.ClassName == "Decal" then
			local Clone = Image:Clone()
			Clone.Parent = Image.Parent
			Clone[Property] = v.Texture
			game:GetService("Debris"):AddItem(Clone, Lifetime)
		end
	end

	local deltaTime = os.clock() - startTime
	print(("Preloading complete, took %.2f seconds"):format(deltaTime))
end

function module.PreloadAllImageSequences(Base, ImageSequence, Image, Property, Lifetime)

	local startTime = os.clock()

	for i,v in pairs(script.ImageSequences:GetDescendants()) do
		if v.ClassName == "Decal" then
			local Clone = Image:Clone()
			Clone.Parent = Image.Parent
			Clone[Property] = v.Texture
			game:GetService("Debris"):AddItem(Clone, Lifetime)
		end
	end

	local deltaTime = os.clock() - startTime
	print(("Preloading complete, took %.2f seconds"):format(deltaTime))
end

function module.PlayImageSequence(Base, ImageSequence, Image, Property, FPS, Loop, AutoVisible : boolean, StartingFrame : IntValue, FrameFunction, Clone, Details)
	local FrameTime = 1

	if StartingFrame ~= nil then
		FrameTime = StartingFrame
	end

	FrameTime -= .99

	local TotalFrames = #script.ImageSequences[ImageSequence]:GetChildren()

	local Image = Image

	if Clone then
		local ImageClone = Image:Clone()
		ImageClone.Name = Image.Name .. " Clone"
		ImageClone.Visible = true
		ImageClone.Parent = Image.Parent
		Image = ImageClone
	end

	if Details then
		if Details.ZIndex then
			Image.ZIndex = Details.ZIndex
		end
	end

	if Loop then
		for i = 1,Loop do
			local Connection
			local EndYielding = false
			local Before = os.clock()
			FrameTime = 1
			FrameTime -= .99

			if Image:IsA("Image") then
				Image.ImageTransparency = 0
			elseif Image:IsA("Texture") then
				Image.Transparency = 0
			end

			if Details then
				if Details.BackgroundTransparency then
					Image.BackgroundTransparency = Details.BackgroundTransparency
				end
			end

			if StartingFrame ~= nil then
				FrameTime = StartingFrame
			end

			-- This is the actual amount of frames that have passed. Used to keep track of when certain frames last for longer because of FrameDuration.
			local ActualFrameCounter = FrameTime
			local LastFrame = math.ceil(FrameTime)

			Connection = game:GetService("RunService").RenderStepped:Connect(function(DT)
				local NewDT = DT * FPS

				local FreezeFrame = false

				-- Checks which is the current frame
				if math.ceil(FrameTime) > LastFrame then
					-- This calls a frame function if there is one
					if FrameFunction then
						warn("Calling function")

						local Function = FrameFunction(math.ceil(FrameTime), TotalFrames)
					end

					LastFrame = math.ceil(FrameTime)
				end


				local NeededFrame = script.ImageSequences[ImageSequence]:FindFirstChild(tonumber(math.ceil(FrameTime)))

				-- Checking for frame duration
				if NeededFrame then
					if NeededFrame:FindFirstChild("FrameDuration") then
						if (ActualFrameCounter - (FrameTime)) < NeededFrame:FindFirstChild("FrameDuration").Value then
							FreezeFrame = true
						end
					end

					Image[Property] = NeededFrame.Texture		
				else
					EndYielding = true
					Connection:Disconnect()
				end

				if FreezeFrame == false then
					FrameTime += NewDT
				end

				ActualFrameCounter += NewDT

			end)

			if Property == "Image" and AutoVisible then
				Image.Visible = true
			end

			repeat
				task.wait()
			until EndYielding

			if Property == "Image" and AutoVisible then
				Image.Visible = false

				if Clone then
					Image:Destroy()
				end
			end

			--print("Play time: ", os.clock() - Before, " Seconds")

		end
	else
		local Connection
		local FrameTime = 0
		local EndYielding = false

		Connection = game:GetService("RunService").RenderStepped:Connect(function(DT)
			local NewDT = DT * FPS
			FrameTime += NewDT
			local NeededFrame = script.ImageSequences[ImageSequence]:FindFirstChild(tonumber(math.ceil(FrameTime)))
			if NeededFrame then
				Image[Property] = NeededFrame.Texture
			else
				EndYielding = true
				Connection:Disconnect()
			end
		end)

		repeat
			task.wait()
		until EndYielding

	end

	if Clone then
		return Image
	end

end

function module.MeshSequence(Base, MeshSequence, Transparency, FPS, Loop, AutoVisible : boolean, StartingFrame : IntValue)
	local FrameTime = 0

	if StartingFrame ~= nil then
		FrameTime = StartingFrame
	end

	if Loop then
		for i = 1,Loop do
			local Connection
			local EndYielding = false
			local Before = os.clock()
			FrameTime = 0

			if StartingFrame ~= nil then
				FrameTime = StartingFrame
			end

			local OldMesh = MeshSequence:FindFirstChild("1")

			Connection = game:GetService("RunService").RenderStepped:Connect(function(DT)
				local NewDT = DT * FPS
				FrameTime += NewDT

				if AutoVisible then
					OldMesh.Transparency = 1
				end

				local NeededFrame = MeshSequence:FindFirstChild(tonumber(math.ceil(FrameTime)))
				if NeededFrame then
					NeededFrame.Transparency = Transparency	
				else
					EndYielding = true
					Connection:Disconnect()
				end

				OldMesh = NeededFrame
			end)

			repeat
				task.wait()
			until EndYielding

			--print("Play time: ", os.clock() - Before, " Seconds")

		end
	else
		local Connection
		local EndYielding = false
		local Before = os.clock()
		FrameTime = 0

		if StartingFrame ~= nil then
			FrameTime = StartingFrame
		end

		local OldMesh = MeshSequence:FindFirstChild("1")

		Connection = game:GetService("RunService").RenderStepped:Connect(function(DT)
			local NewDT = DT * FPS
			FrameTime += NewDT

			if AutoVisible then
				OldMesh.Transparency = 1
			end

			local NeededFrame = MeshSequence:FindFirstChild(tonumber(math.ceil(FrameTime)))
			if NeededFrame then
				NeededFrame.Transparency = Transparency	
			else
				EndYielding = true
				Connection:Disconnect()
			end

			OldMesh = NeededFrame
		end)

		repeat
			task.wait()
		until EndYielding
	end
end

--module.

return module
