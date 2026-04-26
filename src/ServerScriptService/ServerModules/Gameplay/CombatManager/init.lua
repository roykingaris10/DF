local Server = require(script.Parent)

local Network = Server.Network
local Util = Server.Utilities
local LibraryInfo = Server.LibraryInfo

local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local TweenService = game:GetService('TweenService');

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local AirCombat = require(script.AirCombat)(Server)

local GameSettings = require(Nodes.Data.GameSettings)
local Auxiliary = require(Nodes.Utility.Auxiliary);
local TroveFactory = require(Nodes.Utility.Trove);
local SoundHandler = require(Nodes.Utility.SoundHandler);
local CombatUtility = require(Nodes.Gameplay.CombatUtility);
--local SharedFunctions = require(Nodes.Utility.Functions)
local Maid = require(Nodes.Utility.Maid)
local SharedFunctions = require(Nodes.Effects.Functions)
local UptiltSettings = require(script.UptiltSettings)
--local EnvironmentService = require(Nodes.Gameplay.EnvironmentService);

--//Module
local CombatManager = {};
CombatManager.__index = CombatManager;
CombatManager.activeClashers = {} --{ [player/npc] = { move, timestamp, CFrame } }

CombatManager.new = function(Entity: {any})
	local self = setmetatable({

		Parent = Entity;	
		_Trove = TroveFactory.new();
		Maid = Maid.new();

		Cancellables = {};
		IFrames = {};
		MobilityQueue = {};

		_HitReactionList = Auxiliary.Shared.RandomList.new({1,2,3,4,5});
		_BlockReactionList = Auxiliary.Shared.RandomList.new({1,2,3});

		IFrame = false;
		InCombat = false;
		
		CombatData = {};
		
		HeavyTime = nil;

		UptiltData = {
			Maid = Maid.new();
			IsAirborne = false,
			InCombo = true,

			-- Combo tracking
			ComboCount = 0,
			LastHitTime = 0,
			CurrentAttacker = nil,

			-- Physics data
			InitialPosition = nil,
			Velocity = Vector3.new(0, 0, 0),
			Phase = "Grounded", -- "UptiltRising", "UptiltPeak", "UptiltFalling", "JuggleRising", "JuggleFalling", "Grounded"

			-- Timers
			PhaseStartTime = 0,
			LastUpdateTime = tick(),

			-- Direction tracking
			LaunchDirection = nil,

			-- BodyPosition for physics control
			BodyPosition = nil,
			BodyGyro = nil,

			-- Heartbeat connection for this specific character
			HeartbeatConnection = nil,
		};

		Detectable = true;

	}, CombatManager);

	return self;
end;

local function GetLowestValue(Ind: number, Tab: {any})
	if Auxiliary.Shared.Count(Tab) == 0 then
		return;
	end;

	local Lowest;
	for _,v in Tab do
		if not v[Ind] then continue end;
		if not Lowest then
			Lowest = v[Ind];
			continue;
		end;
		if v[Ind] < Lowest then
			Lowest = v[Ind];
		end;
	end;

	return Lowest;
end;

function CombatManager:UpdateCombatStatus()
	local LastTick = self.LastCombatTick;
	if not LastTick then
		self.InCombat = false;
		return;
	end;

	self.InCombat = (tick()-self.LastCombatTick) < GameSettings.InCombatDuration;
end;

function CombatManager:AddCombatStatus()
	self.LastCombatTick = tick();
	self:UpdateCombatStatus();

	task.delay(GameSettings.InCombatDuration, function()
		self:UpdateCombatStatus();
	end);
end;

