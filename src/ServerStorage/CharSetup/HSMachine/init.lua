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
	
	function StateMachine.new(Character, initalHeir,initialState)
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
		
		for _, ModuleScript in script.Movement:GetChildren() do
			self.States[ModuleScript.Name] = require(ModuleScript)(Client)
		end
	
		for _, ModuleScript in script.Combat:GetChildren() do
			self.States[ModuleScript.Name] = require(ModuleScript)(Client)
		end
		
		for _, ModuleScript in script.Environment:GetChildren() do
			self.States[ModuleScript.Name] = require(ModuleScript)(Client)
		end
		self:ChangeState(initalHeir,initialState)
		return self;
	end
	
	function StateMachine:Trigger(Heir: string,Action: string, ...)
		if self.States[self.Heirs[Heir]][Action] == nil then
			warn(`Action: {Action} not found for state: {self.ClientState}`)
			return
		end
		return self.States[self.Heirs[Heir]][Action](self, ...)
	end
	
	function StateMachine:ChangeState(Heir: string, newStateName: string, Params: {any})
		local newState = self.States[newStateName]
		if not newState then return warn("MISSING STATE: ".. newStateName) end

		--[=[
		if self.Heirs[Heir] then
			if not self.States[self.Heirs[Heir]]:CanTransitionTo(newState) then return end
			self.Heirs[Heir]:Exit()
		end
		]=]
		
		-- enter new
		self.Heirs[Heir] = newStateName
	--	newState:Enter(Params)
	end



	
	return StateMachine end