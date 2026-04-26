return function(Server)
	
	local Util = Server.Utilities
	local Network = Server.Network
	local LibraryInfo = Server.LibraryInfo
	
	local Debris = game:GetService("Debris")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local Maid = require(Nodes.Utility.Maid)
	local Auxiliary = require(Nodes.Utility.Auxiliary)
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	
	local AirCombat = {}
	
	function AirCombat:Uptilt(Entity, TargetEntity)
		warn("----")
		warn("Uptilt")
		
		local RootPart = Entity.Character.Root
		local Target = TargetEntity.Character.Rig
		local EnemyRoot = TargetEntity.Character.Root
		local EnemyHumanoid = TargetEntity.Character.Humanoid
		
		local TargetStunned: Boolean = false;
		local Hit = nil;
		
		local StunMaid = Maid.new()
		local StunTags = {}
		local StunAnimations = {}
		
		local VelocityProperties ={
			InFront = true;
			Velocity = 32;
			Gravity = 33;
			DirectionOffset = CFrame.new(0, 0.8, 0.1);
			LifeTime = 1.5;
			AirState = true;
		};
		
		TargetEntity.Character:SetAttribute("Uptilted", true)
		Entity.Character:SetAttribute("AirComboTarget",true)
		Entity.Character:SetAttribute("AirEngage",true)

		local AirComboTarget = Instance.new("ObjectValue")
		AirComboTarget.Name = "AirComboTarget"
		AirComboTarget.Parent = Entity.Character.Rig
		AirComboTarget.Value = TargetEntity.Character.Rig
		StunMaid:GiveTask(AirComboTarget)
		
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "AirCombatTag";
		}
		Entity.VFX:FireAll(EffectData,{})
--		Server.Debris:AddItem(AirComboTarget,1.4)
		
		StunMaid.OnClean = function()
			warn("CLEANING UPTILT")
			TargetEntity.Character.JuggleMaid = nil
			Util.ClearTable(StunTags)	

			for _, Animation: AnimationTrack in pairs(StunAnimations) do
				Animation:Stop()
			end

			if EnemyRoot and EnemyRoot.Parent then
				EnemyRoot.Anchored = false
			end

			if Target and Target.Parent then
				TargetEntity.Character:SetAttribute("Uptilted", nil)
				TargetEntity.Character:SetAttribute("AerialVelocity", nil)
				TargetEntity.Character:SetAttribute("AerialCount", nil)
				TargetEntity.Character:SetAttribute("AutoRotate",nil)
			end
			
			if AirComboTarget or AirComboTarget.Parent then
				AirComboTarget:Destroy()
			end
			
			Entity.Character:SetAttribute("AirEngage",nil)
			Entity.Character:SetAttribute("AirComboTarget",nil)
		end
		
		StunMaid:GiveTask(Target.AncestryChanged:Once(function()
			if Target.Parent ~= workspace.Entities then
				StunMaid:Destroy()
			end
		end))
		
		local Animation = TargetEntity.Animator:Fetch(`Victim/Juggle`);
		Animation.Priority = Enum.AnimationPriority.Action
		
		StunAnimations["TargetAnim"] = Animation
		StunAnimations["TargetAnim"]:Play()

		StunMaid:GiveTask(StunAnimations["TargetAnim"]:GetMarkerReachedSignal("BeginSlow"):Connect(function()
			StunAnimations["TargetAnim"]:SetAttribute("Speed",0.8)
		end))

		StunMaid:GiveTask(StunAnimations["TargetAnim"]:GetMarkerReachedSignal("Pause"):Connect(function()
			StunAnimations["TargetAnim"]:SetAttribute("Speed",0)
		end))
		
		TargetEntity.Character:SetAttribute("AutoRotate",true)
		if VelocityProperties.AirState then
			Util.TagAdd(StunTags, Target, "InAirState")
		end

		Util.TagAdd(StunTags, Target, "CombatDisable")
		Util.TagAdd(StunTags, Target, "Stunned")