function CombatManager:Afflict(...)
	local Args = {...};
	local TargetEntity = ((Args[1]._Class == 'Entity' and Args[1]) or self.Parent);
	local IsSelf = TargetEntity == self.Parent;
	local Params = (IsSelf and Args[1]) or Args[2];

	if not Params.ExcludeAttempts then
		if not Params.IgnoreIFrame and TargetEntity.Combat.IFrame then return end;
		
		if not Params.IgnoreParry and TargetEntity.Server.Parrying then
			local DamageData;
			if Params.Actions.Damage then
				DamageData = Params.Actions.Damage
			end
			self:Parried(TargetEntity,DamageData)
			return
		end

		task.spawn(function()
			self:AddCombatStatus();
			if not IsSelf then
				TargetEntity.Combat:AddCombatStatus();	
			end;
		end);
		
		local DamageData;
		if Params.Actions.Damage then
			DamageData = Params.Actions.Damage
		end

		local CancelLevel = Params.CancelLevel or 1;
		if self:CheckBlock(TargetEntity, CancelLevel, Params.FullBlock, Params.HitOrigin,DamageData) then
			return;
		end;

		if CancelLevel > 0 then
			TargetEntity.Combat:AttemptCancel(CancelLevel, self.Parent);
		end;

		if Params.HitVFX and not IsSelf then
			local IsTable = typeof(Params.HitVFX) == 'table';

			local Passing = {
				Victim = TargetEntity.VFX:GetClientEntity();
			};

			if IsTable then
				for i,v in Params.HitVFX.Data do
					Passing[i] = v;
				end;
			end;
			
			if Params.HitVFX.Data.Type == "Light" then
				local EffectData = {
					EffectModule = Kits.Nodes.EffectsModules.Shared.M1s;
					Func = "Hits";
				}
				self.Parent.VFX:FireAll(EffectData,{Params.HitVFX.Data.HitOrder})
				
			elseif Params.HitVFX.Data.Type == "Aerial" then
				
			elseif Params.HitVFX.Data.Type == "Critical" then
				local EffectData = {
					EffectModule = Kits.Nodes.EffectsModules.Shared.Criticals;
					Func = "Hits";
				}
				self.Parent.VFX:FireAll(EffectData,{})
			elseif Params.HitVFX.Data.Type == "AirJuggle" then
				local EffectData = {
					EffectModule = Kits.Nodes.EffectsModules.Shared.M1s;
					Func = "AirHits";
				}
				self.Parent.VFX:FireAll(EffectData,{Params.HitVFX.Data.HitOrder})
			elseif Params.HitVFX.Data.Type == "Weapon" then
				self.Parent.VFX:Fire({
					Module = "BasicEffect",
					SubModule = "CombatBasics",}
				,"WeaponHit", Passing)
			elseif Params.HitVFX.Data.Type == "Fighting Style" then
				self.Parent.VFX:Fire({
					Module = "BasicEffect",
					SubModule = "CombatBasics",}
				,"MeleeHit", Passing)
			end
			--[[
				if not self.Parent.Character.Awakened then
					self.Parent.VFX:Fire('General/Hit', (IsTable and Params.HitVFX.Name) or Params.HitVFX, Passing, 85);
				else
					self.Parent.VFX:Fire(tostring(self.Parent.Character.Root.Parent:GetAttribute('PlayingCharacter'))..'/Hit', 'AwakenedHits', Passing);
				end
				
				if tostring(self.Parent.Character.Root.Parent:GetAttribute('PlayingCharacter')) == "Aki" then
					self.Parent.VFX:Fire(tostring(self.Parent.Character.Root.Parent:GetAttribute('PlayingCharacter'))..'/Hit', 'LightHits', Passing);
				end
			]]

		end;
	end;

	local AfflictionTypes = {
		Damage = function(Data)
			if not IsSelf then
				TargetEntity.Combat.LastHit = self.Parent;
			end;
			
			TargetEntity.Character.Rig:SetAttribute('_LastHit', tick());
			TargetEntity.Character:TakeDamage(Data.Amount);
			--[[
			if not IsSelf and not self.Parent.Character.Awakened then
				self.Parent.Character:IncrementAwakening(Data.Amount*10);
			end;
			]]

			if Data.HitReaction then
				if TargetEntity.Character.Buffed then return end;

				local HitAnim: AnimationTrack;
				if typeof(Data.HitReaction) == 'boolean' then
					HitAnim = TargetEntity.Animator:Fetch('General/HitReactions/'..self._HitReactionList:Roll());
				else
					HitAnim = TargetEntity.Animator:Fetch('General/HitReactions/'..tostring(Data.HitReaction));
				end;
				HitAnim:Play();
			end;

			task.delay(0.25, function()
				TargetEntity.Character.Rig:SetAttribute('_LastHit', nil)
			end)
			--	self.Parent.StatManager:ChangeBlackFlash("Add",Data.Amount*5)
			self.Parent.StatManager:ChangeWill(Data.Amount*5)
			TargetEntity.InCombatTick = tick()
		end;
		
		HitStop = function(Data)
			assert(Data.Duration, debug.traceback('Need to pass duration when calling hitstop!'));
			assert(Data.Scale, debug.traceback('Need to pass duration when calling hitstop!'));
			
			TargetEntity.RunTime:SetModifier("Base", Data.Scale)
			task.delay(Data.Duration, function()
				TargetEntity.RunTime:SetModifier("Base", 1)
			end)
			
			if Data.Shake then
				local duration      = Data.Shake.Duration      or 0.12   -- real seconds to shake
				local posAmplitude  = Data.Shake.PosAmplitude  or 2.25   -- max stud offset
				local rotAmplitude  = Data.Shake.RotAmplitude  or 10      -- max degree offset
				local frequency     = Data.Shake.Frequency     or 26     -- oscillations per second
				local fadeOut       = Data.Shake.FadeOut       ~= false  -- true by default: shake weakens over time
				local axes          = Data.Shake.Axes          or {      -- which axes to shake
					posX = true,
					posY = true,
					posZ = false,  -- Z shake looks weird for most hits, off by default
					rotX = true,
					rotY = true,
					rotZ = false,
				}
				local RootJoint = TargetEntity.Character.Root.RootJoint
				local originalC0 = RootJoint.C0

				local startTime = os.clock()
				
				TargetEntity.Character:SetAttribute("HitShake",true)
				local connection
				connection = RunService.Heartbeat:Connect(function()

					local realElapsed = os.clock() - startTime

					if realElapsed >= duration then
						RootJoint.C0 = originalC0
						TargetEntity.Character:SetAttribute("HitShake",false)
						connection:Disconnect()
						return
					end

					local alpha = realElapsed / duration

					local strength
					if fadeOut then
						strength = (1 - alpha)^1.5
					else
						strength = 1
					end

					local t = realElapsed * frequency * math.pi * 2

					local offsetX = axes.posX and math.sin(t * 1.0) * posAmplitude * strength or 0
					local offsetY = axes.posY and math.sin(t * 1.3) * posAmplitude * strength or 0
					local offsetZ = axes.posZ and math.sin(t * 0.8) * posAmplitude * strength or 0

					local rotX = axes.rotX and math.sin(t * 1.1) * math.rad(rotAmplitude) * strength or 0
					local rotY = axes.rotY and math.sin(t * 0.9) * math.rad(rotAmplitude) * strength or 0
					local rotZ = axes.rotZ and math.sin(t * 1.4) * math.rad(rotAmplitude) * strength or 0

					
					RootJoint.C0 = originalC0
						* CFrame.new(offsetX, offsetY, offsetZ)
						* CFrame.Angles(rotX, rotY, rotZ)
				end)
			end
		end,

		Downslam = function(Data)
			self:Downslam(TargetEntity, Data);
		end;

		Uptilt = function(Data)
			self:Uptilt(TargetEntity,Data);
		end,

		Knockback = function(Data)
			self:Knockback(TargetEntity, Data);
		end;

		UpKnockback = function(Data)
			self:UpKnockback(TargetEntity, Data);
		end;

		Push = function(Data)
			self:Push(TargetEntity, Data);
		end;

		Stun = function(Data)
			assert(Data.Duration, debug.traceback('Need to pass duration when calling stun!'));
			warn("STUNNED")
			
			Data.Disabling = true;
			TargetEntity.Character:SetStunned(true)
			local Tags = {}
			Util.TagAdd(Tags, TargetEntity.Character.Rig, "Stunned")
			TargetEntity.StatManager:SetAbsolute(Data.Name, {
				WalkSpeed = Data.Speed,
				JumpPower = Data.Jump,
				Priority = 5
			})
			task.delay(Data.Duration,function()
				Util.ClearTable(Tags)
				TargetEntity.Character:SetStunned(false)
				TargetEntity.StatManager:RemoveAbsolute(Data.Name)
			end)
	--		TargetEntity.Combat:ChangeMobility(Data);
	
			if Data.Callback then
				Data.Callback()
			end
		end;

		Ragdoll = function(Duration)
			TargetEntity.Character:Ragdoll(Duration);
			TargetEntity.Character:AssignOwnership(self.Parent.player);
			task.delay(Duration, function()
				TargetEntity.Character:AssignOwnership(false);
			end);
		end;

		BreakJoints = function()
			TargetEntity.Character:Ragdoll(true);
			TargetEntity.Character:AssignOwnership(self.Parent.player);
			task.wait(.1);
			TargetEntity.Character:BreakJoints();
		end;

		Killing = function()
			TargetEntity.Character:Kill();
		end;
	};

	if Params.Actions then
		local DamageData = Params.Actions.Damage;
		if DamageData then
			AfflictionTypes.Damage(DamageData);
		end;

		for ActionName: string, ActionData in Params.Actions do
			if ActionName == 'Damage' then continue end;
			task.spawn(AfflictionTypes[ActionName], ActionData);
		end;
	end;
	
	return true;
end;

function CombatManager:CreateCancel(Level: number?, Callback: () -> ()?)
	local CancelObject = {
		Level = Level or 1;
		Callback = Callback or (function() end);
		Cancelled = false;
	};
	self.Cancellables[CancelObject] = true;

	function CancelObject.Remove()
		self.Cancellables[CancelObject] = nil;
	end;

	if RunService:IsStudio() then
		task.delay(10, function()
			if not self.Cancellables[CancelObject] then return end;
			debug.traceback('\n*\n		Cancel instance has existed for a significant amount of time, did you forget to remove it?\n*');
		end);
	end;

	return CancelObject;
end;

function CombatManager:AttemptCancel(Level: number, HitEntity: {any})
	for v in self.Cancellables do
		if v.Level <= Level then
			v.Cancelled = true;			
			--task.spawn(v.Callback());
			task.spawn(function() v.Callback(HitEntity) end)
			v.Remove();
		end;
	end;
end;

