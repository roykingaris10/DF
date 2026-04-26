local player = game.Players.LocalPlayer
local character  = player.Character or player.CharacterAdded:Wait()

local function open()
	local btn = player.PlayerGui.UI.crewOpenTest
	btn.Activated:Connect(function()
		btn.Parent.crewFrameTest.Visible = not btn.Parent.crewFrameTest.Visible
	end)
end
	
	open()

