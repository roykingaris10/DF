--//Variables
local Server = require(script.Parent)

local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService('RunService');
local SequenceProvider = game:GetService('KeyframeSequenceProvider');


local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes
local AnimationsFolder: Folder = Kits.Animations;

local Auxiliary = require(Nodes.Utility.Auxiliary);

--//Module
local AnimatorManager = {};
AnimatorManager.__index = AnimatorManager;

AnimatorManager.new = function(Entity: {any})
	local self = setmetatable({
		
		Loaded = {};
		_Connections = {};
		
		Parent = Entity;
		
	}, AnimatorManager);
	
	self._Connections[#self._Connections+1] = RunService.Heartbeat:Connect(function()
		if not self.Parent.Character.Rig or not self.Parent.Character.Rig:IsDescendantOf(workspace.Entities) then return end;
		
		for _,v: AnimationTrack in self.Loaded do
			if v.IsPlaying and not v.Animation:GetAttribute('IgnoreActive') then
				self.Parent.Character.Rig:SetAttribute('AnimationActive', true);
				v:AdjustSpeed(self.Parent.RunTime.FinalTimeScale or 1 * v:GetAttribute("Speed") or 1)
				return;
			end;
		end;
		
		self.Parent.Character.Rig:SetAttribute('AnimationActive', nil);
	end);
	
	return self;
end;

function AnimatorManager:Cache()
	self.Loaded = {};
	local Loading = {'General', 'Weapons/Fists', 'Victim'};
	if self.Parent.EquippedWeapon then
		table.insert(Loading, 'Weapons/'..self.Parent.EquippedWeapon)
	end

	for _, MovesetPath: string in Loading do
		-- Split path by '/' to handle nested folders
		local pathParts = string.split(MovesetPath, '/')
		local currentFolder: Instance? = AnimationsFolder

		for _, folderName in ipairs(pathParts) do
			if currentFolder then
				currentFolder = currentFolder:FindFirstChild(folderName)
			else
				break
			end
		end

		local AnimationFolder: Instance? = currentFolder
		if not AnimationFolder then
			warn(`Animation folder not found: {MovesetPath}`)
			continue
		end

		-- Recursively get all animations in this folder and subfolders
		for _, Anim: Animation in AnimationFolder:GetDescendants() do
			if not Anim:IsA('Animation') then continue end;

			local Track: AnimationTrack = self.Parent.Character.Humanoid.Animator:LoadAnimation(Anim);
			local TrackIndex = Auxiliary.Shared.GetPath(Anim, AnimationsFolder);

			self.Loaded[TrackIndex] = Track;

			if Anim:GetAttribute('Priority') then
				Track.Priority = Enum.AnimationPriority[Anim:GetAttribute('Priority')];
			end;
		end;
	end;
end;

function AnimatorManager:Fetch(Path: string)
	return self.Loaded[Path];
end;

function AnimatorManager:Destroy()
	for _,v: RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;
end;

function AnimatorManager:GetPlayingAnims()
	local PlayingAnims = {};
	for _,v: AnimationTrack in self.Loaded do
		if v.IsPlaying then
			PlayingAnims[v.Animation.Name] = v;
		end;
	end;
	return PlayingAnims;
end

function AnimatorManager:StopAllAnimations(Exceptions: {any}?, FadeTime: number?)
	for _,v: AnimationTrack in self.Loaded do
		if Exceptions and table.find(Exceptions, v.Animation.Name) then continue end;
		v:Stop(FadeTime);
	end;
end;

return AnimatorManager;