function CombatManager:Parried(TargetEntity: {any}, Data: {any})
	local ParryNum = math.random(1,#Kits.Animations.Weapons.Fists.ParriedReactions:GetChildren())
	local ParriedAnim: AnimationTrack = self.Parent.Animator:Fetch('Weapons/Fists/ParriedReactions/Parried'..ParryNum);
	ParriedAnim:Play();
	
	local EffectData = {
		EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
		Func = "ParryFX";
	}
	TargetEntity.VFX:FireAll(EffectData,{})
	
	local StartPos = self.Parent.Character.Root.Position;
	local EndPos = TargetEntity.Character.Root.Position;

	local Sub = (StartPos - EndPos);
	local Dist = Sub.Magnitude;
	local Unit = -Sub.Unit;
	TargetEntity.Combat:Afflict(self.Parent,{
		CancelLevel = 1;
		IgnoreParry = true;
	--	ExcludeAttempts = true;
		Actions = {
			Knockback = {
				Velocity = Unit*1.5;
				Duration = .05;
			};
			Stun = {
				Name = "Parry",
				Duration = ParriedAnim.Length,
			}
		};	
	});
	
	self.Parent.StatManager:SetAbsolute("Parried", {
		WalkSpeed = 5,
		JumpPower = 0,
		Priority = 6
	})
	
	task.delay(ParriedAnim.Length,function()
		self.Parent.StatManager:RemoveAbsolute("Parried")
	end)

	return true
end

function CombatManager:WillFinish(Damage: number)
	return self.Parent.Character.Health - Damage <= 0;
end;

function CombatManager:Push(TargetEntity: {any}, Data: {any})
	if TargetEntity.Character.Buffed then return end;
	
--	local PushTags = {}

	local OriginCFr: CFrame = Data.Origin or self.Parent.Character.Root.CFrame;
	local PushDuration = Data.Duration or .9;

	if not TargetEntity.Character.Alive then
		self:Knockback(TargetEntity, {
			Velocity = OriginCFr.LookVector * (Data.Push or 120);
			Duration = PushDuration*.15;
		});

		return;	
	end;

	local RollAnim: AnimationTrack = TargetEntity.Animator:Fetch('General/RollKnockback');
	if not TargetEntity.player then
		TargetEntity.Character:AssignOwnership(TargetEntity.player or self.Parent.player);
	end;

	local BasePushDuration = RollAnim.Length;

	self:Knockback(TargetEntity, {
		Velocity = OriginCFr.LookVector * (Data.Push or 120);
		Duration = PushDuration*.7;
		Ease=true;
		MaxForce = Vector3.new(1e7, 0, 1e7);
	});

	local InitPos = OriginCFr.Position;
	local FacingCFr = CFrame.new(TargetEntity.Character.Root.Position, InitPos);

	TargetEntity.Character.Humanoid.AutoRotate = false;
	TargetEntity.Character.Root.CFrame = FacingCFr;

	if TargetEntity.Character.Ragdolled then
		TargetEntity.Character:Ragdoll(false, true);
		TargetEntity.Character.Root.CFrame += Vector3.yAxis*1.5;
	end;

	TargetEntity.Character.Rig:SetAttribute('Rolling', true);
--	TargetEntity.VFX:Fire('General/Hit', 'Roll', {Facing = FacingCFr, RollDuration = PushDuration, FullVFX = Data.FullVFX});

	local AnimSpeed = BasePushDuration/PushDuration;
	RollAnim:Play(nil, nil, AnimSpeed);

	local NewCancel = TargetEntity.Combat:CreateCancel();

--	Util.TagAdd(PushTags, self.Parent.Character.Rig, "RollKnockback")
	
	local Gyro: BodyGyro = Auxiliary.Shared.CreateGyro(TargetEntity.Character.Root);
	Gyro.P = 10_000;
	Gyro.CFrame = FacingCFr;

	local OldTick = tick();
	repeat 
		Gyro.CFrame = CFrame.new(TargetEntity.Character.Root.Position, InitPos);
		RunService.Heartbeat:Wait();
	until NewCancel.Cancelled or tick()-OldTick >= PushDuration;
	TargetEntity.Character.Rig:SetAttribute('Rolling', false);
	Gyro:Destroy();

	if not TargetEntity.player then
		TargetEntity.Character:AssignOwnership(false);
	end;

	local function EndedEvent()
	--	task.wait(.35);
		NewCancel.Remove();
	--	Util.ClearTable(PushTags)
		TargetEntity.Character.Humanoid.AutoRotate = true;
	end;

	if NewCancel.Cancelled then
		RollAnim:Stop(.02);
	end;

	if RollAnim.IsPlaying then
		RollAnim.Stopped:Once(EndedEvent);
	else
		task.spawn(EndedEvent);
	end;
end

function CombatManager:Downslam(TargetEntity: {any}, Data: {any})
	if TargetEntity ~= self and TargetEntity.Character.Buffed then return end;
	if Data.ClientSided and TargetEntity.player then
--[[	Network:Send('Combat', {
			Effect='Knockback';
			Data=Data;
			Caster = self.Parent.Character.Rig;
		}, false, TargetEntity.player);]]	
		Network:post("ClientWork",TargetEntity.player,"RemoveAllBodyForces",TargetEntity.Character)
		--		Network:post("ClientWork",TargetEntity.player,"BVPlacer",TargetEntity.Character,infoTable)
	else
		TargetEntity.Character:AssignOwnership(self.Parent.player);
		CombatUtility:RemoveAllBodyForces(TargetEntity.Character.Root)
		local DownSlamCheck = CombatUtility:DownSlam(TargetEntity.Character.Rig,self.Parent.Character.Root.CFrame,Data.Type,Data.DampenDuration)
		if DownSlamCheck then

			task.spawn(function()
				local origin = TargetEntity.Character.Root.Position 
				local dir =  Vector3.new(0, -5, 0) 
				local blacklistparams = {workspace.Map}

				local BackRay = SharedFunctions.RayHit:StartI(origin,dir,blacklistparams)
				if BackRay then
					self.Parent.VFX:Fire({
						Module = "BasicEffect",
						SubModule = "CombatBasics",}
					,"Downslam", {Victim = TargetEntity})
					--put VFX HERE
				end
			end)
			TargetEntity.Character:AssignOwnership(false);
		else
			TargetEntity.Character:AssignOwnership(false);
		end
	end;
end;

function CombatManager:Knockback(TargetEntity: {any}, Data: {any})
	if TargetEntity ~= self and TargetEntity.Character.Buffed then return end;
	if Data.ClientSided and TargetEntity.player then
--[[	Network:Send('Combat', {
			Effect='Knockback';
			Data=Data;
			Caster = self.Parent.Character.Rig;
		}, false, TargetEntity.player);]]	
		Network:post("ClientWork",TargetEntity.player,"RemoveAllBodyForces",TargetEntity.Character)
		--Network:post("ClientWork",TargetEntity.player,"BVPlacer",TargetEntity.Character,infoTable)
	else
		local TrueVelocity = Data.Velocity or ((Data.Origin or self.Parent.Character.Root.CFrame).LookVector * Data.Push);
		--	TargetEntity.Character:AssignOwnership(self.Parent.player);

		local infoTable = {
			MaxForce = Data.MaxForce or Vector3.new(5e7,5e7,5e7),
			Velocity = TrueVelocity,
		--	Duration = Data.Duration,
		}
		
		CombatUtility:RemoveAllBodyForces(TargetEntity.Character.Root)
		local BV = CombatUtility:BVPlacer(TargetEntity.Character.Root,infoTable)
		
		
		TargetEntity.RunTime.BodyMovers["KnockbackVelo"] = {
			Instance        = BV,
			Velocity        = TrueVelocity,
			Duration        = Data.Duration,
	--		Ease            = true,
			EaseStyle       = "Sine",
			ScaleOffRunTime = true,
	--		AntiGravity     = true,
			Character       = TargetEntity.Character,
			OnComplete      = function()
				-- BV:Destroy()
			end,
		}
		--[[
		if Data.Ease then
			TweenService:Create(BV, TweenInfo.new(Data.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Velocity = Vector3.zero}):Play();
		end;
		]]
		task.spawn(function()
			TargetEntity.RunTime:Wait(Data.Duration or 0.1)
			BV:Destroy()
			--BV:Destroy();
			--TargetEntity.Character:AssignOwnership(false);
		end);
	end;
end;

function CombatManager:UpKnockback(TargetEntity: {any}, Data: {any})
	if TargetEntity ~= self and TargetEntity.Character.Buffed then return end;

	if Data.ClientSided and TargetEntity.player then
--[[	Network:Send('Combat', {
			Effect='Knockback';
			Data=Data;
			Caster = self.Parent.Character.Rig;
		}, false, TargetEntity.player);]]	

		Network:post("ClientWork",TargetEntity.player,"RemoveAllBodyForces",TargetEntity.Character)
		--	Network:post("ClientWork",TargetEntity.player,"BVPlacer",TargetEntity.Character,infoTable)
	else
		local TrueVelocity = Data.Velocity or ((Data.Origin or self.Parent.Character.Root.CFrame).UpVector * Data.Push);
		TargetEntity.Character:AssignOwnership(self.Parent.player);

		local infoTable = {
			MaxForce = Vector3.new(5e7,5e7,5e7),
			Velocity = TrueVelocity,
			Duration = Data.Duration,
		}
		--[[
		if Data.AngularVelocity then
			TargetEntity.Character.Root.AssemblyAngularVelocity += Data.AngularVelocity;
		end;

		local BV: BodyVelocity = Auxiliary.Shared.CreateVelocity(TargetEntity.Character.Root);		
		BV.Velocity = TrueVelocity;

		if Data.MaxForce then
			BV.MaxForce = Data.MaxForce;
		end;

		if Data.Ease then
			TweenService:Create(BV, TweenInfo.new(Data.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Velocity = Vector3.zero}):Play();
		end;]]
		CombatUtility:RemoveAllBodyForces(TargetEntity.Character.Root)
		CombatUtility:BVPlacer(TargetEntity.Character.Root,infoTable)
		task.delay(Data.Duration, function()
			--		BV:Destroy();
			TargetEntity.Character:AssignOwnership(false);
		end);
	end;
end;

function CombatManager:Uptilt(TargetEntity: {any}, Data: {any})
	AirCombat:Uptilt(self.Parent, TargetEntity, Data)
end

function CombatManager:AirStartCritical(TargetEntity: {any})
	AirCombat:AirStartCritical(self.Parent, TargetEntity)
end

function CombatManager:AirLightHit(TargetEntity: {any}, HitIdentity: {any})
	AirCombat:AirLightHit(self.Parent, TargetEntity, HitIdentity)
end

function CombatManager:AirJuggle(TargetEntity: {any}, Phase: {any})
	AirCombat:AirJuggle(self.Parent, TargetEntity, Phase)
end

function CombatManager:ApplyAirHit(TargetEntity, Phase)
	local state = TargetEntity.Combat.UptiltData;

	if not state.IsAirborne then
		warn("Cannot apply air hit: Victim not in air combat state");
		return false;
	end;
--[[
	-- Check if combo window expired
	local timeSinceLastHit = tick() - state.LastHitTime;
	if timeSinceLastHit > UptiltSettings.JuggleHit.ComboWindow then
		warn("Combo window expired");
		return false;
	end;

	-- Check combo limit
	if state.ComboCount >= UptiltSettings.JuggleHit.MaxComboCount then
		TargetEntity.Combat:EndAirCombo("Downslam");
		return false;
	end;
]]
	-- Check if this is the first air hit (establishes combo direction)
	local isFirstAirHit = state.ComboCount == 0;

	if Phase == "Engage" then
	
		self.Parent.Character:SetAttribute("AirComboOption",true)

		task.delay(0.25,function()
			repeat task.wait() until self.Parent.Character.Rig == nil or self.Parent.Character.Humanoid:GetState() == Enum.HumanoidStateType.Landed or self.Parent.Character.Humanoid.FloorMaterial ~= Enum.Material.Air
			self.Parent.Character:SetAttribute("AirComboOption",nil)
		--	self.Parent.Character.Humanoid.AutoRotate = true
		end)

		local direction = (self.Parent.Character.Root.Position - TargetEntity.Character.Root.Position).Unit
		local distance = 5 -- studs away from target

		local AirPos = TargetEntity.Character.Root.Position + (direction * distance)
		AirPos = Vector3.new(AirPos.X, TargetEntity.Character.Root.Position.Y, AirPos.Z)
		local GyroTarget = CFrame.new(TargetEntity.Character.Root.Position.X,self.Parent.Character.Root.Position.Y,TargetEntity.Character.Root.Position.Z)
		
		local VictimPos = TargetEntity.Character.Root.Position
		local GyroVictim = CFrame.new(self.Parent.Character.Root.Position.X,TargetEntity.Character.Root.Position.Y,self.Parent.Character.Root.Position.Z)
		
		TargetEntity.Combat:EndUptiltPhysics()
		
	--	TargetEntity.Character.Humanoid.AutoRotate = false
	--	self.Parent.Character.Humanoid.AutoRotate = false
		
		CombatUtility:RemoveAllBodyForces(TargetEntity.Character.Root)
		CombatUtility:BPPlacer(TargetEntity.Character.Root,{
			Name = "AirUp",
			MaxForce = Vector3.new(1e9,1e9,1e9),
			Position = VictimPos,
			P = 11000,
			D = 700,
			Duration = 1.25,
		})
		CombatUtility:BGPlacer(TargetEntity.Character.Root,{
			Name = "AirFace",
			MaxForce = Vector3.new(1e8,1e8,1e8),
			CFrame = CFrame.new(VictimPos,AirPos),
			P = 8000,
			Duration = 1.25,
		})
		
		if self.Parent.player then
			Network:post("ClientEvent",self.Parent.player,"RemoveAllBodyForces",self.Parent.Character.Root)
			Network:post("ClientEvent",self.Parent.player,"BPPlacer",self.Parent.Character.Root,{
				Name = "AirUp",
				MaxForce = Vector3.new(1e9,1e9,1e9),
				Position = AirPos,
				P = 11000,
				D = 700,
				Duration = 1.25,
			})
			Network:post("ClientEvent",self.Parent.player,"BGPlacer",self.Parent.Character.Root,{
				Name = "AirFace",
				MaxForce = Vector3.new(1e8,1e8,1e8),
				CFrame = CFrame.new(AirPos,VictimPos),
				P = 8000,
				Duration = 1.25,
			})
		end
		--[[
		-- Apply stronger knockback on first hit
		local upBoost = UptiltSettings.JuggleHit.UpwardBoost * UptiltSettings.JuggleHit.FirstHitRedirectBonus;
		local horizontalKnockback = UptiltSettings.JuggleHit.HorizontalKnockback * UptiltSettings.JuggleHit.FirstHitRedirectBonus;

		state.Velocity = Vector3.new(0, upBoost, 0) + (comboDirection * horizontalKnockback);

		print("First Hit Velocity:", state.Velocity);]]
	elseif Phase == "LightAttack" then
		
		local lookVector = self.Parent.Character.Root.CFrame.LookVector
		local flatDirection = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
		
		local AirPos = self.Parent.Character.Root.Position + (flatDirection * 5)
		local VictimPos = self.Parent.Character.Root.Position + (flatDirection * 9)
		
	--	TargetEntity.Character.Humanoid.AutoRotate = false
	--	self.Parent.Character.Humanoid.AutoRotate = false

		CombatUtility:RemoveAllBodyForces(TargetEntity.Character.Root)
		CombatUtility:BPPlacer(TargetEntity.Character.Root,{
			Name = "AirUp",
			MaxForce = Vector3.new(0,1e9,0),
			Position = VictimPos,
			P = 11000,
			D = 700,
			Duration = 1,
		})
		CombatUtility:BGPlacer(TargetEntity.Character.Root,{
			Name = "AirFace",
			MaxForce = Vector3.new(1e8,1e8,1e8),
			CFrame = CFrame.new(VictimPos,AirPos),
			P = 8000,
			Duration = 1,
		})

		if self.Parent.player then
			Network:post("ClientEvent",self.Parent.player,"RemoveAllBodyForces",self.Parent.Character.Root)
			Network:post("ClientEvent",self.Parent.player,"BPPlacer",self.Parent.Character.Root,{
				Name = "AirUp",
				MaxForce = Vector3.new(0,1e9,0),
				Position = AirPos,
				P = 11000,
				D = 700,
				Duration = 1.25,
			})
			Network:post("ClientEvent",self.Parent.player,"BGPlacer",self.Parent.Character.Root,{
				Name = "AirFace",
				MaxForce = Vector3.new(1e8,1e8,1e8),
				CFrame = CFrame.new(AirPos,VictimPos),
				P = 8000,
				Duration = 1.25,
			})
		end
		
	elseif Phase == "Downslam" then
		CombatUtility:RemoveAllBodyForces(TargetEntity.Character.Root)
		local DownSlamReaction = TargetEntity.Animator:Fetch(`General/DownslamVictim`);
		DownSlamReaction:Play(0.05);
		local DownSlamCheck = CombatUtility:DownSlam(TargetEntity.Character.Rig,self.Parent.Character.Root.CFrame)
		if DownSlamCheck then

			task.spawn(function()
				task.wait()
				local origin = TargetEntity.Character.Root.Position 
				local dir =  Vector3.new(0, -4.5, 0)

				local BackRay = workspace:Raycast(origin, dir, Auxiliary.Shared.RayParams.Map)
				if BackRay then
					--[[
					Network:postAll(
						"EffectsClient",
						{Sort = "BasicEffect",Module = "CombatBasics"},
						{Origin = TargetEntity.Character.Root.Position,Range = 400},
						"DownSlamFX",enemy,BackRay.Instance.Color,BackRay.Material
					)]]
					
					local EffectData = {
						EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
						Func = "DownslamFX";
					}
					self.Parent.VFX:FireAll(EffectData,{BackRay.Position,BackRay.Instance.Color,BackRay.Material})
				end
			end)
			
		
		end
		task.wait(0.3)
		--	StunState:Destroy()
		DownSlamReaction:Stop()
	elseif Phase == "Airpush" then
		CombatUtility:RemoveAllBodyForces(TargetEntity.Character.Root)
		
		local lookVector = self.Parent.Character.Root.CFrame.LookVector
		local flatDirection = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

		local AirPos = self.Parent.Character.Root.Position + (flatDirection * 2)
		local VictimPos = self.Parent.Character.Root.Position + (flatDirection * 35 )

	--	TargetEntity.Character.Humanoid.AutoRotate = false
	--	self.Parent.Character.Humanoid.AutoRotate = false
		
		self.Parent.Character:SetAttribute("FlickerRushOption",true)
		
		local FlickerRushValue = Instance.new("ObjectValue")
		FlickerRushValue.Name = "FlickerRushTarget"
		FlickerRushValue.Parent = self.Parent.Character.Rig
		FlickerRushValue.Value = TargetEntity.Character.Rig
		Server.Debris:AddItem(FlickerRushValue,1.4)

		CombatUtility:RemoveAllBodyForces(TargetEntity.Character.Root)
		CombatUtility:BPPlacer(TargetEntity.Character.Root,{
			Name = "AirUp",
			MaxForce = Vector3.new(1e9,1e9,1e9),
			Position = VictimPos,
			P = 13000,
			D = 900,
			Duration = 1.8,
		})
		CombatUtility:BGPlacer(TargetEntity.Character.Root,{
			Name = "AirFace",
			MaxForce = Vector3.new(1e8,1e8,1e8),
			CFrame = CFrame.new(VictimPos,AirPos),
			P = 8000,
			Duration = 1.8,
		})

		if self.Parent.player then
			Network:post("ClientEvent",self.Parent.player,"RemoveAllBodyForces",self.Parent.Character.Root)
			Network:post("ClientEvent",self.Parent.player,"BPPlacer",self.Parent.Character.Root,{
				Name = "AirUp",
				MaxForce = Vector3.new(0,1e9,0),
				Position = AirPos,
				P = 11000,
				D = 700,
				Duration = 1.25,
			})
			Network:post("ClientEvent",self.Parent.player,"BGPlacer",self.Parent.Character.Root,{
				Name = "AirFace",
				MaxForce = Vector3.new(1e8,1e8,1e8),
				CFrame = CFrame.new(AirPos,VictimPos),
				P = 8000,
				Duration = 1.25,
			})
		end
		
		task.delay(0.275,function()
			repeat task.wait() until self.Parent.Character.Rig == nil or self.Parent.Character.Humanoid:GetState() == Enum.HumanoidStateType.Landed or self.Parent.Character.Humanoid.FloorMaterial ~= Enum.Material.Air or not TargetEntity.Character:GetAttribute("Uptilted")
			self.Parent.Character:SetAttribute("FlickerRushOption",false)
			if FlickerRushValue.Parent then
				FlickerRushValue:Destroy()
			end
		end)
	end;

	-- Update state
	state.ComboCount = state.ComboCount + 1;
	state.LastHitTime = tick();
	state.CurrentAttacker = self.Parent.Character.Rig;
--	state.Phase = "JuggleRising";
	state.PhaseStartTime = tick();

	return true;
end;

local BlockBreakStun = 2
function CombatManager:CheckBlock(TargetEntity: {any}, CancelLevel: number, FullBlock: boolean?, HitOrigin: Vector3,DamageData: {any})
	if not TargetEntity.Server.Blocking then return end;
	local RootCFr: CFrame = TargetEntity.Character.Root.CFrame;
	local Sub: Vector3 = (HitOrigin or self.Parent.Character.Root.Position) - RootCFr.Position;

	local Angle = math.acos(RootCFr.LookVector:Dot(Sub.Unit));

	if CancelLevel > 1 or (not FullBlock and Angle >= math.rad(100)) then
		TargetEntity.Server.Blocking = false;
		return;
	end;

	TargetEntity.inCombatTick = tick()
	TargetEntity.LastPostureHit = tick()

	TargetEntity.StatManager:ChangePosture(TargetEntity.StatManager.Posture+(DamageData.Posture or 20))
	if TargetEntity.StatManager.Posture >= 100 then 
		print("Posture Broken")
		TargetEntity.StatManager:ChangePosture(0)
	--	TargetEntity.Server.Blocking = false;
		TargetEntity.StatManager:SetAbsolute("BlockBreak", {
			WalkSpeed = 3,
			JumpPower = 0,
			Priority = 6
		})
		local StartPos = self.Parent.Character.Root.Position;
		local EndPos = TargetEntity.Character.Root.Position;

		local Sub = (StartPos - EndPos);
		local Dist = Sub.Magnitude;
		local Unit = -Sub.Unit;
		self:Afflict({
			ExcludeAttempts = true;
			Actions = {
				Stun = {
					Name = "BlockBreak",
					Duration = 1.4,
				}
			};	
		});
		
		task.spawn(function()
		
			TargetEntity.RunTime:Wait(1.2)
			TargetEntity.StatManager:RemoveAbsolute("BlockBreak")
		end)
		
		local BreakReact: AnimationTrack = TargetEntity.Animator:Fetch('General/BlockBreak');
		BreakReact:Play(nil,nil);
		BreakReact:SetAttribute("Speed",0.5)
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "BlockBreak";
		}
		TargetEntity.VFX:FireAll(EffectData,{})
	
		return true;
	end
	local BlockFlinch: AnimationTrack = TargetEntity.Animator:Fetch('Weapons/Fists/BlockFlinch');
	BlockFlinch:Play();
	--[[
	local Reaction: AnimationTrack = TargetEntity.Animator:Fetch('Universal/Block/Reactions/'..self._BlockReactionList:Roll());
	Reaction:Play(nil,nil,.7);
	]]
	SoundHandler.Spawn(`Combat/MeleeBlock`, TargetEntity.Character.Root, 1, Auxiliary.Shared.Ran:NextNumber(.9,1.1));
	return true;
