return function(Server)

	local Utilities = Server.Utilities
	local Network = Server.Network
	local LibraryInfo = Server.LibraryInfo

	local Debris = game:GetService("Debris")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local GameSettings = require(Nodes.Data.GameSettings);
	local Maid = require(Nodes.Utility.Maid)
	local Auxiliary = require(Nodes.Utility.Auxiliary)
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)

	local Action = {}
	Action.__index = Action

	function Action.new(Entity)
		local self = setmetatable({}, Action)
		self.Entity = Entity
		self.Character = Entity.Character
		self.Maid = Maid.new()
		self.Checks = {"Active","Ragdoll","Stunned","Dashing","Cooldown","CombatDisable","AttackBuffer"}
		return self
	end

	function Action:Start(Data)
		if not self.Entity.ActionManager.Validator.Check(self.Entity,"LightAttack",self.Checks) then return end

		if self.Entity.Server.LastLightAttack then
			if tick()-self.Entity.Server.LastLightAttack < .01 then return end;
		end;

		self.Character:SetActive(true);
		self.Character:SetAttribute("BlockBuffer" ,true)
		self.Entity.Server.LastLightAttack = tick();

		local function ResetPunch()
			self.Character:SetCurrentAttack(0);
			self.Character.PunchIdentifier = HttpService:GenerateGUID(false);
		end;

		local CurrentAttack;
		local CurrentId;
		if not self.Entity.player then
			if not self.Character.CurrentAttack then
				ResetPunch();
			end;

			self.Character:SetCurrentAttack(self.Character.CurrentAttack+1);
			CurrentAttack = tonumber(self.Character.CurrentAttack);
			CurrentId = self.Character.PunchIdentifier;
		else
			CurrentAttack = Data.CurrentAttack;
			CurrentId = Data.CurrentId;
		end;

		local Proceed = false;
		local FinalAction;
		if Data then
			FinalAction = Data.FinalAction;
		end;
		
		Data.CurrentWeapon = Data.CurrentWeapon or self.Entity.EquippedWeapon or "Fists"

		local PunchIdentity = {
			AttackType = "Light";
			CurrentWeapon = Data.CurrentWeapon;
			CurrentAttack=CurrentAttack;
			CurrentId=CurrentId;
			FinalAction=FinalAction;
		};
		
		local WeaponData = Server.WeaponData[Data.CurrentWeapon] or Server.WeaponData["Fists"]
		
		local ClientResponded = false;
		local CalledClient;
		
		local function checkInAir()
			if ((self.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and self.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping)) and self.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				return false
			else
				return true
			end
		end

		if not self.Entity.player then
			PunchIdentity.InAir = checkInAir();
			task.spawn(function()
				self.Entity.RunTime:Wait(WeaponData.ResetComboTimer)
				if self.Character.CurrentAttack == CurrentAttack and self.Character.PunchIdentifier == CurrentId then
					ResetPunch();
				end;
			end);
		end;
		
		

		local PlayingAnim;
		local Anim, AnimPath =  Auxiliary.Shared.GetLightAnimation(self.Entity.Animator, CurrentAttack, Data.CurrentWeapon, self.Character);
		if not self.Entity.player then
			PlayingAnim = Auxiliary.Shared.GetLightAnimation(self.Entity.Animator, CurrentAttack, Data.CurrentWeapon, self.Character);
			PlayingAnim:Play()
			PlayingAnim:SetAttribute("Speed",WeaponData.AnimationTimes["Light"..CurrentAttack])
		--	PlayingAnim = Auxiliary.Shared.GetLightAnimation(self.Animator, CurrentAttack, FinalAction, self.Data.Character, self.Character, true);
		end
		
