return function(Client)
	local ClientChar = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	local Trove = require(Nodes.Utility.Trove);
	local GameSettings = require(Nodes.Data.GameSettings);
	local Auxiliary = require(Nodes.Utility.Auxiliary)
	local CameraShaker = require(Nodes.Utility.CameraShaker)
	local GameSettings = require(Nodes.Data.GameSettings)

	local PlayerGui = player:WaitForChild('PlayerGui')

	function ClientChar.CreateEntity()
		local Character = player.Character 
		Client.Entity = Client.EntityClient.new(Character)
		Client.Entity.StateMachine = Client.HSMachine.new(Character,"Movement", "Idle")
		Client.Entity.AnimHandler = Client.ClientAnimator.new(Character);
	--	Client.Entity.AnimHandler = Client.Animation.new(Character)
		Client.Entity.Cooldowns = Client.CooldownClient.new(Character)
		Client.Entity.MovementHandler = Client.MovementClient.new(Character)
		Client.Entity.RunTime = Client.RunTimeClient.new(Character)
		Client.Entity.SetupFinished = true
	--	ClientChar.LoadClientAnims()
	end

	function ClientChar.LoadClientAnims()
		Client.Entity.AnimHandler:LoadAnims("General",Client.AnimationData.General)
		Client.Entity.AnimHandler:LoadAnims("BaseCombat",Client.AnimationData.Weapons["Fists"])
	end

	local function GetMoveDirection(Character: Model)
		local Humanoid: Humanoid = Character:FindFirstChildOfClass('Humanoid');
		local HRP = Character:FindFirstChild('HumanoidRootPart');
		local MoveDirection = Humanoid.MoveDirection;

		local Returning = nil;

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			Returning = 'Forward';
		elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
			Returning = 'Backward';
		elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
			Returning = 'Left';
		elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
			Returning = 'Right';
		elseif MoveDirection.Magnitude == 0 then
			Returning = 'Forward';
			MoveDirection = -HRP.CFrame.LookVector.Unit;
		else
			if Client.Entity.RelativeCFrame.LookVector:Dot(MoveDirection) > .7 then
				Returning = 'Forward';
			elseif (-Client.Entity.RelativeCFrame.LookVector):Dot(MoveDirection) > .7 then
				Returning = 'Backward';
			elseif Client.Entity.RelativeCFrame.RightVector:Dot(MoveDirection) > .7 then
				Returning = 'Right';
			elseif (-Client.Entity.RelativeCFrame.RightVector):Dot(MoveDirection) > .7 then
				Returning = 'Left';
			else
				Returning = 'Forward';
			end;
		end;

		return Returning, MoveDirection;
	end;

	function ClientChar.SetCameraFacing(Bool: boolean, CheckDevice: boolean?)
		--if CheckDevice and Bool and player:GetAttribute('CurrentDevice') == 'Keyboard' then return end;

		local Character: Model = player.Character;
		if Bool then
			table.insert(Client.Entity.Temporary.FacingBools, true);
		else
			Auxiliary.Shared.RemoveFirstValue(Client.Entity.Temporary.FacingBools);
		end;

		Character:SetAttribute('CameraFacing', #Client.Entity.Temporary.FacingBools ~= 0);
	end;
	
	function ClientChar.SetFullFacing(Bool: boolean, CheckDevice: boolean?)
		--if CheckDevice and Bool and player:GetAttribute('CurrentDevice') == 'Keyboard' then return end;
		local Character: Model = player.Character;
		if Bool then
			table.insert(Client.Entity.Temporary.FacingBools, true);
		else
			Auxiliary.Shared.RemoveFirstValue(Client.Entity.Temporary.FacingBools);
		end;

		Character:SetAttribute('FullFacing', #Client.Entity.Temporary.FacingBools ~= 0);
	end;

	function ClientChar.CharSpawn()
		local Character = player.Character;
		--	repeat wait() until Character:IsDescendantOf(Entities);
		local Head = Character:WaitForChild('Head');
		local RootPart = Character:WaitForChild('HumanoidRootPart');
		local Humanoid = Character:FindFirstChildOfClass('Humanoid');
		local camera = workspace.CurrentCamera
		
		Client.Entity.AnimHandler:Cache()
		
		local CurrentSettings = table.clone(GameSettings.Camera)
		
		local lastPlayerPos = RootPart.Position
		local smoothedHorizontalPoint = Vector3.new(RootPart.Position.X, 0, RootPart.Position.Z)
		local currentOffset = Vector3.new()
		
		local function getTargetSettings()
			return {
				LeftOffset = Client.Entity.CameraStats.CamLeftOffset or GameSettings.Camera.LeftOffset,
				ForwardFollow = Client.Entity.CameraStats.CamForwardFollow or GameSettings.Camera.ForwardFollow,
				SideFollow = Client.Entity.CameraStats.CamSideFollow or GameSettings.Camera.SideFollow,
				VerticalFollow = Client.Entity.CameraStats.CamVerticalFollow or GameSettings.Camera.VerticalFollow,
				Smoothness = Client.Entity.CameraStats.CamSmoothness or GameSettings.Camera.Smoothness,
			}
		end
		RunService:BindToRenderStep('HeadOffset', Enum.RenderPriority.Camera.Value-1, function()
			if not Character or not Character.Parent then RunService:UnbindFromRenderStep('HeadOffset'); return end
		--	Client.Entity.CameraStats.CamLeftOffset = math.random(0,10)
		
			local targetSettings = getTargetSettings()
			local lerpSpeed = Client.Entity.CameraStats.CamSettingsLerpSpeed or GameSettings.Camera.SettingsLerpSpeed

			for key, targetValue in pairs(targetSettings) do
				CurrentSettings[key] = CurrentSettings[key] + (targetValue - CurrentSettings[key]) * lerpSpeed
			end

			-- Get camera's horizontal direction
			local cameraDirection = (camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
			if cameraDirection.Magnitude < 0.1 then
				cameraDirection = RootPart.CFrame.LookVector
			end
			local cameraRightVector = cameraDirection:Cross(Vector3.new(0, 1, 0)).Unit

			local playerVelocity = RootPart.Position - lastPlayerPos

			local horizontalVelocity = Vector3.new(playerVelocity.X, 0, playerVelocity.Z)
			local forwardSpeed = horizontalVelocity:Dot(cameraDirection)
			local sideSpeed = horizontalVelocity:Dot(cameraRightVector)

			-- Create weighted horizontal velocity for smooth following
			local targetHorizontalVelocity = cameraDirection * forwardSpeed * CurrentSettings.ForwardFollow 
				+ cameraRightVector * sideSpeed * CurrentSettings.SideFollow

			-- Update horizontal smoothed point
			local targetHorizontalPoint = Vector3.new(RootPart.Position.X, 0, RootPart.Position.Z)
			smoothedHorizontalPoint = smoothedHorizontalPoint + targetHorizontalVelocity
			smoothedHorizontalPoint = smoothedHorizontalPoint:Lerp(targetHorizontalPoint, CurrentSettings.Smoothness)

			-- Handle vertical separately with direct lerp (no velocity accumulation)
			local currentVerticalPos = RootPart.Position.Y
			local verticalLerpAlpha = 1 - ((1 - CurrentSettings.VerticalFollow) * (1 - CurrentSettings.Smoothness))
			local smoothedVerticalPos = currentOffset.Y + currentVerticalPos
			smoothedVerticalPos = smoothedVerticalPos + (currentVerticalPos - smoothedVerticalPos) * verticalLerpAlpha

			-- Combine horizontal and vertical into final smoothed focus point
			local smoothedFocusPoint = Vector3.new(
				smoothedHorizontalPoint.X,
				smoothedVerticalPos,
				smoothedHorizontalPoint.Z
			)

			local positionOffset = smoothedFocusPoint - RootPart.Position

			local lateralOffset = cameraRightVector * -CurrentSettings.LeftOffset

			local targetOffset = positionOffset + lateralOffset

			-- Smooth the final offset application
			currentOffset = currentOffset:Lerp(targetOffset, 0.3)

			Humanoid.CameraOffset = currentOffset

			lastPlayerPos = RootPart.Position
		end)
		
		local PreviousCF
		local Shake = CameraShaker.new(Enum.RenderPriority.Last.Value, function(offset)
			
			if camera then
				local current = camera.CFrame
				camera.CFrame = current * offset
				PreviousCF = current
			else
				PreviousCF = nil
			end
		end)
		
		RunService:BindToRenderStep("ShakeReset", Enum.RenderPriority.First.Value, function()

			if PreviousCF and camera then
				camera.CFrame = PreviousCF
			end
		end)

		Client.CameraShake = Shake
		Client.CameraShake:Start()

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);
		
		local function TrackAttributes()
			local PreviousServerState, CurrentServerState
			Character:GetAttributeChangedSignal("ServerState"):Connect(function()
				PreviousServerState = CurrentServerState
				CurrentServerState = Character:GetAttribute("ServerState")
				--print(`Prev: {PreviousServerState}, Curr: {CurrentServerState}`)

				shared.Profile.ServerState = CurrentServerState 

				if CurrentServerState == "Stunned" then
				----	shared.Profile:Stun()
					--shared.Profile:Trigger("TriggerStun")
					--if #workspace.Effects[Character.Name].CancelOnHit:GetChildren() > 0 then
					--	shared.Network:FireServer("ClearClientEffects", Character)
					--end
					--elseif PreviousServerState == "Stunned" then
					--	shared.Profile:Trigger("ReleaseStun")
				end
			end)
			
			Character:GetAttributeChangedSignal("Anchored"):Connect(function()
				local Enabled = Character:GetAttribute("Anchored")
				if Enabled then
					Character.HumanoidRootPart.Anchored = true
				else
					Character.HumanoidRootPart.Anchored = false
				end
			end)

			Character:GetAttributeChangedSignal("AutoRotate"):Connect(function()
				local Enabled = Character:GetAttribute("AutoRotate")
				if Enabled then
					Character.Humanoid.AutoRotate = true
				else
					Character.Humanoid.AutoRotate = false
				end
			end)
		end

		
		
		Humanoid.StateChanged:Connect(function(oldstate,newstate)
			if ((Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping)) and Humanoid.FloorMaterial ~= Enum.Material.Air then
				Client.Entity.GroundState = true
			else
				Client.Entity.GroundState = false
			end
		--	Network:get('PlayerData', 'setGroundState', groundState)
		end)

		local NewTrove = Trove.new();

		local PushVelocity: BodyVelocity;
		local VelocityQueued;

		NewTrove:Connect(Character:GetAttributeChangedSignal('ForwardPush'), function() 
			if VelocityQueued then return end;

			local PushValue = Character:GetAttribute('ForwardPush');
			if not PushValue then return end;

			if PushValue <= 0 then
				if PushVelocity then
					PushVelocity:Destroy();
					PushVelocity = nil;
				end;
				return;
			end;

			if not PushVelocity then
				VelocityQueued = true;
				if RootPart:FindFirstChildOfClass('BodyVelocity') then
					repeat RunService.Heartbeat:Wait() until not RootPart:FindFirstChildOfClass('BodyVelocity');
				end;

				VelocityQueued = false;

				PushVelocity = Auxiliary.Shared.CreateVelocity(RootPart);
				PushVelocity.P = 15_000;
				PushVelocity.MaxForce = Vector3.new(math.huge,0,math.huge);
				PushVelocity.Velocity = RootPart.CFrame.LookVector * Character:GetAttribute('ForwardPush');
			else
				PushVelocity.Velocity = RootPart.CFrame.LookVector * Character:GetAttribute('ForwardPush');
			end;
		end);


		local Connec: RBXScriptConnection;
		Connec = RunService.RenderStepped:Connect(function()

			if Character.Parent ~= workspace and Character.Parent ~= workspace.Entities then
				Connec:Disconnect();
				return;
			end;

			local CamCFr: CFrame = workspace.CurrentCamera.CFrame;
			local CamFacingCFr: CFrame = CFrame.new(RootPart.Position, RootPart.Position + CamCFr.LookVector);

			Client.Entity.CameraFacing = CamFacingCFr;

			local _,OrientationY =  CamCFr:ToOrientation();
			Client.Entity.RelativeCFrame = CFrame.new(RootPart.CFrame.Position) * CFrame.Angles(0,OrientationY,0);

			if (Humanoid.AutoRotate and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter) then return end;
--[[		if Character:GetAttribute('FacingPointer') then return end;
			if Character:GetAttribute('FullFacing') then return end;
]]
			if Character:GetAttribute('CameraFacing') then
				RootPart.CFrame = Client.Entity.RelativeCFrame;
			elseif Character:GetAttribute('FullFacing') then
				RootPart.CFrame = Client.Entity.CameraFacing
			end;
		end);

		local PushVelocity: BodyVelocity;
		local VelocityQueued;

		if player:GetAttribute('AutoRun') then
			Character:SetAttribute('Sprinting', true);
		end;

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);

		repeat
			pcall(function()	
				Client.Entity.Temporary.MovementDirection, Client.Entity.DirectionVelocity = GetMoveDirection(Character);
	--[[		local ValidSprint = (function()
					if Character:GetAttribute('Sprinting') and Client.Entity.Temporary.MovementDirection == 'Forward' then

						return true;
					end;

					return false;
				end)();

				local NewSpeed = (Humanoid:GetAttribute('DisableMovement') and 0) or Humanoid:GetAttribute('ServerSpeed') or Humanoid:GetAttribute('ClientSpeed');
				local NewJump = (Humanoid:GetAttribute('DisableMovement') and 0) or Humanoid:GetAttribute('ServerJump') or Humanoid:GetAttribute('ClientJump');

				Humanoid.WalkSpeed = NewSpeed or ((ValidSprint and GameSettings.RunSpeed) or GameSettings.WalkSpeed);
				Humanoid.JumpPower = NewJump or GameSettings.Jump;

				Client.Entity.Temporary.CurrentSprint = ValidSprint;]]
			end);

			RunService.Heartbeat:Wait();
		until not Connec.Connected;
		
	--	CameraConn:Disconnect()
	end

	function ClientChar.Init()
		local function setupForCharacter(char)
			char:WaitForChild("Humanoid", 10)
			char:WaitForChild("HumanoidRootPart", 10)
			ClientChar.CreateEntity()
			task.spawn(ClientChar.CharSpawn)
		end

		if player.Character then
			task.spawn(setupForCharacter, player.Character)
		end
		player.CharacterAdded:Connect(function(char)
			setupForCharacter(char)
		end)
	end

	return ClientChar end