end;

function CombatManager:StunChange(NewMobility: {any})

end

function CombatManager:ChangeMobility(NewMobility: {any})
	local MobilityObject = {
		Valid = true;	
	};
	local QueueInput = {};

	QueueInput.Speed = NewMobility.Speed;
	QueueInput.Jump = NewMobility.Jump;
	QueueInput.Disabling = NewMobility.Disabling;

	table.insert(self.MobilityQueue, QueueInput);
	self:UpdateMobility();

	function MobilityObject.Remove()
		if not MobilityObject.Valid then return end;
		MobilityObject.Valid = false;
		table.remove(self.MobilityQueue, table.find(self.MobilityQueue, QueueInput));
		self:UpdateMobility();
	end;

	if NewMobility.Duration then
		task.delay(NewMobility.Duration, MobilityObject.Remove);
	end;

	return MobilityObject;
end;

function CombatManager:UpdateMobility()	
	local Stunning = false;
	for _,v in self.MobilityQueue do
		if v.Disabling then
			Stunning = true;
			break;
		end;
	end;
--	self.Parent.Character:SetStunned(Stunning);

	local Humanoid = self.Parent.Character.Rig and self.Parent.Character.Rig:FindFirstChildOfClass('Humanoid');
	if not Humanoid then return end;

	local NewSpeed = GetLowestValue('Speed', self.MobilityQueue);
	local NewJump = GetLowestValue('Jump', self.MobilityQueue);

	if self.Parent.player then
		Humanoid:SetAttribute('ServerSpeed', NewSpeed);
		Humanoid:SetAttribute('ServerJump', NewJump);
	else
		Humanoid.WalkSpeed, Humanoid.JumpPower = NewSpeed or GameSettings.WalkSpeed, NewJump or GameSettings.Jump;
	end;
