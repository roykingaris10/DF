return function(Client)
	local Inputter = {}
	local player = Client.player
	local Network = Client.Network
	local Utilities = Client.Utilities
	
	local UserInputService = game:GetService('UserInputService')
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local ContextActionService = game:GetService("ContextActionService")
	local Players = game:GetService("Players")
	
	local lastTickW = 0
	
	local Mouse = player:GetMouse()

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	local GameSettings = require(Nodes.Data.GameSettings)
	local Auxiliary = require(Nodes.Utility.Auxiliary);
--	local ClientHitbox = require(Nodes.Utility.ClientHitbox);
	local Map = workspace.Map
	
	local processing = false
	local jumpCount = 0
	
	
	
	Inputter.ButtonMap = {
		Action = {Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonX};
--		Critical = {Enum.UserInputType.MouseButton2};
		WillActivate = {Enum.KeyCode.R};
		Dash = {Enum.KeyCode.Q};
		Block = {Enum.KeyCode.F};
		Sprint = {Enum.KeyCode.ButtonR1, Enum.KeyCode.LeftShift};
		Crouch = {Enum.KeyCode.C};
		OpenCoreMenu = {Enum.KeyCode.Tab};
	};

	Inputter.MobileButtons = {"Sprint"};
	
	local ValidStates = {
		[Enum.UserInputState.Begin] = true;
		[Enum.UserInputState.Change] = true;
		[Enum.UserInputState.End] = true;
	};
	
	local defaultCombat = {
		ActiveInput = false,
		currentAnimation = nil,
		selectedObject = nil,

		lastTick = 0,
		
		
		isAttacking = false,
	}

	for i, v in pairs(defaultCombat) do Inputter[i] = v end

	function Inputter:resetAttributes()
		for i, v in pairs(defaultCombat) do self[i] = v end
	end	

	local FetchTypes = {
		Camera = function()
			return workspace.CurrentCamera.CFrame;
		end;

		MoveDirection = function()
			return Client.CharacterHandler.MovementDirection;
		end;

		RootCFrame = function()
			local Character = player.Character;
			if not Character or not Character:IsDescendantOf(workspace.Entities) then return end;
			local HRP = Character:FindFirstChild('HumanoidRootPart');

			return HRP.CFrame;
		end;

		Pointing = function()
			if player:GetAttribute('CurrentDevice') ~= 'Keyboard' or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
				return workspace.CurrentCamera.CFrame * CFrame.new(0,0,-1000);
			else
				return Auxiliary.Mouse:GetPointing();
			end;
		end;

		LastActionCheck = function()
			local Character = player.Character;
			if not Character or not Character:IsDescendantOf(workspace.Entities) then return end;
			local Humanoid: Humanoid = Character:FindFirstChildOfClass('Humanoid');
			if not Humanoid then return end;

			local CurrentAttack = Character:GetAttribute('CurrentAttack')		
			if (not CurrentAttack) or (CurrentAttack+1 ~= 4) then return end;

			if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				return 'Downslam';
			elseif UserInputService:IsKeyDown(Enum.KeyCode.Space) or Humanoid.Jump then
				return 'Uptilt';
			end;

			return 'Normal';
		end;

		FloorMaterial = function()
			local Character = player.Character;
			if not Character or not Character:IsDescendantOf(workspace.Entities) then return end;
			local Humanoid: Humanoid = Character:WaitForChild('Humanoid');
			if not Humanoid then return end;

			return Humanoid.FloorMaterial;
		end;
		
		DragPosition = function()
			local cam = workspace.CurrentCamera
			local mouseCF = Mouse.Hit
			local mousePos = mouseCF.Position
--gotta change hoverrange
			local pos = cam.CFrame.Position + (mousePos - cam.CFrame.Position).Unit * (player.StatFolder.UserFolder:GetAttribute("Range") + (cam.CFrame.Position - player.Character.HumanoidRootPart.Position).Magnitude)
			return pos
		end,
	};
	
	
	--// TODO For Will Mode I think i will add the status trait of WillBuff and check if its on the player before each instance of a will variation such as Dash, Block, etc
		
		Inputter.Actions = {
		
		WillActivate = function(ActionName: sting, Held: boolean, InputObj: InputObject | number)
			if ActionName ~= "WillActivate" then return end

			local Character = player.Character;

			if not Character then return end;
			if not Character:IsDescendantOf(workspace.Entities) then return end;

			if not Held then return end;
			
			Network:post("ServerEvent","WillActivate")
		end;
		
		Dash = function(ActionName: sting, Held: boolean, InputObj: InputObject | number)
			if ActionName ~= "Dash" then return end
			
			local Character = player.Character;

			if not Character then return end;
			if not Character:IsDescendantOf(workspace.Entities) then return end;
			
			if not Held then return end;
			
			if Character:GetAttribute("WillProc") then
				Client.Entity.StateMachine:ChangeState("Movement","Dash")
				Client.Entity.StateMachine:Trigger("Movement","WillDash")
			elseif Client.Entity.GroundState then
				Client.Entity.StateMachine:ChangeState("Movement","Dash")
				Client.Entity.StateMachine:Trigger("Movement","Dash")
			else
				Client.Entity.StateMachine:ChangeState("Movement","Dash")
				Client.Entity.StateMachine:Trigger("Movement","AirDash")
			end
			
			return Enum.ContextActionResult.Pass
		end,

		Sprint = function(ActionName, Held: boolean, InputObj: InputObject | number)
			if ActionName ~= "Sprint" then return end

			local Character = player.Character;

			if not Character then return end;
			if not Character:IsDescendantOf(workspace.Entities) then return end;
			if player:GetAttribute('AutoRun') then return end;
			
			if Held then
				Client.Entity.StateMachine:ChangeState("Movement","Sprint")
				Client.Entity.StateMachine:Trigger("Movement","StartSprint")
			else
				Client.Entity.StateMachine:ChangeState("Movement","Sprint")
				Client.Entity.StateMachine:Trigger("Movement","EndSprint")
			end
		end;
		 
		Action = function(ActionName, Held: boolean, InputObj: InputObject | number)
			if ActionName ~= "Action" then return end

			local Character = player.Character;
			if not Character then return end;
			
			local function checkInAir()
				if ((Client.Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Client.Entity.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping)) and Client.Entity.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
					return false
				else
					return true
				end
			end
		
			if Held then
				if Client.Entity.EquippedItem then
					Client.PacketLinks["ActionItem"]:Fire({Name = Client.Entity.EquippedItem.Name,Id = Client.Entity.EquippedItem.Id})
					return
				end
				
				if not Client.Entity.Cooldowns.cooldownData["Aerial"] and checkInAir() and not Client.Entity.Character:GetAttribute("AirComboing") then
					Client.Entity.StateMachine:ChangeState("Combat","Aerial")
					local Attack = Client.Entity.StateMachine:Trigger("Combat","Attack")
					if Attack then return end
				end
				
				repeat
					Client.Entity.StateMachine:ChangeState("Combat","LightAttack")
					Client.Entity.StateMachine:Trigger("Combat","StartAttackLoop")
					RunService.Heartbeat:Wait()
				until Client.Entity.CombatData.LightAttackLoop == false
				
			else
				Client.Entity.CombatData.LightAttackLoop = false
			end
			return Enum.ContextActionResult.Pass
		end;
		
		Critical = function(ActionName, Held: boolean, InputObj: InputObject | number)
			if ActionName ~= "Critical" then return end

			local Character = player.Character;
			if not Character then return end;
			if not Held then return end;
			
			if Character:GetAttribute("Blocking") then
				if Character:GetAttribute("WillProc") and not Client.Entity.Cooldowns.cooldownData.WillEvasive then
					Network:post("ServerEvent","WillEvasive",{Held = Held})
				else
					Network:post("ServerEvent","Parry",{Held = Held})
				end
			elseif UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
				Client.Entity.StateMachine:ChangeState("Combat","Critical")
				Client.Entity.StateMachine:Trigger("Combat","Attack")
			end

			return Enum.ContextActionResult.Pass
		end;
		
		Block = function(ActionName: sting, Held: boolean, InputObj: InputObject | number)
			if ActionName ~= "Block" then return end

			local Character = player.Character;

			if not Character then return end;
			if not Character:IsDescendantOf(workspace.Entities) then return end;
			
			Network:post("ServerEvent","Block",{Held = Held})
			--[[
			if Held then
				Client.Entity.StateMachine:ChangeState("Combat","Block")
				Client.Entity.StateMachine:Trigger("Combat","StartBlock")
			else
				Client.Entity.StateMachine:ChangeState("Combat","Block")
				Client.Entity.StateMachine:Trigger("Combat","EndBlock")
			end
			]]
			return Enum.ContextActionResult.Pass
		end;
		
		OpenCoreMenu = function(ActionName, Held: boolean, InputObj: InputObject | number)
			if ActionName ~= "OpenCoreMenu" then return end

			local Character = player.Character;
			if not Character then return end;
			if not Held then return end;
			if Client.MenuClient and Client.MenuClient.ToggleScreen then
				Client.MenuClient:ToggleScreen("inventory")
			else
				Client.UISetup:ToggleCoreMenu()
			end
			return Enum.ContextActionResult.Pass
		end;

	};

	UserInputService.JumpRequest:Connect(function()
		if not Client.Entity or not Client.Entity.SetupFinished then return end
		local Character = player.Character
		if not Character or not Character:IsDescendantOf(workspace.Entities) then return end

		local Entity = Client.Entity

		Entity.StateMachine:ChangeState("Environment", "Vault")
		if Entity.StateMachine:Trigger("Environment", "TryVault") then
			local hum = Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.Jump = false end
		end
	end)

	local function shouldUseUserInputService(actionName)
		return (actionName == "WallJump")
	end
	
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			task.spawn(Inputter.Actions["Critical"], "Critical", true, input)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton2 then -- Right-click
			local mouse = player:GetMouse()
	--		onTargetSelected(mouse.Target)
		end

	end)

	function Inputter.Parse(ActionName: string, State: Enum.UserInputType, InputObj: InputObject)
		if not Client.Entity.SetupFinished then return end
		if shouldUseUserInputService(ActionName) then return end
		if not ValidStates[State] then return end 
		local Held = State == Enum.UserInputState.Begin
		
		
		task.spawn(Inputter.Actions[ActionName], ActionName, Held, InputObj)
	end


	function Inputter.Init()
		repeat task.wait() until Client.loaded
		for i, v in Inputter.ButtonMap do
			if shouldUseUserInputService(i) then
				continue
			end
			ContextActionService:BindAction(i, Inputter.Parse, table.find(Inputter.MobileButtons, i) ~= nil, table.unpack(v))
		end
		
		Network:bindFunction('Fetch', function(Params)
			return FetchTypes[Params.Fetching]()
		end)
	end

	return Inputter end