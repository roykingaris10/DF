return function(Server)
	
	local LibraryInfo = Server.LibraryInfo

	local Network = {}
	return {
		LightAttack = function(Player, Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Combat","LightAttack"}
			Profile.ActionManager:StartAction(ActionPathing,Params)
		end,
		Aerial = function(Player, Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Combat","Aerial"}
			Profile.ActionManager:StartAction(ActionPathing,Params)
		end,
		Critical = function(Player, Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Combat","Critical"}
			Profile.ActionManager:StartAction(ActionPathing,Params)
		end,
		Parry = function(Player, Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Combat","Parry"}
			Profile.ActionManager:StartAction(ActionPathing,Params)
		end,
		Block = function(Player, Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Combat","Block"}
			Profile.ActionManager:StartAction(ActionPathing,Params)
		end,
		CriticalHit = function(Player, Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			local DetectedChars = Params.HitChars
	--		Profile.Combat.HeavyTime = Params.Timestamp;
	--		Profile.Combat:RegisterClash(Params.HitIdentity, DetectedChars)
			for i, char in DetectedChars do
				local HitEntity = Server.EntityService.Find(char);
				if not HitEntity then continue end
				if (Profile.Character.Root.Position - HitEntity.Character.Root.Position).Magnitude > 15 then continue end

				Profile.Combat:RegisterHit(HitEntity, Params.HitIdentity)
			end
		end,
		RegisterHeavyClash = function(Player, Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			local DetectedChars = Params.HitChars
			Profile.Combat.HeavyTime = Params.Timestamp;
			local WeaponData = Server.WeaponData[Profile.EquippedWeapon]
	--		Params.HitIdentity.ClashWindow = WeaponData.HeavyClashWindow
			Profile.Combat:RegisterClash(Params.HitIdentity, DetectedChars)
			Profile.RunTime:Wait(WeaponData[Params.HitIdentity.AttackType.."ClashWindow"])
		--	task.wait(WeaponData[Params.HitIdentity.AttackType.."ClashWindow"])
			Profile.Combat:UnregisterClash()
		end,
		AirStartCritical = function(Player, WeaponName, AirTarget)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			local AirComboTarget = Profile.Character.Rig:FindFirstChild("AirComboTarget")
			if AirComboTarget and AirComboTarget.Value and Profile.Character.Rig:GetAttribute("AirComboTarget") then
				if  AirComboTarget.Value == AirTarget then
					local HitEntity = Server.EntityService.Find(AirTarget);
					if not HitEntity then return end
					if (Profile.Character.Root.Position - HitEntity.Character.Root.Position).Magnitude > 50 then return end
					Profile.Combat:AirStartCritical(HitEntity)
				end
			end
		end,
		AirLightHit = function(Player, WeaponName, AirTarget, HitIdentity)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end

			local AirComboTarget = Profile.Character.Rig:FindFirstChild("AirComboTarget")
			if AirComboTarget and AirComboTarget.Value and Profile.Character.Rig:GetAttribute("AirComboTarget") then
				if  AirComboTarget.Value == AirTarget then
					local HitEntity = Server.EntityService.Find(AirTarget);
					if not HitEntity then return end
					if (Profile.Character.Root.Position - HitEntity.Character.Root.Position).Magnitude > 50 then return end
					Profile.Combat:AirLightHit(HitEntity,HitIdentity)
				end
			end
		end,
		RegisterHit = function(Player, Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			
			local DetectedChars = Params.HitChars
			if Params.HitIdentity.InAir and Profile.Character:GetAttribute("AirComboOption") then
				for i, char in DetectedChars do
					local HitEntity = Server.EntityService.Find(char);
					if not HitEntity then continue end
					
					if (Profile.Character.Root.Position - HitEntity.Character.Root.Position).Magnitude > 15 then continue end
					if HitEntity.Combat.UptiltData.Uptilter == Profile.Character.Rig then
						
					Profile.Combat:RegisterHit(HitEntity, Params.HitIdentity, true)
						
						return 
					end
				end
			end
			
			for i, char in DetectedChars do
				local HitEntity = Server.EntityService.Find(char);
				if not HitEntity then continue end
				if (Profile.Character.Root.Position - HitEntity.Character.Root.Position).Magnitude > 15 then continue end
				
				
				Profile.Combat:RegisterHit(HitEntity, Params.HitIdentity)
			end
		end,
		CheckUptilt = function(Player, HitChars)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			
			print("MAKING IT HERE")
			for i, char in HitChars do
				local HitEntity = Server.EntityService.Find(char);
				if not HitEntity then continue end
				print((Profile.Character.Root.Position - HitEntity.Character.Root.Position).Magnitude)
				if (Profile.Character.Root.Position - HitEntity.Character.Root.Position).Magnitude > 25 then continue end
				if HitEntity.Combat.UptiltData.Uptilter == Profile.Character.Rig then
				--	Profile.Combat:ApplyAirHit(HitEntity,"Engage")
					Profile.Combat:AirJuggle(HitEntity,"Engage")
					break
				end
			end
		end,
		WillActivate = function(Player)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Combat","Will"}
			Profile.ActionManager:StartAction(ActionPathing,{})
		end,
		WillEvasive = function(Player,Params)
			local Profile = Server.EntityService.Find(Player);
			if not Profile and Player then
				Player:Kick("Missing Profile?")
			end
			local ActionPathing = {"Combat","WillEvasive"}
			Profile.ActionManager:StartAction(ActionPathing,Params)
		end,

	} end