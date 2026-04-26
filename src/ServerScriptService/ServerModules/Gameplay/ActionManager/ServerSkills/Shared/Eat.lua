return function(Server)
	
	local Utilities = Server.Utilities
	local Network = Server.Network
	local LibraryInfo = Server.LibraryInfo
	
	local Debris = game:GetService("Debris")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	local Maid = require(Nodes.Utility.Maid)
	
	local Action = {}
	Action.__index = Action
	
	function Action.new(Entity)
		local self = setmetatable({}, Action)
		self.Entity = Entity
		self.Maid = Maid.new()
		self.Checks = {"Active","Ragdoll","Stunned","Dashing"}
		return self
	end
	
	function Action:Start(Args)
		if not self.Entity.ActionManager.Validator.Check(self.Entity,script.Name,self.Checks) then return end
		self.Entity.Character:SetActive(true)

		local itemData = LibraryInfo[Args.Name]
		
		local eatAnim = self.Entity.Animator:Fetch(`General/Eat`);
		eatAnim:Play();
		eatAnim.Stopped:Wait()
		
--		task.wait(0.25)
		
		local newStack = (Args.Amount or 1) - 1

		self.Entity.InventoryManager:UpdateItem(Args.Id, {
			Amount = newStack
		})

		-- If stack hits 0, remove item entirely
		if newStack <= 0 then
			self.Entity.InventoryManager:RemoveItem(Args.Id)
		end
		
	--	task.delay(.5, function() 
			self.Entity.StatManager:ChangeHunger(itemData.HungerGain)
	--	end)
		
		local EffectData = {
			EffectModule = Kits.Nodes.EffectsModules.Shared.UI;
			Func = "EatFood";
		}
		if self.Entity.player then
			self.Entity.VFX:FireClient(EffectData,{},self.Entity.player)
		end
		
		
		self.Entity.Character:SetActive(false)
	end

	return Action end