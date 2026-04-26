--State// Idle
return function(Client)
	local State = {}
	local player = Client.player
	local Network = Client.Network
	local Entity = Client.Entity
	local CharacterHandler = Client.CharacterHandler
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	local Trove = require(Nodes.Utility.Trove);
	
	local GameSettings = require(Nodes.Data.GameSettings);
	local CombatUtility = require(Nodes.Gameplay.CombatUtility)
	local Auxiliary = require(Nodes.Utility.Auxiliary)
	
	State["StartSprint"] = function(self,Params)
		Entity.SprintRequest = true
		Entity.StateMachine:ChangeState("Combat","Sprint")
		Entity.StateMachine:Trigger("Combat","Sprint")
	end
	
	local function SprintActionCheck()
		if Entity.CombatData.CurrentlyAttacking or Entity.CombatData.Dashing or Entity.CombatData.Sliding 
			or Entity.CombatData.Blocking or Entity.CombatData.WillDash or Entity.CombatData.RunBuffer
			or Entity.CombatData.Aerial
			or Entity.Character:GetAttribute("Blocking")
		then
			return true
		end
		return false
	end
	
	State["Sprint"] = function(self,Params)
		local Character = player.Character;
		local SprintAnim = Entity.AnimHandler:Fetch('General/Sprint');
		if not SprintAnim then warn("Missing Sprint Anim??") return end
		local camera = workspace.CurrentCamera
		if Entity.SprintRequest then
			Entity.Sprinting = false
		--[[
			SprintAnim:Play()
			
			Entity.MovementHandler:SetAbsolute("Sprint", {
				WalkSpeed = 22,
				Priority = 2
			})
		]]
			local sprintConn
			sprintConn = RunService.Heartbeat:Connect(function()
				if not Entity.SprintRequest then
					Entity.Sprinting = false
					Entity.MovementHandler:RemoveAbsolute("Sprint")
					SprintAnim:Stop()
					Client.Entity.CameraStats.CamVerticalFollow = 1
					sprintConn:Disconnect()
					return
				end
				
				local MoveDirection = Client.Entity.Temporary.MovementDirection
				
				if MoveDirection ~= "Forward" or SprintActionCheck() or not UserInputService:IsKeyDown(Enum.KeyCode.W) then
					SprintAnim:Stop()
					Client.Entity.CameraStats.CamVerticalFollow = 1
					Entity.Sprinting = false
					Entity.MovementHandler:RemoveAbsolute("Sprint")
				elseif not SprintAnim.IsPlaying then
					if not Entity.Sprinting then
						
						SprintAnim:Play()
						Entity.Sprinting = true
						Client.Entity.CameraStats.CamVerticalFollow = 0.03
						Entity.MovementHandler:SetAbsolute("Sprint", {
							WalkSpeed = 24,
							Priority = 2
						})
					end
				end
			end)
		end
	end
	
	State["EndSprint"] = function(self,Params)
		Entity.SprintRequest = false
	end
	

return State end
