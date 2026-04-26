--[[
	[Cooldowns] The Ultimate Cooldown/Debounce Management Module System
	By @Luacathy - v1.0.0
	
	cooldown = Cooldowns.new(name?) -> CooldownInstance
		> Creates new cooldown instance if it doesn't exist already
	
	cooldown = Cooldowns.get(name) -> CooldownInstance?
		> Retrieves existing cooldown instance
		
	-- Properties --
    	> useScaledTime (boolean) - When true, durations are automatically scaled by timeScale
    	> timeScale (number) - Current time scaling factor (write via SetTimeScale)
    
	-- Core Methods --
	cooldown:Set(keyName, duration, callback?, ...) -> boolean
		> Always sets, overwrites if exists
		> Duration in seconds, callback fires on completion
		
	cooldown:Check(keyName, scaled?) -> (boolean, number?)
		> scaled: if true, returns timeLeft scaled by timeScale
		> Returns (doesNotExist: boolean, timeLeft: number?)
		> doesNotExist = false when cooldown active
		> timeLeft = time left when exists
	
	cooldown:Add(keyName, duration, callback?, ...) -> boolean
		> Only sets if key doesn't exist (non-overwriting)
	
	cooldown:Remove(keyName) -> boolean
		> Clears specified cooldown
		
	cooldown:Reset() -> boolean
	    > Clears ALL cooldowns in this instance
	    > Returns true if any cooldowns were removed
	    > For single cooldown removal, use :Remove()
	
	cooldown:Destroy()
		> Cleans up instance (Maid-compatible)
	
	-- Advanced Methods --
	cooldown:Pause(keyName) -> boolean
		> Freezes cooldown
	
	cooldown:Resume(keyName) -> boolean
		> Resumes cooldown
	
	cooldown:SetTimeScale(scale) -> boolean
		> Adjusts speed for all cooldowns (0.5 = 50% speed)
	
	cooldown:AdjustAllDurations(amount: number, predicate: function?) -> boolean
		> Adjusts all cooldown durations
		> predicate: optional filter function (receives CooldownEntry)
		
	cooldown:AdjustDuration(keyName: string, amount: number) -> boolean
		> Adjusts specific cooldown duration
		> Returns false if cooldown didn't exist
	
	Features:
	- Precision timing (auto-optimized near completion)
	- Time scaling (slow-mo/fast-forward/"Player Engagement Booster ;)" support)
	- Thread-safe callbacks
	- Batched processing
	- Predicate filtering for bulk operations
	
	Notes:
	- Uses Heartbeat for frame-accurate timing
	- Switches to high-precision mode near completion
	- Automatically disconnects when no cooldowns exist
	- Automatically reconnects when new cooldowns are added
	
	Example Usage:
    local Cooldowns = require(game.ReplicatedStorage.Cooldowns)
    local abilities = Cooldowns.new("PlayerAbilities")
    
    -- Set ability cooldown
    abilities:Set("Fireball", 5.0, function()
        print("Fireball ready!")
    end)
    
    -- Check if available
    local ready, remaining = abilities:Check("Fireball")
    if ready then
        print("Fireball available!")
    else
        print(string.format("Fireball cooldown: %.1fs", remaining))
    end
--]]

local RunService = game:GetService("RunService")

local Cooldowns = {
	instances = {},
	globalUpdate = nil
}

local MAX_UPDATES_PER_FRAME = 10000
local PRECISION_FACTOR = 0.01
local MIN_PRECISION_TIME = 0.25
local DEFAULT_TIME_SCALE = 1
local MIN_TIME_SCALE = 0.01

local PrivateMethods = {}

function PrivateMethods.maintainGlobalUpdate()
	if not Cooldowns.globalUpdate then
		Cooldowns.globalUpdate = RunService.Heartbeat:Connect(function(deltaTime)
			local hasActive = false
			
			for _, instance in pairs(Cooldowns.instances) do
				if instance.active then
					hasActive = true
					
					PrivateMethods.update(instance, deltaTime)
				end
			end
			
			if not hasActive and Cooldowns.globalUpdate then
				Cooldowns.globalUpdate:Disconnect()
				Cooldowns.globalUpdate = nil
			end
		end)
	end