end;

function CombatManager:AddIFrame(Duration: number?)
	local IFrameObject = {};
	self.IFrames[IFrameObject] = true;
	self:UpdateIFrameStatus();

	if Duration then
		IFrameObject.DurationRemove = task.delay(Duration, function()
			IFrameObject.DurationRemove = nil;
			IFrameObject.Remove();
		end);
	end;

	function IFrameObject.Remove()
		self.IFrames[IFrameObject] = nil;
		self:UpdateIFrameStatus();
		if IFrameObject.DurationRemove then
			task.cancel(IFrameObject.DurationRemove);
		end;
	end;

	return IFrameObject;
end;

function CombatManager:UpdateIFrameStatus()
	self.IFrame = Auxiliary.Shared.Count(self.IFrames) ~= 0;
	self.Parent.Character.Rig:SetAttribute('IFrame', self.IFrame);
end;

function CombatManager:RegisterClash(PunchInfo: {}, DetectedChars: {Object})
	self.Parent.Character:SetAttribute("Clashable",true)
	self.ClashData = {
--		Victims = DetectedChars;
		Timestamp = tick();
		Id = PunchInfo.CurrentId;
		Processed = false,
		Action = PunchInfo.AttackType;
	}
end

function CombatManager:UnregisterClash()
	self.Parent.Character:SetAttribute("Clashable",nil)
	self.ClashData = nil
