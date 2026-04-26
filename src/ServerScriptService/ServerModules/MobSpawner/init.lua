local Server = require(script.Parent)
local LibraryInfo = Server.LibraryInfo
local EnemyInfo = Server.EnemyInfo
--//Variables
local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local HttpService = game:GetService("HttpService")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local Map: Folder = workspace:WaitForChild('Map');
local MobData: Folder = Map.Data.Mobs;
local MobEntities = require(script.MobEntities)

local EntityManager = Server.EntityService

--//Module
local MobSpawner = {};
MobSpawner.Enabled = true;
--SPAWN MOBS IN MAIN
MobSpawner.Types = {
	LightAttack = function(Entity: {any})
		repeat
			local ActionPathing = {"Combat","LightAttack"}
			Entity.ActionManager:StartAction(ActionPathing,{})
		--	Entity.ActionManager:Execute('Light', true,{});

			task.wait(.1);
		until not Entity.Character.Alive;
	end;
	Aerial = function(Entity: {any})
		repeat
			Entity.Character.Humanoid.Jump = true
			task.wait(0.15)
			local ActionPathing = {"Combat","Aerial"}
			Entity.ActionManager:StartAction(ActionPathing,{})
			Entity.Character.Humanoid.Jump = false
			task.wait(.6);
			
		until not Entity.Character.Alive;
	end;
	Critical = function(Entity: {any})
		repeat
			local ActionPathing = {"Combat","Critical"}
			Entity.ActionManager:StartAction(ActionPathing,{})
			--	Entity.ActionManager:Execute('Light', true,{});

			task.wait(.1);
		until not Entity.Character.Alive;
	end;
	Block = function(Entity: {any})
		repeat
			pcall(function()
				local ActionPathing = {"Combat","Block"}

				Entity.ActionManager:StartAction(ActionPathing,{Held = true})
			end);
			task.wait(5);
		until not Entity.Character.Alive;
	end;
	
	Parry = function(Entity: {any})
		task.wait(1)
		local ActionPathing = {"Combat","Block"}
		Entity.ActionManager:StartAction(ActionPathing,{Held = true})

		repeat
			pcall(function()
				Entity.Cooldowns:Remove("Parry")
				local ActionPathing2 = {"Combat","Parry"}
				Entity.ActionManager:StartAction(ActionPathing2,{Held = true})
			end)
			task.wait(0.2);
		until not Entity.Character.Alive;
	end;
	
	Neutral = function(Entity: {any})
		
	end,
	
	Active = function(Entity: {any})

	end,
};

function MobSpawner:SpawnDefault()
	for _,v: BasePart in MobData.DummySpawns:GetChildren() do
		task.spawn(function()
			MobSpawner:DummySpawn(v.Name, v.CFrame,v:GetAttribute("DummyMode"));
		end);
	end;
end;

MobSpawner.Spawned = function(Entity: {any}, DummyFunc: () -> ()?)
	if DummyFunc then
		task.spawn(DummyFunc, Entity);
	end;

	
	--NEED TO CHANGE UNDER
	--[[ 
	local DummyBar: BillboardGui = Shared.Storage.DummyItems.DummyHealth:Clone();
	DummyBar.Parent = Entity.Character.Rig.Head;
	
	local _BarConnec: RBXScriptConnection = Entity.Character.HealthChanged.Event:Connect(function()
		DummyBar.HealthPercentage.Text = tostring(math.floor((Entity.Character.Health/Entity.Character.MaxHealth)*100))..'%';
	end);
	]]	
	--Entity.Character.Rig:FindFirstChild('VelocityVisualiser').Enabled = true;
	
	Entity.Character.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;
	Entity.Character.Died.Event:Wait();
	
	--Entity.Character.Rig:FindFirstChild('VelocityVisualiser').Enabled = false;
--	_BarConnec:Disconnect();
--	DummyBar:Destroy();
end;

function MobSpawner:Spawn(DummyType: string, Location: CFrame?)
	if not MobSpawner.Enabled then return end;
	print("WOWA")
--	local DummyFunc = MobSpawner.Types[DummyType];
	
	local Entity = Server.EntityService.Spawn(DummyType);
	repeat wait() until Entity.Ready;
	Entity.Character.SpawnPosition = Location;
	
	MobSpawner:SetupKit(Entity,DummyType)
	Entity.Character:BindSpawn();
	Entity.Character:BindToSpawn(function()
		MobSpawner.Spawned(Entity);
		
	end);
	Entity.Name = Entity.Character.Rig.Name
end;

function MobSpawner:DummySpawn(DummyType: string, Location: CFrame?, DummyMode: string?)
	if not MobSpawner.Enabled then return end;
	local DummyFunc = MobSpawner.Types[DummyMode];

	local Entity = Server.EntityService.Spawn(DummyType,MobEntities.Dummy.Data);
	repeat wait() until Entity.Ready;
	Entity.Character.SpawnPosition = Location;

--	MobSpawner:SetupKit(Entity,DummyType)
	Entity.Character:BindSpawn();
	Entity.Character:BindToSpawn(function()
		MobSpawner.Spawned(Entity,DummyFunc);
	end);
--	MobSpawner.Spawned(Entity,DummyFunc);
	Entity.Name = Entity.Character.Rig.Name..HttpService:GenerateGUID(false)
	Entity.Character.CombatData.Name = Entity.Name
	Entity.Character.Rig.Name = Entity.Name
	Entity.EquippedWeapon = "Fists"
end;

return MobSpawner;