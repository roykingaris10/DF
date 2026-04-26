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
		self.Checks = {"Active","Ragdoll","Stunned","Dashing","Cooldown","CombatDisable","AttackBuffer","AerialBuffer"}
		return self
	end

	function Action:Start(Data)
		if not self.Entity.ActionManager.Validator.Check(self.Entity,"Aerial",self.Checks) then return end

		if self.Entity.Server.LastAerialAttack then
			if tick()-self.Entity.Server.LastAerialAttack < .01 then return end;
		end;

		self.Character:SetActive(true);
		self.Character:SetAttribute("BlockBuffer" ,true)
		self.Entity.Server.LastAerialAttack = tick();
		
		local AttackMaid = Maid.new()
		local AttackTags = {}
		local AttackAnimations = {}

		AttackMaid.OnClean = function()
			Util.ClearTable(AttackTags)	

			for _, Animation: AnimationTrack in pairs(AttackAnimations) do
				Animation:Stop()
			end

			if self.Character.Rig and self.Character.Rig.Parent then
			end
			
			task.delay(0.5, function()
				self.Entity.Server.LandedHits["Aerial"] = nil;
			end);
			self.Entity.StatManager:RemoveAbsolute("Aerial")
		end

		local Proceed = false;
		local FinalAction;
		if Data then
			FinalAction = Data.FinalAction;
		end;
		
		Data.CurrentWeapon = Data.CurrentWeapon or self.Entity.EquippedWeapon or "Fists"
		
		local CurrentId;
		if not self.Entity.player then
			CurrentId = "Aerial";
		else
			CurrentId = Data.CurrentId;
		end;
		
		local PunchIdentity = {
			AttackType = "Aerial";
			CurrentWeapon = Data.CurrentWeapon;
			FinalAction=FinalAction;
			CurrentId=CurrentId;
		};

		local CalledClient;
		local ClientResponded = false;
		
		local function checkInAir()
			if ((self.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and self.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping)) and self.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				return false
			else
				return true
			end
		end

		local WeaponData = Server.WeaponData[Data.CurrentWeapon] or Server.WeaponData["Fists"]
		local Speed = 40
		local PlayingAnim;
		local Anim, AnimPath =  Auxiliary.Shared.GetAerialAnimation(self.Entity.Animator, Data.CurrentWeapon, self.Character);
		if not self.Entity.player then
			PlayingAnim = Auxiliary.Shared.GetAerialAnimation(self.Entity.Animator, Data.CurrentWeapon, self.Character);
			PlayingAnim:Play()
			PlayingAnim:SetAttribute("Speed",WeaponData.AnimationTimes.Aerial or 1)
			AttackAnimations["Aerial"] = PlayingAnim
			AttackMaid:GiveTask(AttackAnimations["Aerial"]:GetMarkerReachedSignal("Slow"):Connect(function()
				Speed = 7
			end))
		--	PlayingAnim = Auxiliary.Shared.GetLightAnimation(self.Animator, CurrentAttack, FinalAction, self.Data.Character, self.Character, true);
		end

		local AerialVelocity
		if not self.Entity.player then
			self.Entity.StatManager:SetAbsolute("Aerial", {
				WalkSpeed = 8,
				JumpPower = 0,
				Priority = 4,
				Duration = PlayingAnim.Length,
			})
			
			AerialVelocity = CombatUtility:BVPlacer(self.Entity.Character.Root,{
				Name = "AerialVelocity";
				MaxForce = Vector3.new(3e5, 0, 3e5),
			})
			Server.Debris:AddItem(AerialVelocity,PlayingAnim.Length*WeaponData.AnimationTimes.Aerial or 1)
			
			AttackMaid:GiveTask(RunService.Heartbeat:Connect(function()
				AerialVelocity.Velocity = self.Character.Root.CFrame.LookVector * Speed
			end))
			
			AttackMaid:GiveTask(AerialVelocity.AncestryChanged:Once(function()
				if not AerialVelocity.Parent then
					AttackMaid:Destroy()
				end
			end))
		end
		
		self.Entity.Cooldowns:Set(script.Name, WeaponData.AerialCooldown);
	
		local ServerDelay = WeaponData.Timings.Hitbox["Aerial"]
	
		local NewDelay = task.delay(ServerDelay, function()
			Proceed = true;
		end);

		local NewCancel = self.Entity.Combat:CreateCancel(1, function()
			self.Entity.Server.CancelledHits["Aerial"] = true;
			Proceed = true;

			if PlayingAnim then
				PlayingAnim:Stop(.05);
			else
				Network:post('ClientEvent',self.Entity.player, "CaptureCommand", {Command='Stop', Path=AnimPath}, false)
		--		Network:Send('Animator', {Command='Stop', Path=AnimPath}, false, self.player);
			end;
			task.cancel(NewDelay);
			self.Character:SetActive(false);
			self.Character:SetAttribute("BlockBuffer" ,false)
		end);

		repeat wait() until Proceed;
		
		task.delay(1,function()
			self.Entity.Server.CancelledHits["Aerial"] = false;
		end)

		if NewCancel.Cancelled then return end;

		self.Character:SetActive(false);
		task.delay(0.15,function()
			self.Character:SetAttribute("BlockBuffer" ,false)
		end)

		if self.Entity.Server.CancelledHits["Aerial"] then return end;
		NewCancel.Remove();

		if not self.Entity.player then
			local Range  = WeaponData.AerialRange or 6
			local hitboxParams = {
				SizeOrPart = Vector3.new(5.5,7,Range),
				InitialPosition = self.Character.Root.CFrame * CFrame.new(0,0,-Range/2);
				DebounceTime = WeaponData.Timings.Duration.Aerial+0.2;
				Debris = WeaponData.Timings.Duration.Aerial;
				--UseClient = player;
				Blacklist = {self.Character.Rig};
				Debug = true,
			} :: HitboxTypes.HitboxParams

			local newHitbox, connected = Server.HitboxClass.new(hitboxParams)
			newHitbox.HitSomeone:Connect(function(hitChars)
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
			
			local StartTime = tick()

			repeat 
				task.wait() 
				local CF = Util.ExtrapolateMovingCFrame(self.Entity.Character.Root)
				newHitbox:SetPosition(CF * CFrame.new(0,0,-Range/2) )
			until StartTime + WeaponData.Timings.Duration.Aerial < tick() 
		end;

		AttackMaid:Destroy()
		return true
	end

	return Action end