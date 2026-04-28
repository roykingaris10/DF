return function(Client)
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local TroveFactory = require(Nodes.Utility.Trove);

	local StateMachine = {}
	StateMachine.__index = StateMachine

	local stateFactoryCache = nil
	local function ensureStateFactories()
		if stateFactoryCache then return stateFactoryCache end
		stateFactoryCache = {}
		for _, group in ipairs({"Movement", "Combat", "Environment"}) do
			local folder = script:FindFirstChild(group)
			if folder then
				for _, ModuleScript in ipairs(folder:GetChildren()) do
					if ModuleScript:IsA("ModuleScript") then
						local ok, factory = pcall(require, ModuleScript)
						if ok then
							stateFactoryCache[ModuleScript.Name] = factory
						else
							warn("[HSMachine] failed to require", ModuleScript:GetFullName(), factory)
						end
					end
				end
			end
		end
		return stateFactoryCache
	end

	function StateMachine.new(Character, initalHeir, initialState)
		local self = setmetatable({
			Character = Character;
			Humanoid = Character.Humanoid;
			Heirs = {
				Movement = nil,
				Combat = nil,
				Environment = nil,
			};
			States = {};
		}, StateMachine);

		local factories = ensureStateFactories()
		for name, factory in pairs(factories) do
			local ok, state = pcall(factory, Client)
			if ok then
				self.States[name] = state
			else
				warn("[HSMachine] state factory threw for", name, state)
			end
		end

		self:ChangeState(initalHeir, initialState)
		return self;
	end

	function StateMachine:Trigger(Heir: string, Action: string, ...)
		if self.States[self.Heirs[Heir]][Action] == nil then
			warn(`Action: {Action} not found for state: {self.ClientState}`)
			return
		end
		return self.States[self.Heirs[Heir]][Action](self, ...)
	end

	function StateMachine:ChangeState(Heir: string, newStateName: string, Params: {any})
		local newState = self.States[newStateName]
		if not newState then return warn("MISSING STATE: " .. newStateName) end
		self.Heirs[Heir] = newStateName
	end

	ensureStateFactories()

	return StateMachine
end