--		Util.TagAdd(StunTags, Target, "NoJump")
		
		local AerialState = Util.TagAdd(StunTags, Target, "AerialState")
		local AerialCount = 1

		local InitiateVelocity = function()
			-- // Orient Target to Player
			local KnockbackPosition: Vector3 = Vector3.new(RootPart.Position.X, EnemyRoot.Position.Y, RootPart.Position.Z)
			local NewCF: CFrame = CFrame.new(EnemyRoot.Position, KnockbackPosition)
			local EndCFrame: CFrame = VelocityProperties.EndCFrame or CFrame.new(EnemyRoot.Position, EnemyRoot.Position + Vector3.new(NewCF.LookVector.X, 0, NewCF.LookVector.Z))

			if VelocityProperties.InFront then
				EnemyRoot.CFrame = RootPart.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(180), 0)
			end

			local Offset: CFrame do
				-- First One == 2 because we increment above.
				if AerialCount == 2 then
					Offset = VelocityProperties.FirstOffset or CFrame.new(0, 0, 0)
				else
					Offset = VelocityProperties.SecondOffset or CFrame.new(0, -1.5 * AerialCount, 0)
				end
			end
			local FaceOffsetCF: CFrame = EndCFrame * Offset
			-- // CFrame Velocity
			local DirectionOffset: CFrame = VelocityProperties.DirectionOffset or CFrame.new(0, 2, 0.9) -- 0.7
			local DirectionCF: CFrame = FaceOffsetCF * DirectionOffset
			DirectionCF = CFrame.new(FaceOffsetCF.Position, DirectionCF.Position)

			local Direction: Vector3 = DirectionCF.LookVector
			local Gravity: Number = (VelocityProperties.Gravity or 145) 
			local Velocity = Direction * (VelocityProperties.Velocity or 45)

			EnemyRoot.Anchored = true
			EnemyRoot.CFrame = DirectionCF
			local LastPosition: Vector3 = DirectionCF.Position
