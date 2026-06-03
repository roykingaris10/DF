local Server = require(script.Parent)

local Network = Server.Network
local Utilities = Server.Utilities
local CharacterCustomizationInfo = Server.CharacterCustomizationInfo
local LibraryInfo = Server.LibraryInfo
local ItemInfo = Server.ItemInfo

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local Entities = workspace.Entities

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes
local MobTemplates = Kits.Storage.MobTemplates
local TroveFactory = require(Nodes.Utility.Trove);
local Signal = require(Nodes.Utility.Signal);
local Auxiliary = require(Nodes.Utility.Auxiliary);
local RagdollModule = require(script.RagdollModule)

local Characters = {};
Characters.__index = Characters;

Characters.Default = {
	SpawnTime = 4;
	MaxHealth = 100;

	ProtectionDuration = 5;

	DefaultTemporary = {
		MovementDirection = 'Forward';
	},
};

local CharacterHandler = {
	Temporary = Auxiliary.Shared.DeepClone(Characters.Default.DefaultTemporary);
	CharacterInfo = {};
}

Characters.new = function(Entity: {any})
	local self = setmetatable({

		Parent = Entity;
		SlotProfile = Entity.SlotProfile;

		Spawned = Instance.new('BindableEvent');
		Died = Instance.new('BindableEvent');
		HealthChanged = Instance.new('BindableEvent');
		RespawnEvent = Instance.new('BindableEvent');

		ForwardPush = Instance.new('NumberValue');

		Alive = false;
		WillProc = false;

		Buffed = false;
		Ragdolled = false;

		HealthRegeneration = true;
		SpawnProtection = false;

		_DeathQueue = false;
		_BrokenJoints = false;

		_OwnershipQueue = {};
		_ActiveQueue = {};
		_StunQueue = {};
		_AnchorQueue = {};
		_EvasiveQueue = {};

		_CanCollide = true;
		_Massless = false;

		CanRagdoll = true;

		RagdollQueue = {};

	}, Characters);

	self.ForwardPush.Changed:Connect(function()
		Characters._PushChanged(self, self.ForwardPush.Value);
	end);

	return self;
end;

function Characters:_PushChanged(NewValue: number)
	if not self.Rig then return end;
	self.Rig:SetAttribute('ForwardPush', NewValue);
end;

function Characters:Create(NoPositioning: boolean?)
	self._DeathQueue = false;
	self.RagdollQueue = {};
	
	if self.Parent.player then
		self.Parent.player:LoadCharacter();
		self.Rig = self.Parent.player.Character or self.Parent.player.CharacterAdded:Wait();

		repeat wait() until self.Rig:IsDescendantOf(workspace);
	else
		self.Rig = self.Template:Clone();
	end;
--[[	
	if self.Parent.player then
		print("wajb")
		Network:post("ClientEvent",self.Parent.player, "SpawnSetup",
			self.Parent.InventoryManager:GetEquippedSlotInfo() or false,
			self.SlotProfile.Inventory,
			self.SlotProfile.Toolbar
		)
	end
	

	Network:post("ClientEvent",self.Parent.player, "EquippedWeaponInfo",self.Parent.InventoryManager:GetEquippedSlotInfo() or false)
	Network:post("ClientEvent",self.Parent.player, "InventoryUpdate",self.SlotProfile.Inventory)
	Network:post("ClientEvent",self.Parent.player, "ToolbarUpdate",self.SlotProfile.Toolbar)
]]
	self.Rig.Parent = Entities;
