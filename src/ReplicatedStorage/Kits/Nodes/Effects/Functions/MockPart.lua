return function(Name: string, CF: CFrame,Size : PartSize)
	local Part = Instance.new('Part')
	Part.Name = Name or 'MockPart'
	Part.Anchored, Part.CanCollide, Part.CanTouch, Part.CanQuery = true, false, false, false
	Part.CFrame, Part.Size = CF, Size or Vector3.new(1,1,1)
	Part.Transparency = 1
	Part.Material = Enum.Material.Neon
	Part.Parent = workspace.MockFolder
	return Part
end
