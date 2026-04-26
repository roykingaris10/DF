local Viewport = {};


function Viewport:Set(ViewFrame: Instance, Item: Instance,options)
	local itemClone = Item:Clone()
	itemClone.Parent = ViewFrame
	itemClone:SetPrimaryPartCFrame(CFrame.new()*CFrame.Angles(math.rad(90),math.rad(35),0))
	
	-- Calculate model size and center
	local itemSize = itemClone:GetExtentsSize()
	local itemCenter = itemClone:GetBoundingBox().Position
	
	-- Camera setup
	local viewportCamera = Instance.new("Camera")
	ViewFrame.CurrentCamera = viewportCamera
	viewportCamera.Parent = ViewFrame
	
	local padding = options.Padding or 1.25 -- Multiplier for spacing
	local distance = math.max(itemSize.X, itemSize.Y, itemSize.Z) * padding
	viewportCamera.CFrame = CFrame.new(itemCenter + Vector3.new(0, distance/3, distance), itemCenter)
	
	if options.EnableLighting then
		local light = Instance.new("PointLight")
		light.Parent = viewportCamera
		light.Brightness = options.LightBrightness or 2
		light.Range = options.LightRange or 20
	end
	
	if options.RotateModel then
		task.spawn(function()
			while itemClone.Parent == ViewFrame do
				itemClone:SetPrimaryPartCFrame(itemClone.PrimaryPart.CFrame * CFrame.Angles(0,0, math.rad(1)))
				task.wait(0.03)
			end
		end)
	end
end;

function Viewport:AnimSet(ViewFrame: Instance, Item: Instance)

end;

return Viewport;