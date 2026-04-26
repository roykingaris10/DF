--State// Idle
return function(Client)
	local State = {}
	local player = Client.player
	local Network = Client.Network
	local Entity = Client.Entity
	

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	local Trove = require(Nodes.Utility.Trove);
	
	
	State["StartBlock"] = function(self,Params)
		Entity.CombatData.BlockRequest = true
		Entity.StateMachine:ChangeState("Combat","Block")
		Entity.StateMachine:Trigger("Combat","Block")
	end
	
	local function BlockActionCheck()
		if Entity.CombatData.CurrentlyAttacking or Entity.CombatData.Dashing or Entity.CombatData.Sliding 
			or Entity.CombatData.ClientActive or Entity.Character:GetAttribute("Stun") or Entity.CombatData.WillDash 
			or Entity.CombatData.Ragdoll
		then
			return true
		end
		return false
	end
	
	State["Block"] = function(self,Params)
		local WeaponName = Entity.Character:GetAttribute("CurrentEquippedWeapon") or "Fists"
		local WeaponData = Client.WeaponData[WeaponName]
		if not WeaponData then return end
		local Animation = Entity.AnimHandler:Fetch("General/FlickerRush");
		Animation.Priority = Enum.AnimationPriority.Action
		Animation:Play();
		local BlockAnim = Entity.AnimHandler:GetAnim("Block", "BaseCombat")
		if not BlockAnim then warn("Missing Block Anim??") return end
		if Entity.CombatData.BlockRequest then
			Entity.CombatData.Blocking = false
			local blockConn
			blockConn = RunService.Heartbeat:Connect(function()
				if not Entity.CombatData.BlockRequest then
					Entity.CombatData.Blocking = false
					Network:post("ServerEvent","Block",false)
					Entity.MovementHandler:RemoveAbsolute("Block")
					BlockAnim:Stop()
					blockConn:Disconnect()
					return
				end
-- making blocking end if stunned ragdolled etc
				if BlockActionCheck() then
					BlockAnim:Stop()
					Entity.CombatData.Blocking = false
					Network:post("ServerEvent","Block",false)
					Entity.MovementHandler:RemoveAbsolute("Block")
				elseif not BlockAnim.IsPlaying then
					if not Entity.CombatData.Blocking then
						Entity.CombatData.Blocking = true
						Network:post("ServerEvent","Block",true)
						BlockAnim:Play()
						Entity.MovementHandler:SetAbsolute("Block", {
							WalkSpeed = 4,
							Priority = 2
						})
					end
				end
			end)
		end
	end
	
	State["EndBlock"] = function(self,Params)
		Entity.CombatData.BlockRequest = false
	end

return State end