--[[
			EffectsRemote:FireAllClients((args.SubRegen and "SkillHit") or VelocityProperties.VFX or "VelocityJuggleHit", {
				Root = EnemyRoot;
				AirState = VelocityProperties.AirState;
			})
]]
			return LastPosition, Gravity, Velocity
		end
		
		StunMaid:GiveTask(AerialState.AncestryChanged:Once(function()
			if not AerialState.Parent then
				TargetStunned = true
				StunMaid:Destroy()
			end
		end))
		
		local LastPosition: Vector3, Gravity: Number, Velocity: Number = InitiateVelocity()

		task.delay(VelocityProperties.LifeTime or VelocityProperties.stuntime or 3, function()
			if StunMaid then StunMaid:Destroy() end
		end)
		
		local RayParams = Auxiliary.Shared.RayParams.Map

		local FloorBuffer = 0.6
		local StartTick = tick()

		StunMaid:GiveTask(RunService.Heartbeat:Connect(function(Delta)
			LastPosition = EnemyRoot.Position
			Velocity = Velocity - Vector3.new(0, Gravity * Delta, 0)

			-- // Velocity Check
			local CurrentPosition = Util.ExtrapolateMovingCFrame(EnemyRoot).Position
			local Move = Velocity * Delta
			local MoveMag = Move.Magnitude
			local TargetPos = CurrentPosition + Move

			Hit = Util.Raycast(CurrentPosition, Move.Unit, MoveMag, RayParams)
			if Hit then
				StunMaid:Destroy()
				return
			else
				-- // Floor Check
				local FloorHit = Util.Raycast(TargetPos + Vector3.new(0, 2, 0), Vector3.new(0, -1, 0), 6, RayParams)
				if FloorHit and StartTick + FloorBuffer < tick() then
					local FloorY = FloorHit.Position.Y
					-- keep a small hover so we don't clip
					local MinY = FloorY + 1.2
					if TargetPos.Y < MinY then
						TargetPos = Vector3.new(TargetPos.X, MinY, TargetPos.Z)
					end
				end

				-- // Before Velocity Direction
				local NewPosition: Vector3 = EnemyRoot.Position + (Velocity * Delta)
				local LookDirection: Vector3 = Velocity.Unit
				local NewCF: CFrame = CFrame.lookAt(NewPosition, NewPosition + LookDirection)
				local StartCF = NewCF * CFrame.new(0,0,3) -- Start behind

				Hit = Util.Raycast(StartCF.Position, NewCF.LookVector, 5, RayParams)
				if Hit and StartTick + FloorBuffer < tick()then
					StunMaid:Destroy()
					return
				else
					EnemyRoot.CFrame = NewCF * CFrame.Angles(0, math.rad(180), 0)
				end
			end
		end))
		
		TargetEntity.Character.JuggleMaid = StunMaid	
		warn("UPTILT JUGGLE SET")
		warn("----")
	end
	
	function AirCombat:AirStartCritical(Entity, TargetEntity)
		local RootPart = Entity.Character.Root
		local Target = TargetEntity.Character.Rig
		local EnemyRoot = TargetEntity.Character.Root
		local EnemyHumanoid = TargetEntity.Character.Humanoid
		
		local WeaponName = Entity.EquippedWeapon or "Fists"
		local WeaponData = Server.WeaponData[WeaponName]
		if not WeaponData then return end
		local Duration = 0.08
		local OffsetDist = 0.8
		local MoveRadius = 3
		local MoveSpeed = 100
		local FadeTime = 0.18
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "CloneMirage";
		}
		Entity.VFX:FireAll(EffectData,{Duration,OffsetDist,MoveRadius,MoveSpeed,FadeTime})
		
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "CriticalAirRush";
		}
		Entity.VFX:FireAll(EffectData,{})
		
		Entity.Character:SetActive(true);
		Entity.Character:SetAttribute("AttackBuffer",true)
		
		task.delay(0.15,function() 
			CombatUtility:CharacterVisible(Entity.Character.Rig,true)
		end)
		
		local Animation = Entity.Animator:Fetch(`Weapons/{WeaponName}/AirStartCritical`);
		Animation:Play()
		
		local AlignPosition
		local endEarly = false
		
		if (EnemyRoot.Position - RootPart.Position).Magnitude < 75 then
			task.spawn(function()
				task.wait(0.05)

				--	if OnMaxCombo then
				--		Util.ClearConstraints("constraintHolders", Root)
				--	end

				local EnemyCFrame = Util.ExtrapolateMovingCFrame(EnemyRoot)
				local directionToEnemy = (EnemyCFrame.Position - RootPart.Position) * Vector3.new(1, 0, 1) -- Flatten Y to keep upright
				local lookAtPosition = RootPart.Position + directionToEnemy

				local FinalCFrame = RootPart.CFrame.Rotation + (EnemyCFrame.Position + (RootPart.CFrame.lookVector * -2))

				AlignPosition = Kits.Storage.BodyM.AirComboTrack:Clone()
				AlignPosition.Attachment0 = RootPart.MainAttach
				AlignPosition.Position = FinalCFrame.Position -- (eroot.CFrame * CFrame.new(0,0,-3)).Position
				AlignPosition.Parent = RootPart

				local Destroying = false
				repeat
					if not EnemyRoot or not EnemyRoot.Parent then break end
					if not RootPart or not RootPart.Parent then break end

					if Entity.Character.Stunned then 
						if AlignPosition then
							AlignPosition:Destroy()
						end
						break
					end

					if not Destroying and (RootPart.Position - EnemyRoot.Position).Magnitude < 20 then
						Destroying = true

						if AlignPosition then
							task.delay(0.25, AlignPosition.Destroy, AlignPosition)
						end
					end

					--	if not OnMaxCombo then
					EnemyCFrame = Util.ExtrapolateMovingCFrame(EnemyRoot)
					FinalCFrame = RootPart.CFrame.Rotation + (EnemyCFrame.Position + (RootPart.CFrame.lookVector * -2))
					AlignPosition.Position = FinalCFrame.Position
					--	end

					task.wait()
				until AlignPosition.Parent ~= RootPart or not Target:GetAttribute("Uptilted")

				if AlignPosition then
					AlignPosition:Destroy()
				end
				CombatUtility:CharacterVisible(Entity.Character.Rig,false)
				Entity.Character:SetActive(false);
			end)
		end
		
		task.delay(0.4,function()
			if AlignPosition then
				AlignPosition:Destroy()
			end
			
			CombatUtility:CharacterVisible(Entity.Character.Rig,false)
			Entity.Character:SetActive(false);
			
			task.delay(1,function()
				Entity.Character:SetAttribute("AttackBuffer",nil);
			end)
			
			local direction = (Vector3.new(Entity.Character.Root.Position.X,TargetEntity.Character.Root.Position.Y,Entity.Character.Root.Position.Z) - TargetEntity.Character.Root.Position).Unit
			local distance = 3 -- studs away from target

			local AirPos = TargetEntity.Character.Root.Position + (direction * distance)
			AirPos = Vector3.new(AirPos.X, TargetEntity.Character.Root.Position.Y, AirPos.Z)

			if Entity.player then
				Network:post("ClientEvent",Entity.player,"RemoveAllBodyForces",Entity.Character.Root)
				Network:post("ClientEvent",Entity.player,"BPPlacer",Entity.Character.Root,{
					Name = "AirUp",
					MaxForce = Vector3.new(1e8,1e9,1e8),
					Position = AirPos,
					P = 11000,
					D = 800,
					Duration = 0.75,
				})
			end
			
			if not Entity.Server.CancelledHits["AirStartCritical"] then
				Entity.Combat:Afflict(TargetEntity, {
					CancelLevel = 1;
					HitVFX = {
						Name='AirStartCritical';
						Data = {
							--HitOrder = CurrentAttack;
								Type = "Critical",
						};
					};
					Actions = {
						HitStop = {
							Duration = 0.3;
							Scale = 0.05;
							Shake = {
								Duration = 0.3;
								PosAmplitude = 2.5;
							}
						};
						Damage = {
							Amount = 5;
							--	HitReaction = CurrentAttack;
							--	Type = PunchType,
						};
						Stun = {
							Name = "AirStartCritical",
							Duration = .85;
							Speed = 0;
							Jump = 0;

							Callback = function()
								if TargetEntity.Character.JuggleMaid then
									TargetEntity.Character.JuggleMaid:Destroy()
								end
							--	AirCombat:AirJuggle(Entity, TargetEntity, VelocityProperties, HitIdentity)	
							
								local state, rayResult, reflect = CombatUtility:DownSlam(TargetEntity, Entity)
								
								if state then
									local EffectData = {
										EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
										Func = "SlamBounce";
									}
									Entity.VFX:FireAll(EffectData,{rayResult.Position,rayResult.Instance.Color,rayResult.Instance.Material,reflect})
								end
							end,
						};
						Ragdoll = 1;
					};
				});
			end

		end)
	end
	
	function AirCombat:AirLightHit(Entity, TargetEntity, HitIdentity: {})
		warn("----")
		warn("AIR LIGHT CALLED")
		
		local RootPart = Entity.Character.Root
		local Target = TargetEntity.Character.Rig
		local EnemyRoot = TargetEntity.Character.Root
		local EnemyHumanoid = TargetEntity.Character.Humanoid

		local WeaponName = Entity.EquippedWeapon or "Fists"
		local WeaponData = Server.WeaponData[WeaponName]
		if not WeaponData then return end
		
		if Entity.Server.LastAirLightAttack then
			if tick()-Entity.Server.LastAirLightAttack < .01 then return end;
		end;

		Entity.Character:SetActive(true);
		Entity.Character:SetAttribute("BlockBuffer" ,true)
		Entity.Character:SetAttribute("AirComboing", true)
		Entity.Character:SetAttribute("CriticalBuffer", true)
		Entity.Server.LastAirLightAttack = tick();

		local function ResetPunch()
			Entity.Character:SetCurrentAirAttack(0);
			Entity.Character.PunchIdentifier = HttpService:GenerateGUID(false);
		end;

		local CurrentAttack;
		local CurrentId;
		if not Entity.player then
			if not Entity.Character.CurrentAirAttack then
				ResetPunch();
			end;

			Entity.Character:SetCurrentAirAttack(Entity.Character.CurrentAirAttack+1);
			CurrentAttack = tonumber(Entity.Character.CurrentAirAttack);
			CurrentId = Entity.Character.PunchIdentifier;
		else
			CurrentAttack = HitIdentity.CurrentAirAttack;
			CurrentId = HitIdentity.CurrentId;
		end;
		
		local Tags = {}
		Util.TagAdd(Tags, Entity.Character.Rig, "Attacking", nil, nil)
		Util.TagAdd(Tags, Entity.Character.Rig, "NoJump", nil, nil)
		Util.TagAdd(Tags, Entity.Character.Rig, "CombatDisable", nil, nil)
		local SingleTag = {}
		local AerialBuffer = Util.TagAdd(SingleTag, Entity.Character.Rig, "AerialBuffer", nil, nil)
		
		Entity.StatManager:SetAbsolute("AirLight", {
			WalkSpeed = 5,
			JumpPower = 0,
			Priority = 2,
		})
		
		local Path = `Light{CurrentAttack}`
		
		local VelocityProperties = {
			InFront = true;
			Velocity = 20;
			Gravity = 25;
			DirectionOffset = CFrame.new(0, 0.07, 0.1);
			LifeTime = 0.7;
			AirState = true;
		};
		
		local CombatAnim = Entity.Animator:Fetch(`Weapons/{WeaponName}/LightAttack/Light{CurrentAttack}`)
		CombatAnim:Play();
		CombatAnim:SetAttribute("Speed",WeaponData.AnimationTimes[Path])
		
		Entity._Connections.FX = CombatAnim:GetMarkerReachedSignal("FX"):Once(function()
			Entity._Connections.FX = nil

			local EffectData = {
				EffectModule = Kits.Nodes.EffectsModules.Shared.M1s;
				Func = "M1s";
			}
			Entity.VFX:FireAll(EffectData,{})
		end)
		
		task.delay(WeaponData.Timings.Endlag[Path] or 1,function()
			Entity.Character:SetActive(false);
		end)
		
		if (EnemyRoot.Position - RootPart.Position).Magnitude < 75 then
			task.spawn(function()
				local EnemyCFrame = Util.ExtrapolateMovingCFrame(EnemyRoot)
				local FinalCFrame = RootPart.CFrame.Rotation + (EnemyCFrame.Position + (RootPart.CFrame.lookVector * -1))

				local AlignPosition = Kits.Storage.BodyM.AirComboTrack:Clone()
				AlignPosition.Attachment0 = RootPart.MainAttach
				AlignPosition.Position = FinalCFrame.Position -- (eroot.CFrame * CFrame.new(0,0,-3)).Position
				AlignPosition.Parent = RootPart

				local Destroying = false
				repeat
					if not EnemyRoot or not EnemyRoot.Parent then break end
					if not RootPart or not RootPart.Parent then break end

					--if Entity.Character.Stunned then 
					if TargetEntity.Character.Rig:FindFirstChild("Stunned") then
						if AlignPosition then
							AlignPosition:Destroy()
						end
						break
					end

					if not Destroying and (RootPart.Position - EnemyRoot.Position).Magnitude < 15 then
						Destroying = true
						
						warn("Distance")

						if AlignPosition then
							task.delay(0.8, AlignPosition.Destroy, AlignPosition)
						end
					end

				--	if not OnMaxCombo then
						EnemyCFrame = Util.ExtrapolateMovingCFrame(EnemyRoot)
						FinalCFrame = RootPart.CFrame.Rotation + (EnemyCFrame.Position + (RootPart.CFrame.lookVector * -4))
						AlignPosition.Position = FinalCFrame.Position
				--	end

					task.wait()
				until AlignPosition.Parent ~= RootPart

				if AlignPosition then
					AlignPosition:Destroy()
				end
			
				Entity.Character:SetAttribute("AirComboing", nil)
				task.delay(0.8, function()
					Entity.Character:SetAttribute("CriticalBuffer", nil)
				end)
				
				task.delay(1,function()
					AerialBuffer:Destroy()
				end)
				
			end)
		end
		local HitID = (CurrentId or "").. (CurrentAttack or "");
		task.wait(WeaponData.Timings.Hitbox[Path])
		if not Entity.Server.CancelledHits[HitID] then
			Entity.Combat:Afflict(TargetEntity, {
				CancelLevel = 1;
				HitVFX = {
					Name='AirJuggle';
					Data = {
						HitOrder = CurrentAttack;
						Type = "AirJuggle",
					};
				};
				Actions = {
					Damage = {
						Amount = 4;
						--	HitReaction = CurrentAttack;
					--	Type = PunchType,
					};
					Stun = {
						Name = "AirJuggle",
						Duration = .85;
						Speed = 0;
						Jump = 0;
						
						Callback = function()
							if TargetEntity.Character.JuggleMaid then
								TargetEntity.Character.JuggleMaid:Destroy()
							end
							AirCombat:AirJuggle(Entity, TargetEntity, VelocityProperties, HitIdentity)		
						end,
					};
				};
			});
		end
		Util.ClearTable(Tags)
		Entity.StatManager:RemoveAbsolute("AirLight")
		warn("----")
	end
	
	function AirCombat:AirJuggle(Entity, TargetEntity, VelocityProperties: {}, HitIdentity: {})
		local RootPart = Entity.Character.Root
		local Target = TargetEntity.Character.Rig
		local EnemyRoot = TargetEntity.Character.Root
		local EnemyHumanoid = TargetEntity.Character.Humanoid
		
		warn("----")
		warn("Juggle Start")
		
		local TargetStunned: Boolean = false;
		local Hit = nil;

		local StunMaid = Maid.new()
		local StunTags = {}
		local StunAnimations = {}

		Entity.Character:SetAttribute("AirComboTarget",true)

		local AirComboTarget = Instance.new("ObjectValue")
		AirComboTarget.Name = "AirComboTarget"
		AirComboTarget.Parent = Entity.Character.Rig
		AirComboTarget.Value = TargetEntity.Character.Rig
		StunMaid:GiveTask(AirComboTarget)

		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Basic;
			Func = "AirCombatTag";
		}
		Entity.VFX:FireAll(EffectData,{})

		StunMaid.OnClean = function()
			warn("CLEANING JUGGLE")
			
			TargetEntity.Character.JuggleMaid = nil
			Util.ClearTable(StunTags)	

			for _, Animation: AnimationTrack in pairs(StunAnimations) do
				Animation:Stop()
			end

			if EnemyRoot and EnemyRoot.Parent then
				EnemyRoot.Anchored = false
			end

			if Target and Target.Parent then
				TargetEntity.Character:SetAttribute("AerialVelocity", nil)
				TargetEntity.Character:SetAttribute("AerialCount", nil)
				TargetEntity.Character:SetAttribute("AutoRotate",nil)
			end
			Entity.Character:SetAttribute("AirComboTarget",nil)
			StunMaid = nil
		end

		StunMaid:GiveTask(Target.AncestryChanged:Once(function()
			if Target.Parent ~= workspace.Entities then
				StunMaid:Destroy()
			end
		end))

		local Animation = TargetEntity.Animator:Fetch(`Victim/Juggle`);
		Animation.Priority = Enum.AnimationPriority.Action

		StunAnimations["TargetAnim"] = Animation
		StunAnimations["TargetAnim"]:Play()

		StunMaid:GiveTask(StunAnimations["TargetAnim"]:GetMarkerReachedSignal("BeginSlow"):Connect(function() 
			StunAnimations["TargetAnim"]:SetAttribute("Speed",0.8)
		end))

		StunMaid:GiveTask(StunAnimations["TargetAnim"]:GetMarkerReachedSignal("Pause"):Connect(function()
			StunAnimations["TargetAnim"]:SetAttribute("Speed",0)
		end))
		
		TargetEntity.Character:SetAttribute("AutoRotate",true)
		if VelocityProperties.AirState then
			Util.TagAdd(StunTags, Target, "InAirState")
		end

		Util.TagAdd(StunTags, Target, "CombatDisable")
		Util.TagAdd(StunTags, Target, "Stunned")
		local AerialState = Util.TagAdd(StunTags, Target, "AerialState")
		
		local AerialCount = 1
	
		local InitiateVelocity = function()
			-- // Orient Target to Player
			local KnockbackPosition: Vector3 = Vector3.new(RootPart.Position.X, EnemyRoot.Position.Y, RootPart.Position.Z)
			local NewCF: CFrame = CFrame.new(EnemyRoot.Position, KnockbackPosition)
			local EndCFrame: CFrame = VelocityProperties.EndCFrame or CFrame.new(EnemyRoot.Position, EnemyRoot.Position + Vector3.new(NewCF.LookVector.X, 0, NewCF.LookVector.Z))

			--if VelocityProperties.InFront then
			--	EnemyRoot.CFrame = RootPart.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(180), 0)
			--end

			local Offset: CFrame do
				--Offset = VelocityProperties.SecondOffset or CFrame.new(0, -1.5 * 0.5, 0)
				-- First One == 2 because we increment above.
				if AerialCount == 2 then
					Offset = VelocityProperties.FirstOffset or CFrame.new(0, 0, 0)
				else
					Offset = VelocityProperties.SecondOffset or CFrame.new(0, -1.5 * AerialCount, 0)
				end
			end
			local FaceOffsetCF: CFrame = EndCFrame * Offset
			-- // CFrame Velocity
			local DirectionOffset: CFrame = VelocityProperties.DirectionOffset or CFrame.new(0, 2, 0.9) -- 0.7
			local DirectionCF: CFrame = FaceOffsetCF * DirectionOffset
			DirectionCF = CFrame.new(FaceOffsetCF.Position, DirectionCF.Position)

			local Direction: Vector3 = DirectionCF.LookVector
			local Gravity: Number = (VelocityProperties.Gravity or 145) 
			local Velocity = Direction * (VelocityProperties.Velocity or 45)

			EnemyRoot.Anchored = true
			EnemyRoot.CFrame = DirectionCF
			local LastPosition: Vector3 = DirectionCF.Position
