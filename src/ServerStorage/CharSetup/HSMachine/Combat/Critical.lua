--State// Idle
return function(Client)
	local State = {}
	local player = Client.player
	local Network = Client.Network
	local Entity = Client.Entity
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local HTTPService = game:GetService("HttpService")
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local function checkInAir()
		if ((Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping)) and Entity.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
			return false
		else
			return true
		end
	end
	
	State["Attack"] = function(self,Params: {})
		local Character = player.Character;
		local WeaponName = Entity.Character:GetAttribute("CurrentEquippedWeapon") or "Fists"
		local WeaponData = Client.WeaponData[WeaponName]
		if not WeaponData then return end

		if Entity.CombatData.CurrentlyAttacking or Entity.CombatData.HeavyCooldown or Entity.CombatData.Dashing 
			or Entity.CombatData.Blocking or Entity.Cooldowns.cooldownData["Critical"] then return end
		if Entity.Character:GetAttribute("Active") or Entity.Character:GetAttribute("Blocking") or Entity.Character:GetAttribute("Stunned")
			or Entity.Character:GetAttribute("AttackBuffer") or Entity.Character:GetAttribute("AirComboing") or Entity.Character:GetAttribute("CriticalBuffer") then return end
		Entity:SetState("CurrentlyAttacking",true)
		
		local AirComboTarget = Character:FindFirstChild("AirComboTarget")
		if AirComboTarget and AirComboTarget.Value and Character:GetAttribute("AirComboTarget") and Character:GetAttribute("AirEngage") then
			State["Air"](self,Params,AirComboTarget.Value)
			return
		end
		
		local Type = "Critical"
		
		local BeginTick = tick()

		local HitIdentity = {
			CurrentWeapon = "Fists"; --Change later to adapt to multiple weapons
			AttackType = Type;
			CurrentId = "Critical";
			InAir = checkInAir();
			Timestamp = tick();
		}
		
		Client.PacketLinks["Critical"]:Fire(HitIdentity)
		
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Criticals;
			Func = "CritIndicator";
		}
		Client.PacketLinks["ClientEffectsAll"]:Fire(EffectData,{})
		
		local Animation = Entity.AnimHandler:Fetch(`Weapons/{WeaponName}/Critical`);

		Animation.Priority = Enum.AnimationPriority.Action
		Animation:Play();
		Animation:SetAttribute("Speed",WeaponData.AnimationTimes.Critical or 1)
		
		Entity._Connections.FX = Animation:GetMarkerReachedSignal("FX"):Once(function()
			Entity._Connections.FX = nil

			local EffectData = {
				EffectModule = Kits.Nodes.EffectsModules.Shared.Criticals;
				Func = "Critical";
			}
			Client.PacketLinks["ClientEffectsAll"]:Fire(EffectData,{})
		end)
		
	--	Animation:AdjustWeight()
	
		task.spawn(function() -- Early Clash Check
			Client.Entity.RunTime:Wait(WeaponData.Timings.Hitbox[Type]*0.65)
			print("early clash check")
	--[[	local Range = WeaponData.CriticalRange or 6
			local hitboxParams = {
				SizeOrPart = Vector3.new(5,5,Range),
				InitialPosition = Entity.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-Range/2);
				DebounceTime = 0.8;
				Debris = 0.1;
				--				UseClient = player;
				Blacklist = {Entity.Character};
				--	Debug = true,
			} :: HitboxTypes.HitboxParams

			local newHitbox, connected = Client.HitboxClass.new(hitboxParams)
			newHitbox.HitSomeone:Connect(function(hitChars)
				local Resp; 
				task.spawn(function()
					print("wagagla")
					Client.PacketLinks["RegisterHeavyClash"]:Fire({HitChars = hitChars, HitIdentity = HitIdentity})
					--	Resp = Network:post('RegisterHit', {DetectedChar = DetectedChar, Punch = PunchIdentity}, true);
				end)
			end)
			
			newHitbox:Start()
			]]
			Client.PacketLinks["RegisterHeavyClash"]:Fire({HitIdentity = HitIdentity})
		end)
		
		task.spawn(function()
			Client.Entity.RunTime:Wait(WeaponData.Timings.Hitbox[Type])
			local Range = WeaponData.CriticalRange or 6
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
					
					Client.PacketLinks["CriticalHit"]:Fire({HitChars = hitChars, HitIdentity = HitIdentity})
					--	Resp = Network:post('RegisterHit', {DetectedChar = DetectedChar, Punch = PunchIdentity}, true);
				end)
			end)

			newHitbox:Start()
			local Duration = Animation.Length
			Entity.MovementHandler:SetAbsolute("Critical", {
				WalkSpeed = 8,
				JumpPower = 0,
				Priority = 4
			},Duration)
 
			Entity:SetState("RunBuffer",true)
			task.spawn(function()
				Client.Entity.RunTime:Wait(Duration+0.10)
				Entity:SetState("RunBuffer",false)
			end)
		end)

		task.spawn(function()
			Client.Entity.RunTime:Wait(WeaponData.Timings.Endlag[Type])
			if Entity._Connections.FX then
				Entity._Connections.FX:Disconnect()
				Entity._Connections.FX = nil
			end

		end)
		
		Animation.Stopped:Wait()
		Entity:SetState("CurrentlyAttacking",false)
		Entity.CombatData.HeavyCooldown = true
		task.delay(WeaponData.HeavyCooldown, function() Entity.CombatData.HeavyCooldown = false end)
		return true
	end

	State["Air"] = function(self, Params: {}, AirTarget)
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
		Network:post("ServerEvent","AirStartCritical",WeaponName,AirTarget)
		Client.Entity.RunTime:Wait(0.2)
		Entity:SetState("CurrentlyAttacking",false)
	end
	
return State end