end

local ClashWindow = 0.35;

local function AreFacingWithinAngle(rootCF1, rootCF2, maxAngleDeg)
	maxAngleDeg = maxAngleDeg or 45

	-- Positions
	local pos1 = rootCF1.Position
	local pos2 = rootCF2.Position

	-- Flatten Y so vertical height doesn’t affect angle
	pos1 = Vector3.new(pos1.X, 0, pos1.Z)
	pos2 = Vector3.new(pos2.X, 0, pos2.Z)

	-- Directions to each other
	local dir1 = (pos2 - pos1).Unit
	local dir2 = (pos1 - pos2).Unit

	-- Forward look vectors (flattened)
	local look1 = Vector3.new(rootCF1.LookVector.X, 0, rootCF1.LookVector.Z).Unit
	local look2 = Vector3.new(rootCF2.LookVector.X, 0, rootCF2.LookVector.Z).Unit

	-- Dot products
	local dot1 = look1:Dot(dir1)
	local dot2 = look2:Dot(dir2)

	-- Convert to angles
	local angle1 = math.deg(math.acos(math.clamp(dot1, -1, 1)))
	local angle2 = math.deg(math.acos(math.clamp(dot2, -1, 1)))

	return angle1 <= maxAngleDeg and angle2 <= maxAngleDeg
end

function CombatManager:CheckForClash(HitEntity, PunchInfo: {})
	if not self.ClashData then warn("NO CLASH DATA") return end
	if self.ClashData.Id ~= PunchInfo.CurrentId then  return end
	if self.ClashData.Processed then return end
--[[local FoundRig
	
	for i, char in self.ClashData.Victims do
		if char == HitEntity.Character.Rig then
			FoundRig = char
			break
		end
	end
	if FoundRig then]]	
		if HitEntity.Character:GetAttribute("Clashing") or self.Parent.Character:GetAttribute("Clashing") then warn("CLASHING ALREADY") return end
		if HitEntity.Character:GetAttribute("Clashable") and HitEntity.Combat.ClashData then
			print(self.ClashData.Timestamp-HitEntity.Combat.ClashData.Timestamp)
			if math.abs(self.ClashData.Timestamp-HitEntity.Combat.ClashData.Timestamp) <= ClashWindow then
				local RootCF = Util.ExtrapolateMovingCFrame(self.Parent.Character.Root)
				local EnemyRootCF = Util.ExtrapolateMovingCFrame(HitEntity.Character.Root)
				if (RootCF.Position-EnemyRootCF.Position).Magnitude > 15 then return end
				if AreFacingWithinAngle(RootCF, EnemyRootCF, 45) then
					self.ClashData.Processed = true
					self:StartClash(HitEntity, PunchInfo)
					return true
				end
			end
		end
--	end
end

