local Server = require(script.Parent)

local Network = Server.Network
local Util = Server.Util
local CustomRunTimeService = Server.CustomRunTimeService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RunTimeService = {}
RunTimeService.__index = RunTimeService

RunTimeService.PlayerControls = {}
RunTimeService.GlobalScale = 1


local EASE_FUNCTIONS = {
	Sine   = function(a) return math.cos(a * math.pi * 0.5) end,
	Linear = function(a) return 1 - a end,
	Quad   = function(a) return (1 - a)^2 end,
}

local function GetCharacterMass(character)
	local mass = 0
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not part.Massless then
			mass += part.AssemblyMass
		end
	end
	return mass
end

local DEFAULT_GRAVITY = workspace.Gravity

function RunTimeService.new(Entity)
	local self = setmetatable({}, RunTimeService)
	
	self.Parent = Entity
	self.GameTime = 0
	
	self.Modifiers = {
		Global = 1,
		Base = 1,
	}
	
	self.RealTime = 0
	self.ScaledTime = 0 
	
	self.FinalTimeScale = 1
	self.Connections = {}
	
	self.BodyMovers = {}
	self.MoverState = {}
	
	self:SetModifier("Global", CustomRunTimeService.GlobalScale)
	
	
	CustomRunTimeService.Controllers[Entity] = self
	return self
end

function RunTimeService:Recalculate()
	local scale = 1
	for _, value in pairs(self.Modifiers) do
		scale *= value
	end

	self.FinalTimeScale = scale
end

function RunTimeService:SetModifier(name, value)
	self.Modifiers[name] = value
	self:Recalculate()
	self.Parent.StatManager:RecalculateMovement()
end

function RunTimeService:ModifyTemporary(name, value, duration)
	self:SetModifier(name, value)

	task.delay(duration, function()
		self:Wait(duration)
		if self then
			self:SetModifier(name, 1)
		end
	end)
end

function RunTimeService:UpdateBodyMovers(scaledDt)
	for key, data in pairs(self.BodyMovers) do
		local instance = data.Instance
	
		if not instance or not instance.Parent then
			self:RemoveMover(key)
			continue
		end

		if not self.MoverState[key] then
			self.MoverState[key] = {
				elapsed    = 0,
				CachedMass = self.Parent.Character.Rig and GetCharacterMass(self.Parent.Character.Rig) or 0,
				AntiGravAtt   = nil,
				AntiGravForce = nil,
			}

			-- Build the anti-gravity VectorForce once on init
			-- It will be updated every frame in the block below
			if data.AntiGravity and self.Parent.Character.Rig then
				local root = self.Parent.Character.Root
				if root then
					local att = Instance.new("Attachment")
					att.Name = "RuntimeAntiGrav_" .. key
					att.Parent = root

					local vf = Instance.new("VectorForce")
					vf.Name = "RuntimeAntiGravForce_" .. key
					vf.Attachment0 = att
					vf.RelativeTo = Enum.ActuatorRelativeTo.World
					vf.Force = Vector3.zero
					vf.Parent = root

					self.MoverState[key].AntiGravAtt   = att
					self.MoverState[key].AntiGravForce = vf
				end
			end
		end

		local state  = self.MoverState[key]
		local easeFn = EASE_FUNCTIONS[data.EaseStyle or "Sine"]

	
		local scale = data.ScaleOffRunTime and self.FinalTimeScale or 1.0

		state.elapsed += scaledDt

		local duration = data.Duration
		local effectiveDuration = duration and (duration / math.max(self.FinalTimeScale, 0.0001))
		
		local alpha    = duration and math.clamp(state.elapsed / duration, 0, 1) or 0
		local eased    = data.Ease and easeFn(alpha) or 1.0

		print(effectiveDuration)
		if data.Velocity then
			local finalVelocity = data.Velocity * eased * scale
			if instance:IsA("BodyVelocity") then
				instance.Velocity = finalVelocity
			elseif instance:IsA("LinearVelocity") then
				instance.VectorVelocity = finalVelocity
			end
		end

	
		if data.AngularVelocity then
			local finalAngular = data.AngularVelocity * eased * scale

			if instance:IsA("BodyAngularVelocity") then
				instance.AngularVelocity = finalAngular
			elseif instance:IsA("AngularVelocity") then
				instance.AngularVelocity = finalAngular
			end
		end

		if state.AntiGravForce and state.CachedMass > 0 then
			local cancelAmount = (1 - scale) * DEFAULT_GRAVITY * state.CachedMass
			state.AntiGravForce.Force = Vector3.new(0, cancelAmount, 0)
		end

		if effectiveDuration and state.elapsed >= effectiveDuration then
			if data.Velocity then
				if instance:IsA("BodyVelocity") then
					instance.Velocity = Vector3.zero
				elseif instance:IsA("LinearVelocity") then
					instance.VectorVelocity = Vector3.zero
				end
			end
			if data.AngularVelocity then
				if instance:IsA("BodyAngularVelocity") then
					instance.AngularVelocity = Vector3.zero
				elseif instance:IsA("AngularVelocity") then
					instance.AngularVelocity = Vector3.zero
				end
			end

			if state.AntiGravAtt   then state.AntiGravAtt:Destroy() end
			if state.AntiGravForce then state.AntiGravForce:Destroy() end

			if data.OnComplete then
				task.spawn(data.OnComplete)
			end

			self.BodyMovers[key]  = nil
			self.MoverState[key] = nil
		end
	end
end

function RunTimeService:RemoveMover(key)
	local state = self.MoverState[key]
	if state then
		if state.AntiGravAtt   then state.AntiGravAtt:Destroy() end
		if state.AntiGravForce then state.AntiGravForce:Destroy() end
	end
	self.BodyMovers[key]  = nil
	self.MoverState[key] = nil
end


function RunTimeService:Bind(key, callback)
	self.Connections[key] = callback
end

function RunTimeService:Unbind(key)
	self.Connections[key] = nil
end

function RunTimeService:Step(dt)
	if not self.Parent or not self.Parent.Character.Rig then return end
	local scaledDt = dt * self.FinalTimeScale
	self.GameTime += scaledDt
	self.Parent.Character:SetAttribute("TimeScale", self.FinalTimeScale)
	self:UpdateBodyMovers(scaledDt)

	for _, callback in pairs(self.Connections) do
		callback(scaledDt)
	end
end

function RunTimeService:Wait(duration)
	duration = duration or 0
	local elapsed = 0

	while elapsed < duration do
		local scaledDelta = RunService.Heartbeat:Wait() * self.FinalTimeScale
		elapsed += scaledDelta
	end

	return elapsed
end

function RunTimeService:Destroy()
	for i,v in pairs(self.Connections) do
		v:Disconnect()
	end
end

return RunTimeService
