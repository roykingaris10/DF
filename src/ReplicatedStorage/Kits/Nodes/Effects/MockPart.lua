return function(Name: string, CF: CFrame,Size : PartSize)
	local Part = Instance.new('Part')
	Part.Name = Name or 'MockPart'
	Part.Anchored, Part.CanCollide, Part.CanTouch, Part.CanQuery = true, false, false, false
	Part.CFrame, Part.Size = CF, Size
	Part.Transparency = 1
	Part.Material = Enum.Material.Neon
	Part.Parent = workspace.MockFolder
	return Part
end
