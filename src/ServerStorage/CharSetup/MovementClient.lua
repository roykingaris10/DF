return function(Client)
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local TroveFactory = require(Nodes.Utility.Trove);
	
	local MovementClient = {}
	MovementClient.__index = MovementClient
	
	function MovementClient.new(Character)
		local self = setmetatable({
			Character = Character;
			Humanoid = Character.Humanoid;
			
			Defaults = {
				WalkSpeed = 14,
				JumpPower = 50,
			};
			SprintSpeed = 22;
			BaseSpeed = 14;
			BaseJumpPower = 50;
			CurrentMomentum = 0;
			MaxMomentum = 10;
			
			Modifiers = {};
			Absolute = {};
			Buffs = {};
			
			_Connections = {};
			_Threads = {};
			
		}, MovementClient);
		
		self.Humanoid.WalkSpeed = self.BaseSpeed
		self.Humanoid.JumpPower = self.BaseJumpPower
		
		self:Start()
		return self;
	end
	
	function MovementClient:StartSprint()
		MovementClient:SetAbsolute("Sprint", {
			WalkSpeed = 22,
			Priority = 5
		});
	end;

	-- Stop sprinting
	function MovementClient:StopSprint()
		MovementClient:RemoveAbsolute("Sprint");
	end;
	
	function MovementClient:SetAbsolute(source, values, duration)
	--	local expireTime = duration and (tick() + duration) or nil
	--	self.Absolute[source] = {Values = values, Expire = expireTime}
	--	self:Recalculate()
		Network:post("ServerEvent","SetAbsolute",source, values, duration)
	end

	function MovementClient:RemoveAbsolute(source)
	--	self.Absolute[source] = nil
	--	self:Recalculate()
		Network:post("ServerEvent","RemoveAbsolute",source)
	end

	-- Buffs/debuffs
	-- values = {WalkSpeedAdd = number?, WalkSpeedMult = number?, JumpAdd = number?, JumpMult = number?}
	function MovementClient:AddBuff(source, values, duration)
	--	local expireTime = duration and (tick() + duration) or nil
	--	self.Buffs[source] = {Values = values, Expire = expireTime}
	--	self:Recalculate()
		Network:post("ServerEvent","AddBuff",source, values, duration)
	end

	function MovementClient:RemoveBuff(source)
	--	self.Buffs[source] = nil
	--	self:Recalculate()
		Network:post("ServerEvent","RemoveBuff",source)
	end
	
	function MovementClient:Update()
		local now = tick()

		-- Clear expired absolutes
		for k, entry in pairs(self.Absolute) do
			if entry.Expire and now >= entry.Expire then
				self.Absolute[k] = nil
			end
		end

		-- Clear expired buffs
		for k, entry in pairs(self.Buffs) do
			if entry.Expire and now >= entry.Expire then
				self.Buffs[k] = nil
			end
		end

		self:Recalculate()
	end

	-- Main recalculation
	function MovementClient:Recalculate()
		if not self.Humanoid then return end

		local final = {
			WalkSpeed = self.Defaults.WalkSpeed,
			JumpPower = self.Defaults.JumpPower,
		}

		-- Step 1: Check absolutes by priority
		local topPriority = -math.huge
		local winningAbsolute = nil

		for _, entry in pairs(self.Absolute) do
			local abs = entry.Values
			if abs.Priority and abs.Priority >= topPriority then
				topPriority = abs.Priority
				winningAbsolute = abs
			end
		end

		if winningAbsolute then
			if winningAbsolute.WalkSpeed ~= nil then
				final.WalkSpeed = winningAbsolute.WalkSpeed*self.Character:GetAttribute("TimeScale") or 1
			end
			if winningAbsolute.JumpPower ~= nil then
				final.JumpPower = winningAbsolute.JumpPower
			end
		else
			-- Step 2: Apply buffs/debuffs
			local walk = self.Defaults.WalkSpeed
			local jump = self.Defaults.JumpPower

			for _, entry in pairs(self.Buffs) do
				local buff = entry.Values
				if buff.WalkSpeedAdd then
					walk = walk + buff.WalkSpeedAdd
				end
				if buff.WalkSpeedMult then
					walk = walk * buff.WalkSpeedMult
				end
				if buff.JumpAdd then
					jump = jump + buff.JumpAdd
				end
				if buff.JumpMult then
					jump = jump * buff.JumpMult
				end
			end

			final.WalkSpeed = walk*self.Character:GetAttribute("TimeScale") or 1
			final.JumpPower = jump
		end

		-- Apply to humanoid
		self.Humanoid.WalkSpeed = final.WalkSpeed
		self.Humanoid.JumpPower = final.JumpPower
	end
	
	function MovementClient:Start()
		local Character = self.Character
		
		self._Connections["WalkSpeedChanged"] = Character:GetAttributeChangedSignal("WalkSpeed"):Connect(function()
			local newSpeed = Character:GetAttribute("WalkSpeed");
			if newSpeed and self.Humanoid then
				self.Humanoid.WalkSpeed = newSpeed;
			end;
		end);
		
		-- Listen to JumpPower attribute changes
		self._Connections["JumpPowerChanged"] = Character:GetAttributeChangedSignal("JumpPower"):Connect(function()
			local newJump = Character:GetAttribute("JumpPower");
			if newJump and self.Humanoid then
				self.Humanoid.JumpPower = newJump;
			end;
		end);

		-- Set initial values
		local initialSpeed = Character:GetAttribute("WalkSpeed");
		local initialJump = Character:GetAttribute("JumpPower");
		if initialSpeed then
			self.Humanoid.WalkSpeed = initialSpeed;
		end;
		if initialJump then
			self.Humanoid.JumpPower = initialJump;
		end;
		--[[
		local Connec: RBXScriptConnection;
		Connec = RunService.Heartbeat:Connect(function()
			if Character.Parent ~= workspace and Character.Parent ~= workspace.Entities then
				Connec:Disconnect();
				return;
			end;
			
			self:Update()	
		end)
		]]
	end
	
	return MovementClient end