--[[
	if SetupHandler[self.Parent.Data.Character] then
		SetupHandler[self.Parent.Data.Character](self.Rig)
	end
]]
	if self.HitboxPart then
		self.HitboxPart:Destroy();
	end;

	self.Humanoid = self.Rig:FindFirstChildOfClass('Humanoid');
	self.Animator = self.Humanoid:WaitForChild('Animator');
	self.Root = self.Rig:FindFirstChild('HumanoidRootPart');
	self.ItemHolder = self.Rig:FindFirstChild("ItemHolder")
	self.RaceAccHolder = self.Rig:FindFirstChild("RaceAccHolder")
	self.WeaponHolder = self.Rig:FindFirstChild("WeaponHolder")

	self.MaxHealth = Characters.Default.MaxHealth;
	self.Health = self.MaxHealth;
	self.Humanoid.MaxHealth = self.MaxHealth;
	self.Humanoid.BreakJointsOnDeath = false;
	self.Humanoid.RequiresNeck = false;
	self.Humanoid.UseJumpPower = true;
	self.Humanoid.AutomaticScalingEnabled = false
	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	if self.Parent.player then
		local ud = (self.SlotProfile and self.SlotProfile.UserData) or {}
		local f = ud.FirstName or ""
		local m = ud.MiddleName
		local l = ud.LastName or ""
		local fullName
		if m and m ~= "" then
			fullName = f .. " " .. m .. " " .. l
		else
			fullName = f .. " " .. l
		end
		fullName = (fullName:gsub("^%s+", ""):gsub("%s+$", ""))
		if fullName == "" then
			fullName = self.Parent.player.DisplayName ~= "" and self.Parent.player.DisplayName or self.Parent.player.Name
		end
		self.Humanoid.DisplayName = fullName
		self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
		self.Humanoid.NameDisplayDistance = 100
		self.Humanoid.HealthDisplayDistance = 0
		self.Humanoid.NameOcclusion = Enum.NameOcclusion.NoOcclusion
		print("[NameTag-Server]", self.Parent.player.Name, "set DisplayName:", fullName,
			"Mode:", self.Humanoid.DisplayDistanceType, "Dist:", self.Humanoid.NameDisplayDistance)
	end
	
	self.Parent.Animator:Cache();
	if self.Parent.player then
		local sm = self.Parent.StatManager
		if sm then
			sm.Health = sm.MaxHealth
			sm.Stamina = sm.MaxStamina
			sm.Will = sm.MaxWill
			sm.Hunger = sm.MaxHunger
			sm.Posture = 0
		end
		print("[CharacterManager] Create -> SetupLooks for", self.Parent.player.Name)
		local ok, err = pcall(function()
			self.Parent.EquipmentManager:SetupLooks()
		end)
		if not ok then
			warn("[CharacterManager] SetupLooks failed:", err)
		end
		
		Network:post("ClientEvent",self.Parent.player, "SpawnSetup",
			self.Parent.InventoryManager:GetEquippedSlotInfo() or false,
			self.SlotProfile.Inventory,
			self.SlotProfile.Toolbar
		)
	end

	self.Ragdolled = false;
	self.Alive = true;

	self.Stunned = false;
	self.Active = false;
	self.Buffed = false;

	self.CanRagdoll = true;

	self._CanCollide = true;
	self._Massless = false;
	self._BrokenJoints = false;

	if self.RagdollMovement then
		self.RagdollMovement.Remove();
	end;
	
	local DataFolder = Kits.Storage.CombatDataTemplate:Clone()
	DataFolder.Name = self.Rig.Name
	DataFolder.Parent = workspace.CombatData
	self.CombatData = DataFolder

	Entities.ChildRemoved:Connect(function(child)
		if workspace.CombatData:FindFirstChild(child.Name) then
			workspace.CombatData:FindFirstChild(child.Name):Destroy()
		end
	end)

	local HealthScript = self.Rig:FindFirstChild('Health');
	if HealthScript then
		HealthScript:Destroy();
	end;
	
	self.Parent.StatManager:SetupUserAttr()
	self.Parent.StatManager:CalculateStats()
	self.Parent.StatManager:ResourcesSetup()

--	self.Parent.StatManager:StaminaSetup()
	
