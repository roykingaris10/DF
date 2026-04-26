return function(Client)
	local player = Client.player
	local Utilities = Client.Utilities
	local Network = Client.Network
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes

	local TroveFactory = require(Nodes.Utility.Trove);
	
	local CooldownClient = {}
	CooldownClient.__index = CooldownClient
	
	function CooldownClient.new(Character)
		local self = setmetatable({
			Character = Character;
			Humanoid = Character.Humanoid;
			
			cooldownData = {};
			timeScale  = 1;
			useScaledTime = false;
			
		}, CooldownClient);
		
	--	self:StartController()
		
		return self;
	end
	
	function CooldownClient:CooldownSet(CooldownInfo)
		self.cooldownData[CooldownInfo.Name] = true
	end
	
	function CooldownClient:CooldownRemove(CooldownInfo)
		self.cooldownData[CooldownInfo.Name] = nil
	end
	
	function CooldownClient:DisplayCooldown(CooldownInfo)
		local PlayerGui = player:WaitForChild('PlayerGui')
		local UI = PlayerGui:WaitForChild('UI')

		local HRP = player.Character:WaitForChild("HumanoidRootPart")
		local CooldownHolder = HRP:WaitForChild("CDBillboard")
		local Bar = ReplicatedStorage.Kits.UI:WaitForChild("cdBar")

		local CDTemplate = Bar:Clone()
		CDTemplate.Name = CooldownInfo.Name.."CD"
		CDTemplate.image.CDName.Text = (CooldownInfo.Name or "Invalid"):upper()
		--CDTemplate.CDTime.Text = CooldownInfo.Time or "..."
		CDTemplate.Parent = CooldownHolder
		CDTemplate.Visible = true
		local CDBar = CDTemplate.back.bar
		local BarSize = CDBar.Size
		local endtime = CooldownInfo.Time + tick()
		local UIConnection
		UIConnection = RunService.RenderStepped:Connect(function()
			local currTime = tick()
			if currTime < endtime then
				local cooldownremainder = endtime - currTime
				--CDTemplate.CDTime.Text = string.format("%.1f", cooldownremainder)
				local prog = cooldownremainder / CooldownInfo.Time
				CDBar.Size = UDim2.new(prog, BarSize.X.Offset, CDBar.Size.Y.Scale , CDBar.Size.Y.Offset)
				--	CDBar.Size = UDim2.new(CDBar.Size.X.Scale, CDBar.Size.X.Offset, BarSize.Y.Scale * prog , BarSize.Y.Offset)
			else 
				--CDTemplate.CDTime.Text = ""
				CDTemplate:Destroy()
				UIConnection:Disconnect()
			end
		end)
	end
	
	--[[function CooldownClient:DisplayCooldown(CooldownInfo)
		local PlayerGui = player:WaitForChild('PlayerGui')
		local UI = PlayerGui:WaitForChild('UI')

		local CooldownHolder = UI.CooldownHolder

		local CDTemplate = CooldownHolder.CDTemplate:Clone()
		CDTemplate.Name = CooldownInfo.Name.."CD"
		CDTemplate.CDName.Text = CooldownInfo.Name or "Invalid"
		CDTemplate.CDTime.Text = CooldownInfo.Time or "..."
		CDTemplate.Parent = CooldownHolder
		CDTemplate.Visible = true
		local CDBar = CDTemplate.CDBack.CDBar
		local BarSize = CDBar.Size
		local endtime = CooldownInfo.Time + tick()
		local UIConnection
		UIConnection = RunService.RenderStepped:Connect(function()
			local currTime = tick()
			if currTime < endtime then
				local cooldownremainder = endtime - currTime
				CDTemplate.CDTime.Text = string.format("%.1f", cooldownremainder)
				local prog = cooldownremainder / CooldownInfo.Time
				CDBar.Size = UDim2.new(prog, BarSize.X.Offset, CDBar.Size.Y.Scale , CDBar.Size.Y.Offset)
				--	CDBar.Size = UDim2.new(CDBar.Size.X.Scale, CDBar.Size.X.Offset, BarSize.Y.Scale * prog , BarSize.Y.Offset)
			else 
				CDTemplate.CDTime.Text = ""
				CDTemplate:Destroy()
				UIConnection:Disconnect()
			end
		end)
	end]]
	
	
	function CooldownClient:StartController()
		local controllerconn 
		
		controllerconn = RunService.RenderStepped:Connect(function()
			local now = os.clock()
			for keyName, info in pairs(self.cooldownData) do
				local PlayerGUI = player.PlayerGui
				local HUD = PlayerGUI.HUD
				local CDHolder = HUD.CDHolder
				
				local slot = CDHolder:FindFirstChild(keyName)
				if not slot then continue end
				
				local bar = slot.CDBack.CDBar
				local timerlabel = slot.CDTime
				
				local remaining
				
				if info.Paused then
					
				else
					remaining = math.max(0,info.Expires - now)
				end
				
				if bar then
					bar.Size = UDim2.new(remaining / info.Duration, 0, 1, 0)
				end
				
				if timerlabel then
					timerlabel.Text = string.format("%.1f", remaining)
				end
				
				if remaining <= 0 and not info.Paused then
					self.cooldownData[keyName] = nil
				end
			end
		end)
	end
	
	function CooldownClient:Add(SkillName: string, Duration: number?)
		local Prev = self.cooldownData[SkillName];

		if Duration then
			local EndTime = os.clock()+Duration;
			self.cooldownData[SkillName] = EndTime;
		else
			self.cooldownData[SkillName] = true;
		end;

		local function CheckCondition()
			local CurrentValue = self.cooldownData[SkillName];
			if typeof(CurrentValue) == 'number' then
				return os.clock() >= self.cooldownData[SkillName];
			else
				return not self.cooldownData[SkillName];
			end;
		end;

		task.spawn(function()
			if Prev then return end;
			repeat wait() until CheckCondition();
			self.cooldownData[SkillName] = nil;
		end);
	end;
	
	function CooldownClient:Set()
		
	end
	
	
	return CooldownClient end