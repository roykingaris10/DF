return function(Client)
	local FootstepsSetup = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local TweenService = game:GetService('TweenService')
	local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
	
	local FootstepsModule = require(ReplicatedStorage.Kits
		.Nodes.Utility.FootstepModule
	)	

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	function FootstepsSetup:Setup()
		
		local character  = player.Character or player.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local humanoid = character:WaitForChild("Humanoid")
		
		local soundGroup = FootstepsModule:CreateSoundGroup(character, "Footsteps", {
			Volume = 0.2,
			RollOffMode = Enum.RollOffMode.InverseTapered,
			MaxDistance = 100,
			MinDistance = 5
		}, false)
		
		local lastFootstepTime = 0
		local footstepCooldown = 0.225
		
		local function playFootstep()
			local currentTime = tick()
			if currentTime - lastFootstepTime < footstepCooldown then
				return
			end

			lastFootstepTime = currentTime

			-- Raycast to find what material the user is standing on
			local rayOrigin = humanoidRootPart.Position
			local rayDirection = Vector3.new(0, -humanoidRootPart.Size.Y/2 - 2, 0)
			local raycastParams = RaycastParams.new()
			
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = {character}
			
			local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			
			if raycastResult then
				local material = raycastResult.Material
				local soundTable = FootstepsModule:GetTableFromMaterial(material)
				
				if soundTable then
					
					local randomSoundId = FootstepsModule:GetRandomSound(soundTable)
					
					local materialName = nil
					
					for enumMat, soundList in pairs(FootstepsModule.MaterialMap) do
						if soundList == soundTable then
							-- Find the material related to the soundId
							for name, ids in pairs(FootstepsModule.SoundIds) do
								if ids == soundList then
									materialName = name
									break
								end
							end
							
							if materialName and soundGroup:FindFirstChild(materialName) then
								local materialGroup = soundGroup:FindFirstChild(materialName)
								local sounds = materialGroup:GetChildren()
								if #sounds > 0 then
									local randomSound = sounds[math.random(#sounds)]
									if randomSound:IsA("Sound") then
										-- print(material.Name)
										randomSound:Play()
									end
								end
							end
							
						end
					end
					
				end
				
			end

		end
		
		humanoid.StateChanged:Connect(function(oldState, newState)
			if newState == Enum.HumanoidStateType.Running then
				playFootstep()
			elseif newState == Enum.HumanoidStateType.Jumping then
				return
			end
		end) 

		local RunService = game:GetService("RunService")
		local UserInputService = game:GetService("UserInputService")
		local lastStepCheck = 0
		local walkStepInterval = 0.5  -- Slower footsteps when walking
		local runStepInterval = 0.3   -- Faster footsteps when running

		local isSprinting = false

		-- Detect when player holds shift to sprint
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
				isSprinting = true
			end
		end)

		UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if not gameProcessed and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
				isSprinting = false
			end
		end)

		RunService.Heartbeat:Connect(function()
			if humanoid.MoveDirection.Magnitude > 0.1 then
				local currentTime = tick()

				-- Use the sprint state to determine interval
				local stepInterval = isSprinting and runStepInterval or walkStepInterval

				if currentTime - lastStepCheck >= stepInterval then
					lastStepCheck = currentTime
					playFootstep()
				end
			end
		end)
	end
	
	
	function FootstepsSetup:Init()
		FootstepsSetup:Setup()
	end
	
	function FootstepsSetup:Start()
		-- Initialize the footstep system
		self:Init()
	end
	
	return FootstepsSetup
end