--	self.Rig:SetAttribute('CanEvade', true);

	self._Colliders = {};
	for _,v in pairs(self.Rig:GetDescendants()) do
		if v:IsA("BasePart") then v.CollisionGroup = "Characters"  table.insert(self._Colliders, v); end
	end
	
	self:RagdollSetup()
	self.DeathConnec = self.Humanoid.Changed:Connect(function()
		if self.Humanoid.Health <= 0 then
			self:OnDeath();
		end;
	end);
	
	
	
	--[[
	while self.Parent.player do
		task.wait(1)
		self.Parent.StatManager:AddEXP(50)
	end
]]
	if not self.Parent.player then
		self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);
		self.Parent.Name = (self.Rig.Humanoid.DisplayName ~= '' and self.Rig.Humanoid.DisplayName) or self.Rig.Name;
	end;

--	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false);

	if not self.Parent.player then
		local NewSpawn = self.SpawnPosition or self:GetClosestSpawn();
		self.Rig:PivotTo(((typeof(NewSpawn) == 'CFrame') and NewSpawn) or CFrame.new(NewSpawn));
	end

	self.Spawned:Fire();
end;

function Characters:OnDeath()
	self.Alive = false;
	self.DeathConnec:Disconnect();
print("NFNFVMV")
	--if self.Active or self.Stunned then
	--	repeat RunService.Heartbeat:Wait() until not self.Active and not self.Stunned;
	--end;
	local LastHit = self.Parent.Combat.LastHit;
	if LastHit and LastHit.Tick then
		self:KillFeed(LastHit)
	end
	if LastHit and LastHit.Person and LastHit.Person.player and Server.QuestService and Server.QuestService.RegisterEvent then
		local victimRig = self.Rig
		local target = victimRig and (victimRig:GetAttribute("QuestTarget") or victimRig.Name)
		if target then
			Server.QuestService:RegisterEvent(LastHit.Person.player, "Kill", target, 1)
		end
	end
	if self.Parent.ActionManager and self.Parent.ActionManager.DragEnd then
		self.Parent.ActionManager:DragEnd()
	end
--	self.Died:Fire();

	for Attribute: string in self.Rig:GetAttributes() do
		self.Rig:SetAttribute(Attribute, nil);
	end;

	self.Rig:SetAttribute('Dead', true);
	self._LastDeathLocation = self.Root.Position;

	self:ChangeHealth(0, true);

--	self:ToggleSprint(false);

	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
	self:Ragdoll(true);
	--self.MoveConnec:Disconnect();

	if not self.Parent.player and not RunService:IsStudio() then return end;

	
	self.Parent.Combat.LastHit = nil;

	if not LastHit then return end;
	if not LastHit.Valid then return end;
	if not LastHit.player then return end;

	--LastHit:AddKill();
end;