--[[
			EffectsRemote:FireAllClients((args.SubRegen and "SkillHit") or VelocityProperties.VFX or "VelocityJuggleHit", {
				Root = EnemyRoot;
				AirState = VelocityProperties.AirState;
			})
]]			
			return LastPosition, Gravity, Velocity
		end

		StunMaid:GiveTask(AerialState.AncestryChanged:Once(function()
			if not AerialState.Parent then
				TargetStunned = true
				StunMaid:Destroy()
			end
		end))

		local LastPosition: Vector3, Gravity: Number, Velocity: Number = InitiateVelocity()

		task.delay(VelocityProperties.LifeTime or VelocityProperties.stuntime or 3, function()
			if StunMaid then StunMaid:Destroy() end
		end)

		local Connection; 
		local RayParams = Auxiliary.Shared.RayParams.Map

		local FloorBuffer = 0.6
		local StartTick = tick()

		StunMaid:GiveTask(RunService.Heartbeat:Connect(function(Delta)
			LastPosition = EnemyRoot.Position
			Velocity = Velocity - Vector3.new(0, Gravity * Delta, 0)

			-- // Velocity Check
			local CurrentPosition = Util.ExtrapolateMovingCFrame(EnemyRoot).Position
			local Move = Velocity * Delta
			local MoveMag = Move.Magnitude
			local TargetPos = CurrentPosition + Move

			Hit = Util.Raycast(CurrentPosition, Move.Unit, MoveMag, RayParams)
			if Hit then
				StunMaid:Destroy()
				return
			else
				-- // Floor Check
				local FloorHit = Util.Raycast(TargetPos + Vector3.new(0, 2, 0), Vector3.new(0, -1, 0), 6, RayParams)
				if FloorHit then --and StartTick + FloorBuffer < tick() then
					local FloorY = FloorHit.Position.Y
					-- keep a small hover so we don't clip
					local MinY = FloorY + 1.2
					if TargetPos.Y < MinY then
						TargetPos = Vector3.new(TargetPos.X, MinY, TargetPos.Z)
					end
				end

				-- // Before Velocity Direction
				local NewPosition: Vector3 = EnemyRoot.Position + (Velocity * Delta)
				local LookDirection: Vector3 = Velocity.Unit
				local NewCF: CFrame = CFrame.lookAt(NewPosition, NewPosition + LookDirection)
				local StartCF = NewCF * CFrame.new(0,0,3) -- Start behind

				Hit = Util.Raycast(StartCF.Position, NewCF.LookVector, 5, RayParams)
				if Hit and StartTick + FloorBuffer < tick()then
					warn("BUFFER")
					StunMaid:Destroy()
					return
				else
					EnemyRoot.CFrame = NewCF * CFrame.Angles(0, math.rad(180), 0)
				end
			end
		end))
		
		TargetEntity.Character.JuggleMaid = StunMaid
		warn("JUGGLE MAID SET")
		warn("----")
	end

	return AirCombat 
end