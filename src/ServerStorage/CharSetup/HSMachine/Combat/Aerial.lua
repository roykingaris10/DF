--State// Idle
return function(Client)
	local State = {}
	local player = Client.player
	local Network = Client.Network
	local Entity = Client.Entity
	local Util = Client.Utilities
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local HTTPService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local Maid = require(Nodes.Utility.Maid)
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	
	local function checkInAir()
		if ((Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping)) and Entity.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
			return false
		else
			return true
		end
	end
	
	local CheckTable = {"AerialBuffer"}
	
	State["Attack"] = function(self,Params: {})
		local Character = player.Character;
		local WeaponName = Entity.Character:GetAttribute("CurrentEquippedWeapon") or "Fists"
		local WeaponData = Client.WeaponData[WeaponName]
		if not WeaponData then return end

		if Entity.CombatData.CurrentlyAttacking or Entity.CombatData.AerialCooldown or Entity.CombatData.Dashing 
			or Entity.CombatData.Blocking or Entity.Cooldowns.cooldownData["Aerial"] then return end
		if Entity.Character:GetAttribute("Active") or Entity.Character:GetAttribute("Blocking") 
			or Entity.Character:GetAttribute("Stunned") or Entity.Character:GetAttribute("AttackBuffer") 
			or Util.CheckTags(CheckTable,Character)then return end
		Entity:SetState("CurrentlyAttacking",true)
		Entity:SetState("Aerial",true)
		
		local RootPart: BasePart = Character:WaitForChild('HumanoidRootPart')
		local Humanoid: Humanoid = Character:FindFirstChildOfClass('Humanoid')
		
		local Type = "Aerial"
		
		local AttackMaid = Maid.new()
		local AttackTags = {}
		local AttackAnimations = {}
		
		AttackMaid.OnClean = function()
			warn("CLEANING AERIALCLIENT")
			Util.ClearTable(AttackTags)	

			for _, Animation: AnimationTrack in pairs(AttackAnimations) do
				Animation:Stop(0.4)
			end

			if Character and Character.Parent then
			end
			Entity:SetState("Aerial",nil)
			Entity:SetState("CurrentlyAttacking",false)
			Entity.CombatData.AerialCooldown = true
			task.delay(WeaponData.AerialCooldown, function() Entity.CombatData.AerialCooldown = false end)
			
		end
		
		local BeginTick = tick()

		local HitIdentity = {
			CurrentWeapon = "Fists"; --Change later to adapt to multiple weapons
			AttackType = Type;
			CurrentId = "Aerial";
			InAir = checkInAir();
			Timestamp = tick();
		}
		
		Client.PacketLinks["Aerial"]:Fire(HitIdentity)
		
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.Aerials;
			Func = "AerialIndicator";
		}
		Client.PacketLinks["ClientEffectsAll"]:Fire(EffectData,{})
		
		local Animation = Entity.AnimHandler:Fetch(`Weapons/{WeaponName}/Aerial`);

		Animation.Priority = Enum.AnimationPriority.Action
		Animation:Play();
		Animation:SetAttribute("Speed",WeaponData.AnimationTimes.Aerial)
		AttackAnimations["Aerial"] = Animation

		local Speed = 40
		
		AttackMaid:GiveTask(AttackAnimations["Aerial"]:GetMarkerReachedSignal("Slow"):Connect(function()
			Speed = 7
		end))
		
		local AerialVelocity = CombatUtility:BVPlacer(RootPart,{
			Name = "AerialVelocity";
			MaxForce = Vector3.new(3e5, 0, 3e5),
		})
		Client.Debris:AddItem(AerialVelocity,Animation.Length*WeaponData.AnimationTimes.Aerial or 1)
		
		AttackMaid:GiveTask(AerialVelocity.AncestryChanged:Connect(function()
			if not AerialVelocity or not AerialVelocity.Parent then
				AttackMaid:Destroy()
			end
		end))
		
		Entity._Connections.FX = Animation:GetMarkerReachedSignal("FX"):Once(function()
			Entity._Connections.FX = nil

			local EffectData = {
				EffectModule = Kits.Nodes.EffectsModules.Shared.Aerials;
				Func = "Aerial";
			}
			Client.PacketLinks["ClientEffectsAll"]:Fire(EffectData,{})
		end)
		
		AttackMaid:GiveTask(RunService.RenderStepped:Connect(function()
			if not Animation.IsPlaying then
				AttackMaid:Destroy()
				return
			end
			AerialVelocity.Velocity = RootPart.CFrame.LookVector * Speed
		end))
		
		task.spawn(function() -- Early Clash Check
			Client.Entity.RunTime:Wait(WeaponData.Timings.Hitbox[Type]*0.65)
			Client.PacketLinks["RegisterHeavyClash"]:Fire({HitIdentity = HitIdentity})
		end)
		
		task.spawn(function()
			Client.Entity.RunTime:Wait(WeaponData.Timings.Hitbox[Type]*WeaponData.AnimationTimes.Aerial or 1)
			local Range = WeaponData.AerialRange or 6
			local hitboxParams = {
				SizeOrPart = Vector3.new(5.5,7,Range);
				InitialPosition = Entity.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-Range/2);
				DebounceTime = WeaponData.Timings.Duration.Aerial+0.2;
				Debris = WeaponData.Timings.Duration.Aerial;
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
			Entity.MovementHandler:SetAbsolute("Aerial", {
				WalkSpeed = 8,
				JumpPower = 0,
				Priority = 4
			},Duration)

			Entity:SetState("RunBuffer",true)
			task.spawn(function()
				Client.Entity.RunTime:Wait(Duration+0.10)
				Entity:SetState("RunBuffer",false)
			end)
			
			local StartTime = tick()
			
			repeat 
				Client.Entity.RunTime:Wait(0.01)
				newHitbox:SetPosition(Entity.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-Range/2) )
			until StartTime + WeaponData.Timings.Duration.Aerial < tick() 
		end)

		task.spawn(function()
			Client.Entity.RunTime:Wait(WeaponData.Timings.Endlag[Type])
			if Entity._Connections.FX then
				Entity._Connections.FX:Disconnect()
				Entity._Connections.FX = nil
			end
		end)
		
		Animation.Stopped:Wait()
		AttackMaid:Destroy()
		return true
	end
	
return State end
