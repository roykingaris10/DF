-- || Simple Linear Compass Script ||
-- || by TheCarbyneUniverse		   ||

local frame = script.Parent
local n, e, s, w, ne, nw, se, sw, nw2, n2, ne2 = frame.N, frame.E, frame.S, frame.W, frame.NE, frame.NW, frame.SE, frame.SW, frame.NW2, frame.N2, frame.NE2
local directions = {nw, n, ne, e, se, s, sw, w, nw2, n2, ne2}
local camera, cameraPart = workspace.CurrentCamera, workspace.CameraPart
local absoluteSize, canvasSize, Inc = 0, 0, 0

local function partToCamera() 
	cameraPart.CFrame = camera.CFrame 
end

local function tickMarks(position, thickness)	
	local mark = Instance.new("Frame")
	mark.AnchorPoint = Vector2.new(0.5, .1)
	mark.Position = UDim2.new(0, position, 0, 0)
	mark.BorderSizePixel = 0
	mark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mark.Name = "TickMark"

	if thickness == "thicker" then mark.Size = UDim2.new(0, 3, 0.15, 0) end
	if thickness == "thick" then mark.Size = UDim2.new(0, 3, 0.15, 0) end
	if thickness == "thin" then mark.Size = UDim2.new(0, 1, 0.35, 0) end
		
	mark.Parent = frame
	return mark	
end

local function removeTickMarks()
	for i, v in pairs(frame:GetChildren()) do		
		if v.Name == "TickMark" then v:Destroy() end		
	end		
end

local function updateTickMarks()
	for i, v in pairs(frame:GetChildren()) do
		if v:IsA("TextLabel") then
			local pxPos = v.Position.X.Offset
			
			if #v.Text == 1 then tickMarks(pxPos, "thicker") end
			if #v.Text == 2 then tickMarks(pxPos, "thick") end	
		end
		
	end
	
	for j = 22.5, 427.5, 45 do tickMarks(j * Inc, "thin") end
	
	--[[You can add in more "sub" tick marks if you want, but don't get to crazy since your game can get a little laggy due to 
		 due to an excessive number of frames!]]
		
	for k = 11.25, 416.25, 45 do tickMarks(k * Inc, "thin") end
	for l = 33.75, 438.75, 45 do tickMarks(l * Inc, "thin") end
end

local function positionElements()
	absoluteSize = frame.AbsoluteSize.X
	canvasSize = absoluteSize * 5
	
	Inc = (absoluteSize * 4) / 360
	
	for i, dir in ipairs(directions) do			
		dir.Position = UDim2.new(0, 45 * (i - 1) * Inc, 0.5, 0)			-- 0, 45, 90, ... canvasSize
	end
	
	removeTickMarks()
	updateTickMarks()
	
	frame.CanvasSize = UDim2.new(0, canvasSize, 0, 0)
end

local function moveWithOrientation()
	local orientationY = cameraPart.Orientation.Y
	local inc = (absoluteSize * 4) / 360
	local deg = 0
	
	
	if orientationY < 0 then 
		deg = 180 + (180 + orientationY) 
	else 
		deg = orientationY 
	end
	
	deg = 360 - deg
	frame.CanvasPosition = Vector2.new(deg * inc, 0)
	positionElements()
end

moveWithOrientation()
partToCamera()

cameraPart:GetPropertyChangedSignal("Orientation"):Connect(moveWithOrientation)
frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(positionElements)
camera:GetPropertyChangedSignal("CFrame"):Connect(partToCamera)