end

function PrivateMethods.update(self, deltaTime)
	if not self.cooldownData then return end
	
	local scaledDelta = deltaTime * self.timeScale

	-- Create a snapshot
	local cooldownsToProcess = {}
	for keyName in pairs(self.cooldownData) do
		cooldownsToProcess[#cooldownsToProcess + 1] = keyName
		if #cooldownsToProcess >= MAX_UPDATES_PER_FRAME then
			break
		end
	end

	local isActive = false

	for _, keyName in ipairs(cooldownsToProcess) do
		local entry = self.cooldownData[keyName]
		if not entry then continue end  -- Skip if removed

		if not entry.paused then
			local precise = entry.timeLeft <= math.max(MIN_PRECISION_TIME, entry.time * PRECISION_FACTOR)
			
			if precise then
				entry.timeLeft = math.max(0, entry.time - (os.clock() - entry.startTime) * self.timeScale)
			else
				entry.timeLeft = math.max(0, entry.timeLeft - scaledDelta)
			end
			
			if entry.timeLeft <= 0 then
				-- Handle callback
				if entry.callback then
					local args = entry.arguments or {}
					
					task.spawn(function()
						local success, err = pcall(entry.callback, unpack(args))
						
						if not success then
							warn("Cooldown callback failed:", err)
						end
					end)
				end
				
				self.cooldownData[keyName] = nil
			end
		end
		
		isActive = true
	end
	
	if not self.cooldownData or next(self.cooldownData) == nil then
		self.cooldownData = nil
		self.active = false
	else
		self.active = isActive
	end
end

local Methods = {}
Methods.__index = Methods

type CooldownEntry = {
	time: number,
	startTime: number,
	timeLeft: number,
	callback: (...any) -> (...any)?,
	arguments: {any},
	paused: boolean,
}

export type CooldownInstance = {
	name: string,
	cooldownData: {[string]: CooldownEntry}?,
	active: boolean,
	timeScale: number,
	useScaledTime: boolean,
	
	SetTimeScale: (self: CooldownInstance, scale: number) -> boolean,
	Set: (self: CooldownInstance, keyName: string, duration: number, callback: ((...any) -> (...any)?), ...any) -> boolean,
	Check: (self: CooldownInstance, keyName: string, scaled: boolean?) -> (boolean, number?),
	Add: (self: CooldownInstance, keyName: string, duration: number, callback: ((...any) -> (...any)?), ...any) -> boolean,
	Remove: (self: CooldownInstance, keyName: string) -> boolean,
	Reset: (self: CooldownInstance) -> boolean,
	Pause: (self: CooldownInstance, keyName: string) -> boolean,
	Resume: (self: CooldownInstance, keyName: string) -> boolean,
	AdjustAllDurations: (self: CooldownInstance, amount: number, predicate: ((entry: CooldownEntry) -> boolean)?) -> boolean,
	AdjustDuration: (self: CooldownInstance, keyName: string, amount: number) -> boolean,
	Destroy: (self: CooldownInstance) -> ()
}

function Cooldowns.new(tableName: string?): CooldownInstance
	local name = tableName or "Cooldown_"..tostring(#Cooldowns.instances + 1)

	local existing = Cooldowns.instances[name]
	if existing and getmetatable(existing) == Methods then
		return existing
	end
	
	local self = setmetatable({
		name = name,
		cooldownData = {},
		active = false,
		timeScale = math.max(MIN_TIME_SCALE, DEFAULT_TIME_SCALE),
		useScaledTime = true,
	}, Methods)

	Cooldowns.instances[name] = self

	return self
end

function Cooldowns.get(tableName: string): CooldownInstance?
	return Cooldowns.instances[tableName]
end

function Methods:SetTimeScale(scale: number)
	assert(scale, "Missing scale for cooldowns")
	
	local oldScale = self.timeScale
	self.timeScale = math.max(MIN_TIME_SCALE, scale)
	
	local currentTime = os.clock()

	for keyName, entry in pairs(self.cooldownData) do
		if entry.timeScale ~= self.timeScale then
			if not entry.paused then
				-- Convert remaining time proportionally
				entry.timeLeft = entry.timeLeft * (oldScale / self.timeScale)
				entry.time = entry.time * (oldScale / self.timeScale)
				entry.startTime = currentTime - (currentTime - entry.startTime) * (self.timeScale / oldScale)
			else
				-- For paused cooldowns, just scale the remaining time
				entry.timeLeft = entry.timeLeft * (oldScale / self.timeScale)
				entry.time = entry.time * (oldScale / self.timeScale)
			end
		end
	end

	return true
end

function Methods:Set(keyName: string, duration: number, callback: (...any) -> (...any)?, ...: any): boolean
	assert(keyName, "Missing keyName for a cooldown")
	assert(duration, "Missing duration for a ["..keyName.."] cooldown")
	assert(duration >= 0, "Duration cannot be negative for ["..keyName.."] cooldown")
	
	PrivateMethods.maintainGlobalUpdate()
	
	local realDuration = self.useScaledTime and (duration / self.timeScale) or duration
	
	local entry = {
		time = realDuration,
		startTime = os.clock(),
		timeLeft = realDuration,
		callback = callback,
		arguments = {...},
		paused = false,
	}
	
	if not self.cooldownData then
		self.cooldownData = {}
	end

	self.cooldownData[keyName] = entry
	self.active = true
	
	return true
end

function Methods:Check(keyName: string, scaled: boolean?): (boolean, number?)
	if not self.cooldownData then
		return true
	end

	local entry = self.cooldownData[keyName]
	if not entry then
		return true
	end
	
	return false, scaled and (entry.timeLeft * self.timeScale) or entry.timeLeft
end

function Methods:Add(keyName: string, duration: number, callback: (...any) -> (...any)?, ...: any): boolean
	if self.cooldownData and self.cooldownData[keyName] then 
		return false 
	end

	return self:Set(keyName, duration, callback, ...)
end

function Methods:Remove(keyName: string): boolean
	if self:Check(keyName) then return end

	self.cooldownData[keyName] = nil

	if next(self.cooldownData) == nil then
		self.cooldownData = nil
	end

	return true
end

function Methods:Reset(): boolean
	if not self.cooldownData then return false end

	local hadCooldowns = next(self.cooldownData) ~= nil
	self.cooldownData = {}
	self.active = false
	
	return hadCooldowns
end

function Methods:Pause(keyName: string): boolean
	if self:Check(keyName) then return false end

	local entry = self.cooldownData[keyName]

	if entry.paused then
		return false
	end

	entry.time = entry.timeLeft
	entry.paused = true

	return true
end

function Methods:Resume(keyName: string): boolean
	if self:Check(keyName) then return false end

	local entry = self.cooldownData[keyName]

	if not entry.paused then
		return false
	end

	entry.startTime = os.clock()
	entry.paused = false

	return true
end

function Methods:AdjustAllDurations(amount: number, predicate: ((entry: CooldownEntry) -> boolean)?): boolean
	if not self.cooldownData then return false end
	
	assert(amount, "Missing amount adjustment for cooldowns")
	
	local realAmount = self.useScaledTime and (amount / self.timeScale) or amount

	for _, entry in pairs(self.cooldownData) do
		if not predicate or predicate(entry) then
			entry.time = math.max(0, entry.time + realAmount)
			entry.timeLeft = math.max(0, entry.timeLeft + realAmount)
		end
	end

	return true
end

function Methods:AdjustDuration(keyName: string, amount: number): boolean
	if self:Check(keyName) then return end
	
	assert(amount, "Missing amount adjustment for a ["..keyName.."] cooldown")
	
	local realAmount = self.useScaledTime and (amount / self.timeScale) or amount

	local entry = self.cooldownData[keyName]
	
	entry.time = math.max(0, entry.time + realAmount)
	entry.timeLeft = math.max(0, entry.timeLeft + realAmount)

	return true
end

function Methods:Destroy()
	if self.name and Cooldowns.instances[self.name] then
		Cooldowns.instances[self.name] = nil
	end

	setmetatable(self, nil)
end

return Cooldowns