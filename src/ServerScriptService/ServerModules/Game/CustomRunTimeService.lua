local Server = require(script.Parent)
local Network = Server.Network

local RunService = game:GetService("RunService")

local CustomTimeService = {}
CustomTimeService.Controllers = {}
CustomTimeService.GlobalScale = 1

CustomTimeService.__index = CustomTimeService

function CustomTimeService:Get(entity)
	return self.Controllers[entity]
end

function CustomTimeService:SetGlobalScale(scale)
	self.GlobalScale = scale

	for _, controller in pairs(self.Controllers) do
		controller:SetModifier("Global", scale)
	end
end

RunService.Heartbeat:Connect(function(dt)
	workspace:SetAttribute("CustomRunTime", dt)
	for _, controller in pairs(CustomTimeService.Controllers) do
		controller:Step(dt)
	end
end)


return CustomTimeService 
