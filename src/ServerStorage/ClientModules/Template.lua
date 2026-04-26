return function(Client)
	local TemplateModule = {}
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local TweenService = game:GetService('TweenService')
	local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	
	function TemplateModule:Init()
		
	end
	
	
	return TemplateModule end

	