function Characters:KillFeed(LastHit)
	local KillParticipation = 6
	
	local KillerText
	local KillerCharName
	local DeathText 
	local VictimText 
	local VictimCharName
	print(tick() - LastHit.Tick)
	if tick() - LastHit.Tick < KillParticipation then
		if not LastHit.Person then return end
		if self.Parent.player then
			VictimText = self.Parent.player.DisplayName
		else
			VictimText = self.Rig.Name
		end
		VictimCharName = self.Rig.Name
		if LastHit.Person.player then
			KillerText = LastHit.Person.player.DisplayName
		else
			KillerText = LastHit.Person.Character.Rig.Name
		end
		KillerCharName = LastHit.Person.Character.Rig.Name
		if LastHit.Item then
			local function chooseText(Item)
				local ItemData = ItemInfo[Item] 
				if not ItemData then return end
				if ItemData.DeathText then
					local DeathTextTable = ItemData.DeathText
					local randomDeathText = DeathTextTable[math.random(1, #DeathTextTable)]
					return randomDeathText
				else
					return "eliminated"
				end
			end
			DeathText = chooseText(LastHit.Item)
		else
			DeathText = "eliminated"
		end
		
		local DeathMsgInfo = {
			KillerText = KillerText,
			KillerCharName = KillerCharName,
			DeathText = DeathText,
			VictimText = VictimText,
			VictimCharName = VictimCharName,
		}
		
		self.Parent.VFX:Fire({Module = "UIEffect",SubModule = "NotificationUI",},"KillFeed", {DeathMsgInfo = DeathMsgInfo})
	end
	
end

function Characters:RagdollSetup()
	local user = self.Rig

	RagdollModule:BuildCollisionParts(user)
end

function Characters:Ragdoll(Val: boolean | number, Absolute: boolean?)
	if not self.CanRagdoll then return end;
	if self._BrokenJoints then return end;
	if self.Alive and self.Buffed then return end;
	if Val then
		self.Parent.Server.Blocking = false;
	end;

	local IsDuration = typeof(Val) == 'number';
	if self.Ragdolled then
		if not IsDuration and Val == true then return; end;
	end;
	if IsDuration then
		self:RagdollStart()
		task.delay(Val, function()
			self:RagdollEnd()
		end);
	else
		if Val then
			self:RagdollStart()
		else
			self:RagdollEnd()
		end
	end;
end

function Characters:RagdollStart()
	local user = self.Rig

	RagdollModule:replaceJoints(user)
	--	RagdollModule:EnableMotor6D(user,false)
	--	RagdollModule:BuildJoints(user)
	RagdollModule:EnableCollisionParts(user,true)

	local function Push()
		self.Rig.Torso:ApplyImpulse(self.Rig.Torso.CFrame.LookVector * -100);
	end;
	user:SetAttribute("Ragdoll",true)
	user:SetAttribute("Draggable",true)
	if self.Parent.player then
		Network:post("Ragdoll",self.Parent.player,{Bool = true})
	else
		self:AssignOwnership(nil)
		self.Humanoid.AutoRotate = false
		self.Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		self.Humanoid.PlatformStand = true
	
		Push();

	end
end

function Characters:RagdollEnd()
	local user = self.Rig
	if not user.Parent then return end
	local Humanoid = user:FindFirstChild("Humanoid")
	local RootPart = user:FindFirstChild("HumanoidRootPart")

	if not RootPart then return end

	user:SetAttribute("Ragdoll",false)
	user:SetAttribute("Draggable",false)
	if self.Parent.player then
		Network:post("Ragdoll",self.Parent.player,{Bool = false})
	else
		self:AssignOwnership(false)
		if Humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
		self.Humanoid.AutoRotate = true
		
		self.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		self.Humanoid.PlatformStand = false
	
	end
	RagdollModule:resetJoints(user)
	--	RagdollModule:DestroyJoints(user)
	--	RagdollModule:EnableMotor6D(user,true)
	RagdollModule:EnableCollisionParts(user,false)
	
end

function Characters:Kill()
	self:ChangeHealth(0);
end;

function Characters:BindSpawn(Bool: boolean)
	task.spawn(function()
		repeat
			self:Create();

			local ProceedSlow;
			local ProceedFast;

			local Connec1: RBXScriptConnection = self.Died.Event:Once(function()
				ProceedSlow = true;
				print("DIEDA FUNCAA")
			end);

			local Connec2: RBXScriptConnection = self.RespawnEvent.Event:Once(function()
				ProceedFast = true;
			end);

			repeat task.wait() until ProceedSlow or ProceedFast;
			Connec1:Disconnect();
			Connec2:Disconnect();

			if not ProceedFast then 
				task.wait(Characters.Default.SpawnTime);
			end;	

			if not self.Parent.player and self.Rig then
				self.Rig:Destroy();
			end;
		until not self.Parent.Valid;

		self:Destroy();
	end);
end;

function Characters:Anchor(Bool: boolean)
	if Bool then
		table.insert(self._AnchorQueue, true);
	else
		table.remove(self._AnchorQueue, 1);
	end;

	if #self._AnchorQueue == 0 then
		self.Root.Anchored = false;
	else
		self.Root.Anchored = true;
	end;
end;

function Characters:SetCameraFacing(Bool: boolean)
	if not self.Parent.player then return end;
	Network:Send('FacingCamera', {Bool=Bool}, false, self.Parent.player);
end;

function Characters:SetActive(Bool: boolean)
	if Bool then
		table.insert(self._ActiveQueue, true);
	else
		table.remove(self._ActiveQueue, 1);
	end;

	local IsActive = #self._ActiveQueue > 0;

	self.Active = IsActive;
	self.Rig:SetAttribute('Active', IsActive);
end;

function Characters:SetStunned(Bool: boolean)
	if Bool then
		table.insert(self._StunQueue, true);
	else
		table.remove(self._StunQueue, 1);
	end;

	local IsStunned = #self._StunQueue > 0;

	self.Stunned = IsStunned;
	self.Rig:SetAttribute('Stunned', IsStunned);
end;
--[[
function Characters:SetStunned(Bool: boolean)
	self.Stunned = Bool;
	self.Rig:SetAttribute('Stunned', Bool);
end;
]]
function Characters:SetCurrentAttack(Num: number)
	self.CurrentAttack = Num;
	self.Rig:SetAttribute('CurrentAttack', Num);
end;

function Characters:SetCurrentAirAttack(Num: number)
	self.CurrentAirAttack = Num;
	self.Rig:SetAttribute('CurrentAirAttack', Num);
end;

function Characters:UpdateJump(NewNum: number)
	self.Parent.Server.DefaultJump = NewNum;
	self.Parent.Combat:UpdateMobility();
end;

function Characters:FacingPointer(Enabled: boolean, Lifted: boolean)
	local SettingValue = nil;
	if Enabled then
		SettingValue = (Lifted and 'Lifted') or 'Normal';
	end;

	self.Rig:SetAttribute('FacingPointer', SettingValue);
end;

function Characters:CreateBodyPosition(Owner)
	if Owner.player then
		self:AssignOwnership(Owner.player);
	end;

	local BPObject = {};
	local BodyPosition = Auxiliary.Shared.CreatePosition(self.Root);
	BodyPosition.Position = self.Root.Position;

	BPObject.Instance = BodyPosition;

	function BPObject.Remove()
		BodyPosition:Destroy();
		if Owner.player then
			self:AssignOwnership(false);
		end;
	end;

	return BPObject;
end;

function Characters:SetRootOwner(player: player?)
	task.spawn(function()
		self._LastRootOwner = player;
		if self.Root.Anchored then
			repeat task.wait() until self._LastRootOwner ~= player or not self.Root.Anchored;
			if self._LastRootOwner ~= player then return end;
		end;
		if not self.Root then return end
		self.Root:SetNetworkOwner(self._LastRootOwner);
	end);
end;

function Characters:BreakJoints()
	self._BrokenJoints = true;
	for _,v: Instance in self.Rig:GetDescendants() do
		if v:IsA('Weld') or v:IsA('Motor6D') or v:IsA('BallSocketConstraint') then
			v:Destroy();
		end;
	end;

	if self.Alive then
		self:Kill();
	end;
end;

function Characters:IsGrounded()
	local Fetched;
	local ServerStatus = self.Humanoid.FloorMaterial ~= Enum.Material.Air;

	if self.Parent.player then
		Fetched = Network:Send('Fetch', {Fetching='FloorMaterial'}, 1, self.Parent.player);
	end;

	if Fetched then
		return Fetched ~= Enum.Material.Air;
	else
		return ServerStatus;
	end;
end;

function Characters:AssignOwnership(player: player? | boolean)
	if player then
		table.insert(self._OwnershipQueue, self.Parent.player or player);
	elseif player == false then
		Auxiliary.Shared.RemoveFirstValue(self._OwnershipQueue);
	else
		return;
	end;

	if #self._OwnershipQueue == 0 then
		self:SetRootOwner(self.Parent.player);
	else
		local Major = Auxiliary.Shared.GetMajorityElement(self._OwnershipQueue);
		if not Major:IsDescendantOf(Players) then
			self:SetRootOwner(self.Parent.player);
			self._OwnershipQueue = {};
			return;
		end;

		self:SetRootOwner(Major);
	end;
end;

--[[
	Fetch root part CFrame from client if the entity is a player, if client does not respond within 1 second it defaults to the currently replicated CFrame
	If the entity isn't a player it also defaults to the CFrame on the server
]]
function Characters:GetRootCFrame(MagnitudeTolerance: number?)
	if not self.Parent.player then
		return self.Root.CFrame;
	end;

	local Returning;
	if self.Parent.player then
		local Fetched = Network:post('Fetch',self.Parent.player , {Fetching='RootCFrame'}, 1);
		if Fetched then
			assert(typeof(Fetched) == 'CFrame', 'Returned value was not a CFrame! Possibly manipulated by the client');
			if (Fetched.Position - self.Root.Position).Magnitude <= (MagnitudeTolerance or 10) then
				Returning = Fetched;
			end;
		end;
	end;

	Returning = Returning or self.Root.CFrame;
	return Returning;
end;

function Characters:DragPosition()
	if not self.Parent.player then
		return (self.Root.CFrame* CFrame.new(0,0,-6)).Position;
	end;

	local Returning;
	if self.Parent.player and self.Parent.player:IsDescendantOf(game.Players)then
		local Fetched = Network:get('Fetch',self.Parent.player, {Fetching='DragPosition'}, 1);

		if Fetched then
			assert(typeof(Fetched) == 'Vector3', 'Returned value was not a Position! Possibly manipulated by the client');
			Returning = Fetched;
		end;
	end;

	Returning = Returning or (self.Root.CFrame * CFrame.new(0,0,-6)).Position;
	return Returning;
end;


function Characters:GetPointingAt()
	if not self.Parent.player then
		return self.Root.CFrame;
	end;

	local Returning;
	if self.Parent.player then
		local Fetched = Network:get('Fetch',self.Parent.player, {Fetching='Pointing'}, 1);

		if Fetched then
			assert(typeof(Fetched) == 'CFrame', 'Returned value was not a CFrame! Possibly manipulated by the client');
			Returning = Fetched;
		end;
	end;

	Returning = Returning or self.Root.CFrame * CFrame.new(0,0,-5);
	return Returning;
end;

function Characters:GetCameraCF()
	if not self.Parent.player then
		return self.Root.CFrame;
	end;
	
	local Returning;
	if self.Parent.player then
		local Fetched = Network:get('Fetch',self.Parent.player, {Fetching='Camera'}, 1);

		if Fetched then
			assert(typeof(Fetched) == 'CFrame', 'Returned value was not a CFrame! Possibly manipulated by the client');
			Returning = Fetched;
		end;
	end
	
	Returning = Returning or self.Root.CFrame * CFrame.new(0,0,-1);
	return Returning;
end

function Characters:GetRelativeCFrame(EndPos: CFrame | Vector3 | nil, UseServerReplicated: boolean?)
	if typeof(EndPos) == 'CFrame' then
		EndPos = EndPos.Position;
	elseif EndPos == nil then
		EndPos = self:GetPointingAt().Position;
	end;

	local RootCFr = (UseServerReplicated and self.Root.CFrame) or self:GetRootCFrame();
	local FacingCFr = CFrame.new(RootCFr.Position, EndPos);

	return FacingCFr;
end;

function Characters:SetWillProc(Value: boolean?)
	self:SetAttribute("WillProc", Value);
	self.WillProc = Value
end

function Characters:SetCombatData(ValueName: string, Value: any,Duraton: number)
	self.Rig:SetAttribute(ValueName, Value);
	self.Parent.Combat.CombatData[ValueName] = Value
	if Duraton then
		task.delay(Duraton, function()
			self.Rig:SetAttribute(ValueName, nil);
			self.Parent.Combat.CombatData[ValueName] = nil
		end)
	end
end

function Characters:SetAttribute(AttributeName: string, Value: any)
	if not self.Rig or not self.Rig.Parent then return end
	self.Rig:SetAttribute(AttributeName, Value);
end;

function Characters:GetAttribute(AttributeName: string)
	if not self.Rig or not self.Rig.Parent then return nil end
	return self.Rig:GetAttribute(AttributeName);
end;

function Characters:BindToSpawn(Callback: () -> ())
	local _Signal = Signal.new();

	if self.Alive then
		task.spawn(Callback);
	end;
	self.Spawned.Event:Connect(Callback);

	return _Signal;
end;

function Characters:BindSpawnProtection()
	self.SpawnProtection = true;
	self.Rig:SetAttribute('SpawnProtection', true);

	local IFrame = self.Parent.Combat:AddIFrame();
	local OldTick = tick();

	repeat
		task.wait(.1);
	until tick()-OldTick >= Characters.Default.ProtectionDuration or not self.SpawnProtection;

	IFrame.Remove();
	self.SpawnProtection = false;
	self.Rig:SetAttribute('SpawnProtection', nil);
end;

function Characters:Respawn()
	self.RespawnEvent:Fire();
end;

function Characters:SetEvasive(Bool: boolean?)
	if Bool then
		table.insert(self._EvasiveQueue, true);
	else
		table.remove(self._EvasiveQueue, 1);
	end;

	if #self._AnchorQueue == 0 then
		self.Rig:SetAttribute('CanEvade', false);
	else
		self.Rig:SetAttribute('CanEvade', true);
	end;
end;

function Characters:SetMassless(Bool: boolean)
	self._Massless = Bool;
	
	local PartTable = {"Head","HumanoidRootPart","Torso","Left Leg", "Left Arm","Right Leg","Right Arm"}
	
	for i = 1,#PartTable  do
		local Part = self.Rig[PartTable[i]]
		Part.Massless = self._Massless
	end
end

function Characters:SetCollision(Bool: boolean)
	self._CanCollide = Bool;
	task.spawn(function()
		self.HitboxPart.CanCollide = Bool;
		for _,Part: BasePart in self._Colliders do
			Part.CollisionGroup = (Bool and 'Characters') or 'Nothing';
		end;
	end);
end;

function Characters:ChangeCollision(CollisionName)
	task.spawn(function()
		for _,Part: BasePart in self._Colliders do
			Part.CollisionGroup = CollisionName;
		end;
	end);
end;

function Characters:ChangeHealth(New: number, NoDeath: boolean?)
	if not self.Alive then return end;
	local PreviousHealth = self.Health;

	self.Health = math.clamp(New,0,self.MaxHealth);
	self.Humanoid.Health = self.Health;
	
	if self.Parent.player then
		self.Parent.player.StatFolder.UserFolder:SetAttribute("Health",self.Health/100)
	end

	if not NoDeath and self.Health <= 0 then
		self:OnDeath();
	end;

	self.HealthChanged:Fire(PreviousHealth, self.Health);
end;

function Characters:TakeDamage(Amount: number)
	--[[
	self.Parent.VFX:Fire({
		Module = "BasicEffect",
		SubModule = "CombatBasics",}
	,"HitHighlight", {})
]]
	self.Parent.StatManager:ChangeHealth(self.Parent.StatManager.Health - Amount);
end;

function Characters:Destroy()
	if self.Rig then
		self.Rig:Destroy();
		self.Rig = nil;
	end;

	self.Died:Destroy();
	self.Spawned:Destroy();
	self.HealthChanged:Destroy();
end;

return Characters