function CombatManager:StartClash(TargetEntity, PunchInfo: {})
	local Target = TargetEntity.Character.Rig
	local RootPart = self.Parent.Character.Root;
	local EnemyRoot = TargetEntity.Character.Root;
	warn("STARTING CLASH")
	local ClashMaid = Maid.new()
	local ClashTags = {}
	local ClashAnimations = {}
	
	ClashMaid.OnClean = function()
		warn("CLEANING CLASH")
		self.Parent.Character.ClashMaid = nil
		Util.ClearTable(ClashTags)	
		
		for _, Animation: AnimationTrack in pairs(ClashAnimations) do
			Animation:Stop()
		end
		
		local UserPosture = self.Parent.StatManager.Posture
		local TargetPosture = TargetEntity.StatManager.Posture
		print(UserPosture)
		print(TargetPosture)

		if self.Parent.Character.Rig and self.Parent.Character.Rig.Parent then
			RootPart.Anchored = false
			self.Parent.Character:SetAttribute("Clashing",nil)
			self.Parent.Character.Humanoid.AutoRotate = true
			self.Parent.Character:SetActive(false)
			if UserPosture >= TargetPosture then
				TargetEntity.Combat:Afflict(self.Parent, {
					CancelLevel = 1;
					Actions = {
						Push = {
							Push = 52,
							Duration = 0.6,
						};
						Stun = {
							Name = "ClashStun",
							Duration = .4;
							Speed = 0;
							Jump = 0;
						};
					};
				});
			else
				print("dd")
			end
		end
		
		if TargetEntity.Character.Rig and TargetEntity.Character.Rig.Parent then
			EnemyRoot.Anchored = false
			TargetEntity.Character:SetAttribute("Clashing",nil)
			TargetEntity.Character.Humanoid.AutoRotate = true
			TargetEntity.Character:SetActive(false)
			if TargetPosture >= UserPosture then
				self.Parent.Combat:Afflict(TargetEntity,{
					CancelLevel = 1;
					Actions = {
						Push = {
							Push = 52,
							Duration = 0.6,
						};
						Stun = {
							Name = "ClashStun",
							Duration = 0.4;
							Speed = 0;
							Jump = 0;
						};
					};
				});
			else
				print("daa")
			end
		end
	end
	
	TargetEntity.Combat:AttemptCancel(2, self.Parent);
	self.Parent.Combat:AttemptCancel(2, TargetEntity);

	Util.TagAdd(ClashTags, self.Parent.Character.Rig, "Rooted")
	Util.TagAdd(ClashTags, Target, "Rooted")

	RootPart.Anchored = true
	EnemyRoot.Anchored = true
	self.Parent.Character.Humanoid.AutoRotate = false
	TargetEntity.Character.Humanoid.AutoRotate = false
	
	self.Parent.Character:SetActive(true)
	TargetEntity.Character:SetActive(true)
	self.Parent.Character:SetAttribute("Clashing",true)
	TargetEntity.Character:SetAttribute("Clashing",true)
	
	local Anim = self.Parent.Animator:Fetch(`Weapons/Fists/`..self.Parent.Combat.ClashData.Action..`Clash`);
	Anim:Play()
	ClashAnimations["UserAnim"] = Anim

	local EnemyAnim = TargetEntity.Animator:Fetch(`Weapons/Fists/`..TargetEntity.Combat.ClashData.Action..`Clash`);
	EnemyAnim:Play()
	ClashAnimations["TargetAnim"] = EnemyAnim
	
	ClashMaid:GiveTask(Target.AncestryChanged:Once(function()
		if Target.Parent ~= workspace.Entities then
			ClashMaid:Destroy()
		end
	end))
	
	ClashMaid:GiveTask(self.Parent.Character.Rig.AncestryChanged:Once(function()
		if self.Parent.Character.Rig.Parent ~= workspace.Entities then
			ClashMaid:Destroy()
		end
	end))
	
	ClashMaid:GiveTask(Target:GetAttributeChangedSignal("Clashing"):Connect(function()
		if not Target:GetAttribute("Clashing") then
			ClashMaid:Destroy()
		end
	end))
	
	ClashMaid:GiveTask(self.Parent.Character.Rig:GetAttributeChangedSignal("Clashing"):Connect(function()
		if not self.Parent.Character:GetAttribute("Clashing") then
			ClashMaid:Destroy()
		end
	end))

	local RootCF = Util.ExtrapolateMovingCFrame(RootPart)
	local EnemyRootCF = Util.ExtrapolateMovingCFrame(EnemyRoot)
	local MidPoint = (RootCF.Position + EnemyRootCF.Position) / 2
	
	if self.Parent.player then
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "ClashingInitialCamera";
		}
		self.Parent.VFX:FireClient(EffectData,{},self.Parent.player)
	end
	if TargetEntity.player then
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "ClashingInitialCamera";
		}
		TargetEntity.VFX:FireClient(EffectData,{},TargetEntity.player)
	end
	
	local EffectData = {
		EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
		Func = "ClashingFX";
	}
	self.Parent.VFX:FireAll(EffectData,{MidPoint})
	
	local EffectData = {
		EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
		Func = "LightningClash";
	}
	self.Parent.VFX:FireAll(EffectData,{CFrame.new(MidPoint,MidPoint+(EnemyRootCF.Position - RootCF.Position).Unit)})

	local direction = (EnemyRootCF.Position - RootCF.Position).Unit

	local offset = 2.25 -- studs from center

	local RootTarget = CFrame.lookAt(
		MidPoint - direction * offset,  -- Position for character 1
		MidPoint + direction * offset   -- Look at character 2's position
	)

	local EnemyTarget = CFrame.lookAt(
		MidPoint + direction * offset,  -- Position for character 2
		MidPoint - direction * offset   -- Look at character 1's position
	)

	local duration = 0.25
	local startTime = tick()


	ClashMaid:GiveTask(RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / duration, 1)

		local alpha = progress < 0.5 
			and 2 * progress * progress 
			or -1 + (4 - 2 * progress) * progress

		RootPart.CFrame = RootCF:Lerp(RootTarget, alpha)
		EnemyRoot.CFrame = EnemyRootCF:Lerp(EnemyTarget, alpha)
	end))
	
	local Duration      = 0.1
	local FadeTime      = 0.35
	local MoveSpeed     = 95
	local MoveRadius    = 5
	local BackDistance  = 3
	local EffectData = {
		EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
		Func = "ClashingMirage";
	}
	self.Parent.VFX:FireAll(EffectData,{Duration,FadeTime,MoveSpeed,MoveRadius,BackDistance,(self.Parent.player and self.Parent.player:GetAttribute("WillColor")) or nil})
	
	local EffectData = {
		EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
		Func = "ClashingMirage";
	}
	TargetEntity.VFX:FireAll(EffectData,{Duration,FadeTime,MoveSpeed,MoveRadius,BackDistance,(TargetEntity.player and TargetEntity.player:GetAttribute("WillColor")) or nil})
	
	self.Parent.Character.ClashMaid = ClashMaid
	
	task.delay(GameSettings.ClashDuration,function()
		if ClashMaid then ClashMaid:Destroy() end
	end)
end

