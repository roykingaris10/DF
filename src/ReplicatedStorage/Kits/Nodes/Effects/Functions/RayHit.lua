local Hitbox = {}

function Hitbox:Start(Origin, Direction, Blacklist)
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	RayParams.IgnoreWater = true
	RayParams.FilterDescendantsInstances = Blacklist
	
	return workspace:Raycast(Origin, Direction, RayParams)
end

function Hitbox:StartI(Origin, Direction, Whitelist)

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Include
	RayParams.IgnoreWater = true
	RayParams.FilterDescendantsInstances = Whitelist

	return workspace:Raycast(Origin, Direction, RayParams)
end

return Hitbox
