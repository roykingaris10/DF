--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local Kits= ReplicatedStorage.Kits;
local Nodes = Kits.Nodes;

local SoundFolder: Folder = Kits.Sounds;
local Effects: Folder = workspace:WaitForChild('EffectsFolder');

local Auxiliary = require(Nodes.Utility.Auxiliary);

--//Module
local SoundHandler = {};
SoundHandler._Cached = {};

function SoundHandler:Cache()
	SoundHandler._Cached = {};
	for _,Sound: Sound in SoundFolder:GetDescendants() do
		if not Sound:IsA('Sound') then continue end;
		SoundHandler._Cached[Auxiliary.Shared.GetPath(Sound, SoundFolder)] = Sound;
	end;
end;

function SoundHandler:Fetch(Path: string)
	return SoundHandler._Cached[Path];
end;

SoundHandler.Spawn = function(SoundPath: string, Holder: Instance | Vector3, Duration: number?, Pitch: number?, Debug: boolean?)
	local TargetSound = SoundHandler:Fetch(SoundPath);
	assert(TargetSound, debug.traceback('Could not find sound '..SoundPath..'!'));

	local HoldingPart;
	local Cloned: Sound = TargetSound:Clone();
	if Pitch then
		Cloned.PlaybackSpeed = Pitch;
	end;

	if typeof(Holder) == 'Instance' then
		Cloned.Parent = Holder;
	elseif typeof(Holder) == 'Vector3' then
		HoldingPart = Instance.new('Part');
		HoldingPart.Anchored, HoldingPart.CanCollide = true, false;
		HoldingPart.Transparency = 1;
		HoldingPart.Size = Vector3.one;

		if Debug then
			HoldingPart.Color = Color3.new(1,0,0);
			HoldingPart.Transparency = .5;
		end;

		HoldingPart.Position = Holder;

		HoldingPart.Name = TargetSound.Name;
		HoldingPart.Parent = Effects;	
		Cloned.Parent = HoldingPart;
	end;

	local SoundObject = {
		Destroyed = false;
		Sound=Cloned;	
	};

	SoundObject.Destroy = function()
		if SoundObject.Destroyed then return end;

		SoundObject.Destroyed = true;
		Cloned:Destroy();
		if HoldingPart then
			HoldingPart:Destroy();
		end;
	end;

	if Duration then
		Cloned:Play();
		task.delay(Duration, SoundObject.Destroy);
	end;

	return SoundObject;
end;

return SoundHandler;