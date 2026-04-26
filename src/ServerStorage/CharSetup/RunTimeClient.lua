return function(Client)

	local Network = Client.Network
	local Util = Client.Util
	local CustomRunTimeClient = Client.CustomRunTimeClient

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local RunTimeClient = {}
	RunTimeClient.__index = RunTimeClient

	RunTimeClient.PlayerControls = {}
	RunTimeClient.GlobalScale = 1

	function RunTimeClient:new(Character)
		local self = setmetatable({
		
			_Connections = {};
			_Threads = {};

		}, RunTimeClient);
		return self;
	end

	function RunTimeClient:Recalculate()
		local scale = 1
		for _, value in pairs(self.Modifiers) do
			scale *= value
		end

		self.FinalTimeScale = scale
	end

	function RunTimeClient:SetModifier(name, value)
		self.Modifiers[name] = value
		self:Recalculate()
	end

	function RunTimeClient:ModifyTemporary(name, value, duration)
		self:SetModifier(name, value)

		task.delay(duration, function()
			if self then
				self:SetModifier(name, 1)
			end
		end)
	end

	function RunTimeClient:Bind(key, callback)
		self.Connections[key] = callback
	end

	function RunTimeClient:Unbind(key)
		self.Connections[key] = nil
	end

	function RunTimeClient:Step(dt)
		local scaledDt = dt * self.FinalTimeScale
		self.GameTime += scaledDt

		for _, callback in pairs(self.Connections) do
			callback(scaledDt)
		end
	end

	function RunTimeClient:Wait(duration)
		duration = duration or 0
		local elapsed = 0

		while elapsed < duration do
			local scaledDelta = RunService.Heartbeat:Wait() * Client.Entity.Character:GetAttribute("TimeScale") or 1
			elapsed += scaledDelta
		end

		return elapsed
	end

	function RunTimeClient:Destroy()
		for i,v in pairs(self.Connections) do
			v:Disconnect()
		end
	end

	return RunTimeClient end