--[[
		if not self.Character.Awakened then
			self.VFX:Fire('General/Hit', 'LightThrow', {
				FinalAction=FinalAction;
				HitOrder=CurrentAttack;	
			}, 80);
		else
			--	self.VFX:Fire(tostring(self.Character.Root.Parent:GetAttribute('PlayingCharacter'))..'/Hit', 'AwakeningLight', {FinalAction = FinalAction, CurrentAttack = CurrentAttack});
		end
]]		

		if not self.Entity.player then
			self.Entity.StatManager:SetAbsolute("Critical", {
				WalkSpeed = 9,
				JumpPower = 0,
				Priority = 4,
				Duration = PlayingAnim.Length/PlayingAnim:GetAttribute("Speed"),
			})
		end
	--[[
		if FinalAction then
			self.Entity.Combat:ChangeMobility({
				Duration = .4;
				Speed = 0;
				Jump = 0;
				Disabling = true;
			});
		end;
]]
		if CurrentAttack < WeaponData.ComboMax then
			local CD
			if Anim.Length == 0 then
				CD = 1
			else
				CD = WeaponData.Timings.Endlag["Light"..CurrentAttack]--Anim.Length/WeaponData.AnimationTimes["Light"..CurrentAttack]
			end
			self.Entity.Cooldowns:Set(script.Name, CD);
		else
			self.Entity.Cooldowns:Set(script.Name, WeaponData.ComboCooldown);
			ResetPunch();
		end;
		
		local ServerDelay = WeaponData.Timings.Hitbox["Light"..CurrentAttack]
		--[[
		if typeof(ServerDelay) == 'table' then
			if not FinalAction then
				ServerDelay = ServerDelay.Normal;
			else
				ServerDelay = ServerDelay[FinalAction];
			end;
		end;
]]		
		
		local NewDelay = task.delay(ServerDelay, function()
			Proceed = true;
		end);

		local NewCancel = self.Entity.Combat:CreateCancel(1, function()
			self.Entity.Server.CancelledHits[CurrentId..CurrentAttack or ""] = true;
			Proceed = true;

			if PlayingAnim then
				PlayingAnim:Stop(.05);
				self.Entity.StatManager:RemoveAbsolute("Critical")
			else
				Network:post('ClientEvent',self.Entity.player, "CaptureCommand", {Command='Stop', Path=AnimPath}, false)
		--		Network:Send('Animator', {Command='Stop', Path=AnimPath}, false, self.player);
			end;
			task.cancel(NewDelay);
			self.Character:SetActive(false);
			self.Character:SetAttribute("BlockBuffer" ,false)
		end);

		repeat wait() until Proceed;
		
		task.spawn(function()
			self.Entity.RunTime:Wait(1)
			self.Entity.Server.CancelledHits[CurrentId..CurrentAttack or ""] = false;
		end)
		
		if NewCancel.Cancelled then return end;

		self.Character:SetActive(false);
		task.spawn(function()
			self.Entity.RunTime:Wait(0.075)
			self.Character:SetAttribute("BlockBuffer" ,false)
		end)

		if self.Entity.Server.CancelledHits[CurrentId..CurrentAttack or ""] then return end;
		NewCancel.Remove();

		if not self.Entity.player then
			local Range  = WeaponData.Range or 6
			local hitboxParams = {
				SizeOrPart = Vector3.new(5,5,Range),
				InitialPosition = self.Character.Root.CFrame * CFrame.new(0,0,-Range/2);
				DebounceTime = 0.8;
				Debris = 0.1;
				--UseClient = player;
				Blacklist = {self.Character.Rig};
				Debug = true,
			} :: HitboxTypes.HitboxParams

			local newHitbox, connected = Server.HitboxClass.new(hitboxParams)
			newHitbox.HitSomeone:Connect(function(hitChars)
				print(hitChars)
				
				task.spawn(function()
					--[[
					if combatState == "Uptilt" then
						local distance, char = CombatUtility:getFarthestCharacter(self.Entity.Character.HumanoidRootPart,hitChars)
						hitChars = {char}
					
					end]]
					for i, char in hitChars do
						local HitEntity = Server.EntityService.Find(char);
						if not HitEntity then continue end
						if (self.Character.Root.Position - HitEntity.Character.Root.Position).Magnitude > 15 then continue end


						self.Entity.Combat:RegisterHit(HitEntity, PunchIdentity)
					end
					
				--	Client.PacketLinks["RegisterHit"]:Fire({HitChars = hitChars, HitIdentity = HitIdentity})
					--	Resp = Network:post('RegisterHit', {DetectedChar = DetectedChar, Punch = PunchIdentity}, true);
				end)
			end)
			
			newHitbox:Start()
			--[[
			local PunchHitbox = self:CreateHitbox();
			Auxiliary.Shared.LightAttackHitbox(self, PunchHitbox, PunchIdentity, FinalAction, function(Hit: {any})
				self.Combat:RegisterHit(Hit, PunchIdentity);
			end);]]
		end;

		if CurrentAttack == WeaponData.ComboMax and not FinalAction then
			if not self.Entity.Server.LandedHits[CurrentId] then
				self.Entity.Combat:ChangeMobility({
					Duration = .4;
					Speed = 0;
					Jump = 0;
					Disabling = true;
				});
			end;
		end;

		task.spawn(function()
			self.Entity.RunTime:Wait(1)
			self.Entity.Server.LandedHits[CurrentId] = nil;
		end);
	end

	return Action end