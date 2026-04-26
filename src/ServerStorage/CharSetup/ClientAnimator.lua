return function(Client)
--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService('RunService');

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes
local Animations: Folder = Kits.Animations;

local Auxiliary = require(Nodes.Utility.Auxiliary);

--//Module
local AnimatorManager = {};
AnimatorManager.__index = AnimatorManager;

AnimatorManager.new = function(Character)
	local self = setmetatable({
		
		Loaded = {};
		_Connections = {};
			Character = Character;
			Humanoid = Character.Humanoid;
		
	}, AnimatorManager);
	
	RunService.Heartbeat:Connect(function()
		if not self.Character or not self.Character:IsDescendantOf(workspace.Entities) then return end;

		for _,v: AnimationTrack in self.Loaded do
			if v.IsPlaying and not v.Animation:GetAttribute('IgnoreActive') then
				self.Character:SetAttribute('ClientAnimationActive', true);
				v:AdjustSpeed(self.Character:GetAttribute("TimeScale") or 1 * v:GetAttribute("Speed") or 1)
				return;
			end;
		end;

		self.Character:SetAttribute('ClientAnimationActive', nil);
	end);
	
	task.spawn(function()
		--[[
		repeat wait() until Network.Ready;
		Network:BindChannel('Animator', function(Params: {any}) 
			self:CaptureCommand(Params.Command, Params);
		end);]]
	end);
	
	return self;
end;

function AnimatorManager:Cache()
	self.Loaded = {};
		local Loading = {'General', 'Weapons/Fists', 'Camera','Victim'};
		
		if Client.Entity.EquippedWeapon then
			table.insert(Loading, 'Weapons/'..Client.Entity.EquippedWeapon)
		end

		for _, MovesetPath: string in Loading do
			-- Split path by '/' to handle nested folders
			local pathParts = string.split(MovesetPath, '/')
			local currentFolder: Instance? = Animations

			-- Navigate to the target folder
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
			
			local LoadingAnimator: AnimationController | Animator;
			if MovesetPath == 'Camera' then
				LoadingAnimator = Auxiliary.Client.CameraRig.Humanoid.Animator;
			else
				LoadingAnimator = self.Character.Humanoid.Animator;
			end;

			-- Recursively get all animations in this folder and subfolders
			for _, Anim: Animation in AnimationFolder:GetDescendants() do
				if not Anim:IsA('Animation') then continue end;
				
				local Track: AnimationTrack = LoadingAnimator:LoadAnimation(Anim);
				local TrackIndex = Auxiliary.Shared.GetPath(Anim, Animations);

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

function AnimatorManager:StopAllAnimations(Exceptions: {any}?, FadeTime: number?)
	for _,v: AnimationTrack in self.Loaded do
		if Exceptions and table.find(Exceptions, v.Animation.Name) then continue end;
		v:Stop(FadeTime);
	end;
end;

function AnimatorManager:CaptureCommand(Command: string, Params: {any})
	if Command=='Stop' then
		self:Fetch(Params.Path):Stop(Params.FadeTime);
	end;
end;

return AnimatorManager end