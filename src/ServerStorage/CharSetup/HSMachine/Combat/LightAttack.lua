--State// Idle
return function(Client)
	local State = {}
	local player = Client.player
	local Network = Client.Network
	local Entity = Client.Entity
	
	local HttpService = game:GetService("HttpService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	
	State["StartAttackLoop"] = function(self,Params: {})
		Entity.CombatData.LightAttackLoop = true
		Entity.StateMachine:ChangeState("Combat","LightAttack")
		Entity.StateMachine:Trigger("Combat","Attack")
	end
	
	local function uptiltCheck()
		if Entity.Character.Humanoid.FloorMaterial ~= Enum.Material.Air and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) 
			and not Entity.Cooldowns.cooldownData["Uptilt"] 
			and ((Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping)) then
			return true 
		end
		return false
	end
	
	local function checkInAir()
		if ((Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping)) and Entity.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
			return false
		else
			return true
		end
	end
	
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
	
	State["Attack"] = function(self,Params: {})
		local Character = player.Character;
		local WeaponName = Entity.Character:GetAttribute("CurrentEquippedWeapon") or "Fists"
		local WeaponData = Client.WeaponData[WeaponName]
		if not WeaponData then return end
		if Entity.CombatData.CurrentlyAttacking or Entity.CombatData.comboCooldown or Entity.CombatData.Dashing 
		or Entity.CombatData.Blocking then return end
		if Entity.Character:GetAttribute("Active") or Entity.Character:GetAttribute("Blocking") or Entity.Character:GetAttribute("Stunned") or Entity.Character:GetAttribute("AttackBuffer")then return end
		Entity:SetState("CurrentlyAttacking",true)
		
		local AirComboTarget = Character:FindFirstChild("AirComboTarget")
		if AirComboTarget and AirComboTarget.Value and Character:GetAttribute("AirComboTarget") then

			local TargetRoot = AirComboTarget.Value:FindFirstChild("HumanoidRootPart")
			if not TargetRoot then return end
			if AreFacingWithinAngle(TargetRoot.CFrame, Character.HumanoidRootPart.CFrame, 60) and (TargetRoot.Position-Character.HumanoidRootPart.Position).Magnitude < 15 then
				State["Air"](self,Params,AirComboTarget.Value)
				return
			end
			
		end
		
		if not (tick()-Entity.CombatData.lastTick < WeaponData.ResetComboTimer) then Entity.CombatData.ComboNum = 1 end
		local initCombo = Entity.CombatData.ComboNum
		Entity.CombatData.ComboNum = Entity.CombatData.ComboNum + 1

		local Type = "Light"
		
		local function ResetPunch()
			Entity.Character:SetAttribute('CurrentAttack', 0);
			Entity.Character:SetAttribute('PunchId', HttpService:GenerateGUID(false));
		end;
		
		if not Entity.Character:GetAttribute('CurrentAttack') then
			ResetPunch();
		end;
		
		local BeginTick = tick()
		
		Entity.Character:SetAttribute('CurrentAttack', Entity.Character:GetAttribute('CurrentAttack')+1);
		local CurrentAttack = Entity.Character:GetAttribute('CurrentAttack');
		local CurrentId = Entity.Character:GetAttribute('PunchId');
		
		local HitIdentity = {
			CurrentWeapon = "Fists"; --Change later to adapt to multiple weapons
			AttackType = Type;
			CurrentAttack = initCombo;
			CurrentId = Entity.Character:GetAttribute('PunchId');
			InAir = checkInAir();
		}
		
		Client.PacketLinks["LightAttack"]:Fire(HitIdentity)
		
		task.spawn(function()
			Client.Entity.RunTime:Wait(1.5)
			if Entity.Character:GetAttribute('CurrentAttack') == initCombo and Entity.Character:GetAttribute('PunchId') == CurrentId then
				ResetPunch();
			end;
		end);
	
		local combatState
		local AnimPath
		if uptiltCheck() then
			--Entity:SetState("Uptilt",true)
			combatState = "Uptilt"
			HitIdentity.AttackType = "Uptilt"
			Entity.Cooldowns:Add("Uptilt",2);
			AnimPath = `Weapons/{WeaponName}/Uptilt`
		elseif initCombo == WeaponData.ComboMax then
			if HitIdentity.InAir and Entity.Character:GetAttribute("AirComboOption") and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				combatState = "Airpush"
				HitIdentity.AttackType = "Airpush"
				AnimPath = `Weapons/{WeaponName}/Airpush`
			elseif HitIdentity.InAir and Entity.Character:GetAttribute("AirComboOption") then
				combatState = "Downslam"
				HitIdentity.AttackType = "Downslam"
				AnimPath = `Weapons/{WeaponName}/Downslam`
			else
				combatState = "Light"..initCombo
				AnimPath = `Weapons/{WeaponName}/LightAttack/Light{initCombo}`
			end
		else
			combatState = "Light"..initCombo
			AnimPath = `Weapons/{WeaponName}/LightAttack/Light{initCombo}`
		end
		
		local Animation = Entity.AnimHandler:Fetch(AnimPath);
		Animation.Priority = Enum.AnimationPriority.Action
		Animation:Play();
		Animation:SetAttribute("Speed",WeaponData.AnimationTimes[combatState])

		Entity._Connections.FX = Animation:GetMarkerReachedSignal("FX"):Once(function()
			Entity._Connections.FX = nil
			
			local EffectData = {
				EffectModule = Kits.Nodes.EffectsModules.Shared.M1s;
				Func = "M1s";
			}
			Client.PacketLinks["ClientEffectsAll"]:Fire(EffectData,{})

		end)
		
		task.spawn(function()
			Client.Entity.RunTime:Wait(WeaponData.Timings.Hitbox[combatState])
			local Range  = WeaponData.Range or 6
			local hitboxParams = {
				SizeOrPart = Vector3.new(5,5,Range),
				InitialPosition = Entity.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-Range/2);
				DebounceTime = 0.8;
				Debris = 0.1;
				--				UseClient = player;
				Blacklist = {Entity.Character};
				Debug = true,
			} :: HitboxTypes.HitboxParams

			local newHitbox, connected = Client.HitboxClass.new(hitboxParams)
			newHitbox.HitSomeone:Connect(function(hitChars)
				local Resp; 
				task.spawn(function()
					if combatState == "Uptilt" then
						local distance, char = CombatUtility:getFarthestCharacter(Entity.Character.HumanoidRootPart,hitChars)
						hitChars = {char}
						--[[
						local EffectData = {
							EffectModule = Kits.Nodes.EffectsModules.Shared.M1s;
							Func = "HitStop";
							Caster= Client.EffectsClient.GetMockEntity(player)
						}
						]]
				--		Client.EffectsClient:Execute(EffectData,{})
					end
					Client.PacketLinks["RegisterHit"]:Fire({HitChars = hitChars, HitIdentity = HitIdentity})
				--	Resp = Network:post('RegisterHit', {DetectedChar = DetectedChar, Punch = PunchIdentity}, true);
				end)
			end)

			newHitbox:Start()
			local Duration = Animation.Length
			Entity.MovementHandler:SetAbsolute("LightAttack", {
				WalkSpeed = 9,
				JumpPower = 0,
				Priority = 4
			},Duration)
			
			Entity:SetState("RunBuffer",true)
			task.spawn(function()
				Client.Entity.RunTime:Wait(Duration+0.075)
				Entity:SetState("RunBuffer",false)
			end)
		end)
		
		task.spawn(function()
			Client.Entity.RunTime:Wait(WeaponData.Timings.Endlag[combatState])
			if Entity._Connections.FX then
				Entity._Connections.FX:Disconnect()
				Entity._Connections.FX = nil
			end
			
			State["ReleaseAttack"](self,Params)
		end)
		
		Entity.CombatData.lastTick = tick()
		
		if Entity.CombatData.ComboNum > WeaponData.ComboMax then
			Entity.CombatData.ComboNum = 1
			Entity.CombatData.comboCooldown = true
			ResetPunch();
			task.delay(WeaponData.ComboCooldown,function() Entity.CombatData.comboCooldown = false end)
		end
		
	end
	
	State["ReleaseAttack"] = function(self,Params: {})
		Entity:SetState("CurrentlyAttacking",false)
		if Entity.CombatData.LightAttackLoop and not Entity.CombatData.CurrentlyAttacking then
			
		else
			--Profile:ResetCharacterBase()
			--Profile:ResumeSprinting()
		end
	end
	
	State["Air"] = function(self,Params: {},AirTarget: Object)
		local Character = player.Character;
		local WeaponName = Entity.Character:GetAttribute("CurrentEquippedWeapon") or "Fists"
		local WeaponData = Client.WeaponData[WeaponName]
		if not WeaponData then return end
		--[[
		local AnimPath = `Weapons/{WeaponName}/Downslam`
		
		local Animation = Entity.AnimHandler:Fetch(AnimPath);
		Animation.Priority = Enum.AnimationPriority.Action
		Animation:Play();
		Animation:AdjustSpeed(WeaponData.AnimationTimes["AirStartCritical"] or 1)
]]
		print("air light client")
		if not (tick()-Entity.CombatData.lastAirTick < WeaponData.ResetComboTimer) then Entity.CombatData.AirComboNum = 1 end
		local initCombo = Entity.CombatData.AirComboNum
		Entity.CombatData.AirComboNum = Entity.CombatData.AirComboNum + 1
		print(Entity.CombatData.AirComboNum)
		local Type = "Light"

		local function ResetPunch()
			Entity.Character:SetAttribute('CurrentAirAttack', 0);
			Entity.Character:SetAttribute('AirLightId', HttpService:GenerateGUID(false));
		end;

		if not Entity.Character:GetAttribute('CurrentAirAttack') then
			ResetPunch();
		end;
		
		Entity.Character:SetAttribute('CurrentAirAttack', Entity.Character:GetAttribute('CurrentAirAttack')+1);
		local CurrentAttack = Entity.Character:GetAttribute('CurrentAirAttack');
		local CurrentId = Entity.Character:GetAttribute('AirLightId');
		
		local HitIdentity = {
			CurrentWeapon = "Fists"; --Change later to adapt to multiple weapons
			AttackType = Type;
			CurrentAirAttack = initCombo;
			CurrentId = Entity.Character:GetAttribute('AirLightId');
			InAir = checkInAir();
		}

		Network:post("ServerEvent","AirLightHit",WeaponName,AirTarget,HitIdentity)
		local combatState = "Light"..initCombo
		task.spawn(function()
			Client.Entity.RunTime:Wait(WeaponData.Timings.Endlag[combatState])
			Entity:SetState("CurrentlyAttacking",false)
		end)
		
		Entity.CombatData.lastAirTick = tick()
		
		if Entity.CombatData.AirComboNum > WeaponData.ComboMax then
			Entity.CombatData.AirComboNum = 1
			Entity.CombatData.comboCooldown = true
			ResetPunch();
			task.spawn(function()Client.Entity.RunTime:Wait(WeaponData.ComboCooldown) Entity.CombatData.comboCooldown = false end)
		end
		
	end

return State end
