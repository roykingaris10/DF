return function(Client)
	local FXClient = {}
	local player = Client.player
	local Network = Client.Network
	local Utilities = Client.Utilities

	local RunService = game:GetService('RunService')
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PhysicsService = game:GetService("PhysicsService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local SoundHandler = require(Nodes.Utility.SoundHandler)
	local Auxiliary = require(Nodes.Utility.Auxiliary)
	local EffectsFolder = workspace:WaitForChild("EffectsFolder")
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	
	FXClient.Forward = function(self: {any}, Args: {any}, ServerCall: boolean?)
	--	if ServerCall and self.IsClient then return end;
		SoundHandler.Spawn('Movement/Dash', self.Character.Root, 1);
		--local _RockBind = Auxiliary.Rock.SideRocks(self.Character.Root, 3, false, .8, .08);
		local RootCFr = self.Character.Root.CFrame;
		
		local armTable = {"Left","Right"}
		local armTrails = {}
		for i = 1,#armTable do
			local arm = self.Character.Rig[armTable[i].." Arm"]
			local trailpart = script.ArmTrail:Clone()
			trailpart.Parent = EffectsFolder
			trailpart.CFrame = arm.CFrame
			
			local ArmWeld = Instance.new("WeldConstraint")
			ArmWeld.Parent = trailpart
			ArmWeld.Part0 = trailpart
			ArmWeld.Part1 = arm
			armTrails[i] = trailpart
			Client.EffectFunctions:Enable(trailpart,true);
		end

		local StartEffect: Model = Auxiliary.Client.SpawnGroup(script.Start, RootCFr, 1);
		local StartParticles: Model = Auxiliary.Client.AlignGroup(Auxiliary.Client.SpawnGroup(script.StartParticles, RootCFr, 3));
		task.spawn(Auxiliary.Client.Emit, StartParticles);
		task.spawn(Auxiliary.Rock.Crater, RootCFr*CFrame.Angles(-math.rad(20),0,0), {

			MinAngleVariation = -20;
			MaxAngleVariation = 30;

			Rocks = 6;
			
			BaseDuration = 1,
			ExposeLevel = -2;
			Distance = 7;	
			OpenSpaces=1;

			SizeMagnitude = Vector3.new(1.4,2,1);

		});
		task.spawn(Auxiliary.Rock.Explode, RootCFr, {
			Rocks = 8;
			SizeMagnitude = .5;
			HorizontalVelocity = 5;
			VerticalVelocity = 8;
			Lifespan = 3;
		});

		Auxiliary.Rock.NewSideRocks(
			self.Character.Root, 
			{
				[1] = 'Look',
				[2] = 0.6,
				[3] = 0.67,
				[5] = 0.05555555555555555,
				[6] = 0.5;
			}
		);

		--Blur effect
		Auxiliary.Client.BindMesh(StartEffect.TorusBlur, function(Torus)
			TweenService:Create(Torus, TweenInfo.new(.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = Torus.CFrame * CFrame.new(0,-4,0), Size = Vector3.new(0,8,0), Transparency = 1}):Play();
			task.wait(.1);
		end);

		Auxiliary.Client.BindMesh(StartEffect.RingOuter, function(v)
			TweenService:Create(v, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = v.CFrame * CFrame.new(0,-3,0), Size = Vector3.new(9,0,9), Transparency = 1}):Play();
			task.wait(.2);
		end);

		Auxiliary.Client.BindMesh(StartEffect.RingInner, function(v)
			TweenService:Create(v, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = v.CFrame * CFrame.new(0,-2,0), Size = Vector3.new(13,0,13), Transparency = 1}):Play();
			task.wait(.2);
		end);

		repeat wait() until not self.Character.Rig:GetAttribute('Dashing') and not self.Character.Rig:GetAttribute('DashEffect');
		--_RockBind:Fire();
		
	
		task.wait(0.5)
		for i,armpart in pairs(armTrails) do
			if armpart then
				Client.EffectFunctions:Enable(armpart,false,true);
				Client.Debris:AddItem(armpart,1)
			end
		end
		armTrails = {}
	end;
	
	FXClient.Side = function(self: {any}, Args: {any})
		local RootPart = self.Character.Root
		local Side = Args[1]
		SoundHandler.Spawn('Movement/Dash', self.Character.Root, 1);
		local armTable = {"Left","Right"}
		local armTrails = {}
		for i = 1,#armTable do
			local arm = self.Character.Rig[armTable[i].." Arm"]
			local trailpart = script.ArmTrail:Clone()
			trailpart.Parent = EffectsFolder
			trailpart.CFrame = arm.CFrame

			local ArmWeld = Instance.new("WeldConstraint")
			ArmWeld.Parent = trailpart
			ArmWeld.Part0 = trailpart
			ArmWeld.Part1 = arm
			armTrails[i] = trailpart
			Client.EffectFunctions:Enable(trailpart,true);
		end
		
		local SideDustEffect = script.SideDust:Clone();
		local Enabled = true;
		
		local function UpdateDust()
			local RootCFr = self.Character.Root.CFrame;
			local Ground = workspace:Raycast(RootCFr.Position, Vector3.yAxis*-4,Auxiliary.Shared.RayParams.Map);
			if not Ground then
				if Enabled then
					Enabled = false;
					Client.EffectFunctions:Enable(SideDustEffect,false, true);
				end;
			else
				if not Enabled then
					Enabled = true;
					Client.EffectFunctions:Enable(SideDustEffect,true);

				end;

				local FacingCFr = CFrame.new(RootCFr.Position, RootCFr.Position+RootCFr.RightVector);
				if Side == 'Left' then
					FacingCFr *= CFrame.Angles(0,math.pi,0);
				end;

				SideDustEffect.CFrame = (FacingCFr - FacingCFr.Position) + (Ground.Position-Vector3.yAxis*.5);
			end;
		end;
		
		Auxiliary.Rock.NewSideRocks(
			self.Character.Root, 
			{ 'Sides', 0.4, 0.5 }
		);
		local OldTick = tick();

		UpdateDust();
		SideDustEffect.Parent = EffectsFolder;

		repeat
			task.spawn(UpdateDust);
			task.wait(.05);
		until tick()-OldTick >= .35 or not self.Character.Rig:GetAttribute("SideDashClient");
		task.wait(0.15)
		Client.EffectFunctions:Enable(SideDustEffect,false);
		
		task.wait(0.5)
		for i,armpart in pairs(armTrails) do
			if armpart then
				Client.EffectFunctions:Enable(armpart,false,true);
				Client.Debris:AddItem(armpart,1)
			end
		end
		armTrails = {}
	end
	
	FXClient.Backward = function(self: {any}, Args: {any}, ServerCall: boolean?)
		local RootCFr = self.Character.Root.CFrame;

		SoundHandler.Spawn('Movement/Dash', self.Character.Root, 1);
	
		local armTable = {"Left","Right"}
		local armTrails = {}
		for i = 1,#armTable do
			local arm = self.Character.Rig[armTable[i].." Arm"]
			local trailpart = script.ArmTrail:Clone()
			trailpart.Parent = EffectsFolder
			trailpart.CFrame = arm.CFrame

			local ArmWeld = Instance.new("WeldConstraint")
			ArmWeld.Parent = trailpart
			ArmWeld.Part0 = trailpart
			ArmWeld.Part1 = arm
			armTrails[i] = trailpart
			Client.EffectFunctions:Enable(trailpart,true);
		end
		local DustEffect = script.SideDust:Clone();

		local Enabled = true;
		local function UpdateDust()
			local RootCFr = self.Character.Root.CFrame;
			local Ground = workspace:Raycast(RootCFr.Position, Vector3.yAxis*-4,Auxiliary.Shared.RayParams.Map);
			if not Ground then
				if Enabled then
					Enabled = false;
					Client.EffectFunctions:Enable(DustEffect,false, true);
				end;
			else
				if not Enabled then
					Enabled = true;
					Client.EffectFunctions:Enable(DustEffect,true);
				end;

				local FacingCFr = CFrame.new(RootCFr.Position, RootCFr.Position+RootCFr.RightVector);
				DustEffect.CFrame = (FacingCFr - FacingCFr.Position) + (Ground.Position-Vector3.yAxis*.5);
			end;
		end;

		local _RockBind = Auxiliary.Rock.SideRocks(self.Character.Root, 2.5, false, .8, .05);
		local BackStart: Model = Auxiliary.Client.AlignGroup(Auxiliary.Client.SpawnGroup(script.BackStart, RootCFr*CFrame.Angles(0,math.pi,0), 3));
		Auxiliary.Client.Emit(BackStart);

		local OldTick = tick();

		UpdateDust();
		DustEffect.Parent = EffectsFolder;

		repeat
			task.spawn(UpdateDust);
			task.wait(.05);
		until tick()-OldTick >= 1 or not self.Character.Rig:GetAttribute("DashEffect");

		--_RockBind:Fire();
		Auxiliary.Client.Toggle(false, DustEffect);
		Client.Debris:AddItem(DustEffect, 2);

		_RockBind:Fire();
		
		
		task.wait(0.5)
		for i,armpart in pairs(armTrails) do
			if armpart then
				Client.EffectFunctions:Enable(armpart,false,true);
				Client.Debris:AddItem(armpart,1)
			end
		end
		armTrails = {}
	end;

	FXClient.Woosh = function(self: {any}, Args: {any}, ServerCall: boolean?)
		if ServerCall and self.IsClient then return end;
	--	SoundHandler.Spawn('Universal/Dash/Front/Swing', self.Character.Root, 1);

		task.wait(.08);
		local WooshEffect: Model = Auxiliary.Client.SpawnGroup(script.Woosh, self.Character.Root.CFrame, 3);
		Auxiliary.Client.Emit(Auxiliary.Client.AlignGroup(WooshEffect));
	end;
	
	FXClient.Air = function(self: {any}, Args: {any}, ServerCall: boolean?)
		--	if ServerCall and self.IsClient then return end;
		SoundHandler.Spawn('Movement/Sanji Geppo', self.Character.Root, 0.4);
		--local _RockBind = Auxiliary.Rock.SideRocks(self.Character.Root, 3, false, .8, .08);
		local RootCFr = self.Character.Root.CFrame;

		local armTable = {"Left","Right"}
		local armTrails = {}
		for i = 1,#armTable do
			local arm = self.Character.Rig[armTable[i].." Arm"]
			local trailpart = script.ArmTrail:Clone()
			trailpart.Parent = EffectsFolder
			trailpart.CFrame = arm.CFrame

			local ArmWeld = Instance.new("WeldConstraint")
			ArmWeld.Parent = trailpart
			ArmWeld.Part0 = trailpart
			ArmWeld.Part1 = arm
			armTrails[i] = trailpart
			Client.EffectFunctions:Enable(trailpart,true);
		end

		task.spawn(Auxiliary.Rock.Crater, CFrame.new(RootCFr.Position), {

			MinAngleVariation = 50;
			MaxAngleVariation = 65;
			LayerRingRandomization = true;

			Rocks = 4;
			
			RaycastRange = 15;
			BaseDuration = 5,
			ExposeLevel = -0.3;
			Distance = 2;	
			Layers = 3;
			LayerScaling = 0.125;

			SizeMagnitude = Vector3.new(0.85,1.5,0.2);

		});
		task.spawn(Auxiliary.Rock.Explode, RootCFr, {
			Rocks = 8;
			SizeMagnitude = .5;
			HorizontalVelocity = -3;
			VerticalVelocity = 8;
			RayRange = 15;
			Lifespan = 3;
		});


		repeat wait() until not self.Character.Rig:GetAttribute('Dashing') and not self.Character.Rig:GetAttribute('AirDashEffect');
		--_RockBind:Fire();


		task.wait(0.5)
		for i,armpart in pairs(armTrails) do
			if armpart then
				Client.EffectFunctions:Enable(armpart,false,true);
				Client.Debris:AddItem(armpart,1)
			end
		end
		armTrails = {}
	end;
	
	FXClient.WillDash = function(self: {any}, Args: {any}, ServerCall: boolean?)
		
		local RootCFr = self.Character.Root.CFrame;
		
		SoundHandler.Spawn('Movement/Teleport Soru v2', self.Character.Root, 1);
		local DashStart = Auxiliary.Client.SpawnGroup(script.WillDashStart, CFrame.new(self.Character.Root.Position+Vector3.new(0,-1,0)), 0.5);
		Client.EffectFunctions:Emit(DashStart)
		
		local DashSmoke = Auxiliary.Client.SpawnGroup(script.WillDashSmoke, CFrame.new(self.Character.Root.Position+Vector3.new(0,-2.25,0)), 0.5);
		Client.EffectFunctions:Emit(DashSmoke)
		
		task.spawn(Auxiliary.Rock.Crater, CFrame.new(RootCFr.Position), {

			MinAngleVariation = 50;
			MaxAngleVariation = 65;
			LayerRingRandomization = true;

			Rocks = 4;

			RaycastRange = 15;
			BaseDuration = 15,
			ExposeLevel = -0.3;
			Distance = 2;	
			Layers = 3;
			LayerScaling = 0.125;

			SizeMagnitude = Vector3.new(0.85,1.5,0.2);

		});
		task.spawn(Auxiliary.Rock.Explode, RootCFr, {
			Rocks = 8;
			SizeMagnitude = .5;
			HorizontalVelocity = -3;
			VerticalVelocity = 8;
			RayRange = 15;
			Lifespan = 3;
		});

		local endtime = 1 + tick()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local currTime = tick()
			if not self.Character.Rig:GetAttribute("WillDashingEffects") or currTime > endtime then 
				connection:Disconnect() 
				SoundHandler.Spawn('Movement/Teleport Soru v2', self.Character.Root, 1);
				
				local DashEnd = Auxiliary.Client.SpawnGroup(script.WillDashStart, CFrame.new(self.Character.Root.Position+Vector3.new(0,-1,0)), 0.5);
				Client.EffectFunctions:Emit(DashStart)

				local DashSmokeEnd = Auxiliary.Client.SpawnGroup(script.WillDashSmoke, CFrame.new(self.Character.Root.Position+Vector3.new(0,-2.25,0)), 0.5);
				Client.EffectFunctions:Emit(DashSmoke)
				return end
		end)

		repeat 
			local currTime2 = tick()
			
			local dashEmit = Auxiliary.Client.SpawnGroup(script.WillDashInner, CFrame.new(self.Character.Root.Position), 0.3);
			Client.EffectFunctions:Emit(dashEmit)
			SoundHandler.Spawn('Movement/Teleport Soru v2', self.Character.Root, 1);
	
			task.wait(.15)
		until not self.Character.Rig:GetAttribute("WillDashingEffects") or currTime2 > endtime
	end
	
	FXClient.FlickerRush = function(self: {any}, Args: {any}, ServerCall: boolean?)

		local RootCFr = self.Character.Root.CFrame;
		CombatUtility:CharacterVisible(self.Character.Rig,true)
		SoundHandler.Spawn('Movement/Teleport Soru v2', self.Character.Root, 1);
		local DashStart = Auxiliary.Client.SpawnGroup(script.WillDashStart, CFrame.new(self.Character.Root.Position+Vector3.new(0,-1,0)), 0.5);
		Client.EffectFunctions:Emit(DashStart)

		local DashSmoke = Auxiliary.Client.SpawnGroup(script.WillDashSmoke, CFrame.new(self.Character.Root.Position+Vector3.new(0,-2.25,0)), 0.5);
		Client.EffectFunctions:Emit(DashSmoke)

		task.spawn(Auxiliary.Rock.Crater, CFrame.new(RootCFr.Position), {

			MinAngleVariation = 50;
			MaxAngleVariation = 65;
			LayerRingRandomization = true;

			Rocks = 4;

			RaycastRange = 15;
			BaseDuration = 15,
			ExposeLevel = -0.3;
			Distance = 2;	
			Layers = 3;
			LayerScaling = 0.125;

			SizeMagnitude = Vector3.new(0.85,1.5,0.2);

		});
		task.spawn(Auxiliary.Rock.Explode, RootCFr, {
			Rocks = 8;
			SizeMagnitude = .5;
			HorizontalVelocity = -3;
			VerticalVelocity = 8;
			RayRange = 15;
			Lifespan = 3;
		});

		local endtime = 1 + tick()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local currTime = tick()
			if not self.Character.Rig:GetAttribute("FlickerRushing") or currTime > endtime then 
				connection:Disconnect() 
				SoundHandler.Spawn('Movement/Teleport Soru v2', self.Character.Root, 1);

				local DashEnd = Auxiliary.Client.SpawnGroup(script.WillDashStart, CFrame.new(self.Character.Root.Position+Vector3.new(0,-1,0)), 0.5);
				Client.EffectFunctions:Emit(DashStart)

				local DashSmokeEnd = Auxiliary.Client.SpawnGroup(script.WillDashSmoke, CFrame.new(self.Character.Root.Position+Vector3.new(0,-2.25,0)), 0.5);
				Client.EffectFunctions:Emit(DashSmoke)
				return end
		end)

		repeat 
			local currTime2 = tick()

			local dashEmit = Auxiliary.Client.SpawnGroup(script.WillDashInner, CFrame.new(self.Character.Root.Position), 0.3);
			Client.EffectFunctions:Emit(dashEmit)
			SoundHandler.Spawn('Movement/Teleport Soru v2', self.Character.Root, 1);

			task.wait(.15)
		until not self.Character.Rig:GetAttribute("FlickerRushing") or currTime2 > endtime
		CombatUtility:CharacterVisible(self.Character.Rig,false)
	end


	
	return FXClient end
