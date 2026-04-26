local NewPart = {}

function NewPart.CreateNewPart(properties)
	local part = Instance.new("Part")
	

	
	for name, value in pairs(properties) do
			part[name] = value
	end
	
	return part
end

return NewPart
