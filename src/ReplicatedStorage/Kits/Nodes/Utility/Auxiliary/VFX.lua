--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local TweenService = game:GetService('TweenService');

local Kits = ReplicatedStorage.Kits
local Nodes: Folder = Kits.Nodes;

local Effects: Folder = workspace:WaitForChild('EffectsFolder');
local Assets: Folder = script:WaitForChild('Assets');

local AuxiliaryShared = require(script.Parent.Shared);
local Client = require(script.Parent.Client);

local Debris = require(Nodes.Utility.Debris);

--//Module
local Auxiliary = {};

Auxiliary.SpawnAfterimage = function(CFr: CFrame)
	local Afterimage: Model = Client.SpawnGroup(Assets.Afterimage, CFr, 3);
	Client.Emit(Afterimage);
end;

Auxiliary.CreateSplatter = function(Origin: CFrame, Amount: number?, Distance: number?, XVaration: number?, SplatterDelay: number?, SplatterSize: number?, SplatterDuration: number?)
	Amount = Amount or 5;
	SplatterDuration = SplatterDuration or 4;
	SplatterSize = SplatterSize or 12;
	Distance = Distance or 15;
	
	Origin *= CFrame.new(0,0,2);
	
	local function CreateSplatter(i: number)
		local Alpha = i/Amount;
		local Offset = Origin:Lerp(Origin * CFrame.new(0,0,-Distance), Alpha*AuxiliaryShared.Ran:NextNumber(.85,1.15)) * 
			CFrame.new((XVaration or (Distance*.3)) * AuxiliaryShared.Ran:NextNumber(-1,1),0,0);
		
		local NewRay = workspace:Raycast(Offset.Position, Vector3.yAxis*-5, AuxiliaryShared.RayParams.Map);
		if not NewRay then return end;
		
		local NewSplatter: BasePart = Assets.Splatter:Clone();
		NewSplatter.CFrame = (CFrame.new(NewRay.Position, NewRay.Position + NewRay.Normal) * CFrame.Angles(math.rad(-90),0,0))
			* CFrame.fromOrientation(0,AuxiliaryShared.Ran:NextNumber(0,math.pi*2),0);
		NewSplatter.Size = Vector3.new(.01,.05,.01);
		NewSplatter.Decal.Color3 = Color3.fromRGB(AuxiliaryShared.Ran:NextNumber(100,120),0,0);
		
		NewSplatter.Parent = Effects;
		
		TweenService:Create(NewSplatter, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = Vector3.new(
				SplatterSize*AuxiliaryShared.Ran:NextNumber(.9,1.1),
				.05,
				SplatterSize*AuxiliaryShared.Ran:NextNumber(.9,1.1)
			);
		}):Play();
		
		task.delay(SplatterDuration*.7, function()
			TweenService:Create(NewSplatter.Decal, TweenInfo.new(SplatterDuration*.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Transparency = 1;
				Color3 = Color3.fromRGB(AuxiliaryShared.Ran:NextNumber(95,110),0,0);
			}):Play();
		end);
			
		Debris:AddItem(NewSplatter, SplatterDuration);
	end;
	
	for i = 1,Amount do
		task.spawn(CreateSplatter, i);
		if SplatterDelay then
			task.wait(SplatterDelay);
		end;
	end;
end;

Auxiliary.MangaBox = function(parent: Instance, Msg: string, Height: Number, End: Number, Side: string)
	local Xside = 4
	if Side == "Left" then
		Xside = -4
	end
	
	local BillUI = Assets.BillboardGui:Clone()
	BillUI.Parent = parent
	BillUI.StudsOffset = Vector3.new(Xside,Height,0)
	BillUI.Frame.TextLabel.Text = Msg
	Debris:AddItem(BillUI,3.5)
	local billtween = TweenService:Create(BillUI,TweenInfo.new(0.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{StudsOffset = Vector3.new(Xside,End,0)})
	billtween:Play()
	local frametween = TweenService:Create(BillUI.Frame,TweenInfo.new(0.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{BackgroundTransparency = 0})
	frametween:Play()
	local labeltween = TweenService:Create(BillUI.Frame.TextLabel,TweenInfo.new(0.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{TextTransparency = 0})
	labeltween:Play()
	local stroketween = TweenService:Create(BillUI.Frame.UIStroke,TweenInfo.new(0.25,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Transparency = 0})
	stroketween:Play()
	
	task.delay(2.5,function()
		local billtween = TweenService:Create(BillUI,TweenInfo.new(0.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{StudsOffset = Vector3.new(Xside,Height,0)})
		billtween:Play()
		local frametween = TweenService:Create(BillUI.Frame,TweenInfo.new(0.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency = 1})
		frametween:Play()
		local labeltween = TweenService:Create(BillUI.Frame.TextLabel,TweenInfo.new(0.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{TextTransparency = 1})
		labeltween:Play()
		local stroketween = TweenService:Create(BillUI.Frame.UIStroke,TweenInfo.new(0.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency = 1})
		stroketween:Play()
	end)
end

return Auxiliary;