function CombatManager:RegisterHit(HitEntity, PunchInfo: {any} | string, AirCombat: boolean?)
	local Valid = false;
	if typeof(PunchInfo) == 'table' then
		local CurrentAttack: number = PunchInfo.CurrentAttack;
		local PunchType: string = PunchInfo.AttackType;
		local CurrentId: string = PunchInfo.CurrentId;
		
		if self.Parent.EquippedWeapon ~= PunchInfo.CurrentWeapon then return warn('WEAPONS FOR HIT REGISTRATION ARENT MATCHING') end;
		local WeaponInfo = Server.WeaponData[PunchInfo.CurrentWeapon]
		local Path = (CurrentId or "").. (CurrentAttack or "");
		if self.Parent.Server.CancelledHits[Path] then return end;
		self.Parent.Server.LandedHits[CurrentId] = true;
		
		local function LightAttack()
			local StartPos = self.Parent.Character.Root.Position;
			local EndPos = HitEntity.Character.Root.Position;

			local Sub = (StartPos - EndPos);
			local Dist = Sub.Magnitude;
			local Unit = -Sub.Unit;

			Valid = self:Afflict(HitEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='Light';
					Data = {
						HitOrder = CurrentAttack;
						Type = PunchType,
					};
				};
				Actions = {
					Damage = {
						Amount = WeaponInfo.LightDamage;
						Posture = WeaponInfo.LightPostureDamage;
						HitReaction = CurrentAttack;
						Type = PunchType,
					};
					Knockback = {
						Push = 5;
						Duration = .2;
					};
					Stun = {
						Name = "LightStun",
						Duration = WeaponInfo.LightStun;
						Speed = 5;
						Jump = 5;
					};
				};
			});

		end
		
		local function Critical()
			local StartPos = self.Parent.Character.Root.Position;
			local EndPos = HitEntity.Character.Root.Position;

			local Sub = (StartPos - EndPos);
			local Dist = Sub.Magnitude;
			local Unit = -Sub.Unit;

			Valid = self:Afflict(HitEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='Critical';
					Data = {
						HitOrder = CurrentAttack;
						Type = PunchType,
					};
				};
				Actions = {
					
					HitStop = {
						Duration = 0.15;
						Scale = 0.05;
						Shake = {
							Duration = 0.15;
							PosAmplitude = 2.5;
						}
					};
					Damage = {
						Amount = WeaponInfo.HeavyDamage;
						Posture = WeaponInfo.HeavyPostureDamage;
						HitReaction = true;
						Type = PunchType,
					};
					Knockback = {
						Push = 45;
						Duration = .2;
					};
					Stun = {
						Name = "CriticalStun",
						Duration = .5;
						Speed = 5;
						Jump = 0;
					};
				};
			});
			
			self:Afflict({
				ExcludeAttempts = true;
				Actions = {
					HitStop = {
						Duration = 0.12;
						Scale = 0.05
					};
				};
			});
		end
		
		local function Aerial()
			local StartPos = self.Parent.Character.Root.Position;
			local EndPos = HitEntity.Character.Root.Position;

			local Sub = (StartPos - EndPos);
			local Dist = Sub.Magnitude;
			local Unit = -Sub.Unit;

			Valid = self:Afflict(HitEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='Aerial';
					Data = {
						HitOrder = CurrentAttack;
						Type = PunchType,
					};
				};
				Actions = {
					Damage = {
						Amount = WeaponInfo.AerialDamage;
						Posture = WeaponInfo.AerialPostureDamage;
						HitReaction = true;
						Type = PunchType,
					};
					Knockback = {
						Push = 25;
						Duration = .2;
					};
					Stun = {
						Name = "AerialStun",
						Duration = .5;
						Speed = 5;
						Jump = 0;
					};
				};
			});
		end

		local function Uptilt()
			local StartPos = self.Parent.Character.Root.Position;
			local EndPos = HitEntity.Character.Root.Position;

			local Sub = (StartPos - EndPos);
			local Dist = Sub.Magnitude;
			local Unit = -Sub.Unit;

			Valid = self:Afflict(HitEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='Light';
					Data = {
						HitOrder = CurrentAttack;
						Type = PunchType,
					};
				};
				Actions = {
					Damage = {
						Amount = 2;
						Posture = 35;
						HitReaction = CurrentAttack;
						Type = PunchType,
					};
					Uptilt = {
						Push = 10
					};
					Stun = {
						Name = "UptiltStun",
						Duration = 1.5;
						Speed = 0;
						Jump = 0;
					};
				};
			});

		end
		
		local function Downslam()
			local StartPos = self.Parent.Character.Root.Position;
			local EndPos = HitEntity.Character.Root.Position;

			local Sub = (StartPos - EndPos);
			local Dist = Sub.Magnitude;
			local Unit = -Sub.Unit;
	
			Valid = self:Afflict(HitEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='Light';
					Data = {
						HitOrder = CurrentAttack;
						Type = PunchType,
					};
				};
				Actions = {
					Damage = {
						Amount = 2;
					--	HitReaction = CurrentAttack;
						Type = PunchType,
					};
					Stun = {
						Name = "DownslamStun",
						Duration = .85;
						Speed = 0;
						Jump = 0;
					};
				};
			});

			if Valid then
				local PushDistance = (14*(Dist/7));

				self:ApplyAirHit(HitEntity, "Downslam")
			end
		end
		
		local function Airpush()
			local StartPos = self.Parent.Character.Root.Position;
			local EndPos = HitEntity.Character.Root.Position;

			local Sub = (StartPos - EndPos);
			local Dist = Sub.Magnitude;
			local Unit = -Sub.Unit;
	
			Valid = self:Afflict(HitEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='Light';
					Data = {
						HitOrder = CurrentAttack;
						Type = PunchType,
					};
				};
				Actions = {
					Damage = {
						Amount = 2;
						HitReaction = CurrentAttack;
						Type = PunchType,
					};
					Stun = {
						Name = "AirpushStun",
						Duration = .85;
						Speed = 0;
						Jump = 0;
					};
				};
			});

			if Valid then
			
				self:ApplyAirHit(HitEntity, "Airpush")
			end
		end
		
		local function AirLightAttack()
			local StartPos = self.Parent.Character.Root.Position;
			local EndPos = HitEntity.Character.Root.Position;

			local Sub = (StartPos - EndPos);
			local Dist = Sub.Magnitude;
			local Unit = -Sub.Unit;
	
			Valid = self:Afflict(HitEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='Light';
					Data = {
						HitOrder = CurrentAttack;
						Type = PunchType,
					};
				};
				Actions = {
					Damage = {
						Amount = 2;
						HitReaction = CurrentAttack;
						Type = PunchType,
					};
					Stun = {
						Name = "AirLightStun",
						Duration = .85;
						Speed = 5;
						Jump = 0;
					};
				};
			});

			if Valid then
				local PushDistance = (14*(Dist/7));

				self:ApplyAirHit(HitEntity, "LightAttack")
			end
		end
		
		if AirCombat and PunchType == 'Downslam' then
			Downslam()
		elseif AirCombat and PunchType == 'Airpush' then
			Airpush()
		elseif AirCombat then
			AirLightAttack()
		elseif PunchType == 'Uptilt' then
			Uptilt()
		elseif PunchType == 'Critical' then
		--	local clashPartner = self:CheckClash(HitEntity)
		--	Critical()
			local Clashed = self:CheckForClash(HitEntity,PunchInfo)
			if not Clashed then
				Critical()
			end
		elseif PunchType == 'Aerial' then 
			local Clashed = self:CheckForClash(HitEntity,PunchInfo)
			if not Clashed then
				Aerial()
			end
		elseif CurrentAttack < WeaponInfo.ComboMax then
			LightAttack()
		else

			Valid = self:Afflict(HitEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='Light';
					Data = {
						HitOrder = CurrentAttack;
						Type = PunchType,
					};
				};
				Actions = {
					Damage = {
						Amount = WeaponInfo.LightDamage;
						Posture = WeaponInfo.LightPostureDamage;
					};
					Knockback = {
						Push = 42;
						Duration = .1;
					};
					Ragdoll = 1;
				};
			});

		end;	
	end;

	return Valid;
end;

function CombatManager:Destroy()
	self._Trove:Destroy();
end;

return CombatManager;