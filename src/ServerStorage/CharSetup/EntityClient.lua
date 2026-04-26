return function(Client)
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local TroveFactory = require(Nodes.Utility.Trove);
	
	local Entity = {}
	Entity.__index = Entity
	
	function Entity.new(Character)
		local self = setmetatable({
			Character = Character;
			Inventory = false,
			Toolbar = false,
			EquippedItem = false,
			
			SprintSpeed = 26;
			WalkSpeed = 14;
			JumpHeight = 7.2;
			
			_Connections = {};
			_Threads = {};
			AnimHandler = false;

			_Class = 'Entity';
			Name = 'N/A',
			
			ClientState = "Neutral";
			ServerState = "Neutral";
			
			EquippedWeapon = false;

			SprintRequest = false;
			Sprinting = false;
			GroundState = true;

			StaminaTick = false,
			
			CameraStats = {};

			CombatData = {
				lastTick = 0,
				lastAirTick = 0,
				AirComboNum = 1,
				ComboNum = 1,
			};
			Stuns = {};
			Cooldowns = {};
			Temporary = {
				FacingBools = {},
			};
			
			CombatConn = {};
		}, Entity);
		return self;
	end
	
	function Entity:SetState(stateName, value)
		self.CombatData[stateName] = value
		self.Character:SetAttribute(stateName, value)
	end
	
return Entity end