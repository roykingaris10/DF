--//Variables

local Server = require(script.Parent)
local Network = Server.Network
local LibraryInfo = Server.LibraryInfo

local ReplicatedStorage = game:GetService('ReplicatedStorage');
local RunService = game:GetService('RunService');
local SequenceProvider = game:GetService('KeyframeSequenceProvider');

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes
local AnimationsFolder: Folder = Kits.Animations;

local Auxiliary = require(Nodes.Utility.Auxiliary);

--//Module
local AnimatorManager = {};
local AnimationCache = {}
AnimatorManager.__index = AnimatorManager;

AnimatorManager.new = function(Entity: {any})
	local self = setmetatable({
		Parent = Entity;
		
		AnimStore = {};
		Loaded = {};
		_Connections = {};
		
	}, AnimatorManager);
	
	self._Connections[#self._Connections+1] = RunService.Heartbeat:Connect(function()
		if not self.Parent.Character.Rig or not self.Parent.Character.Rig:IsDescendantOf(workspace.Entities) then return end;
		
		for _,v: AnimationTrack in self.Loaded do
			if v.IsPlaying and not v.Animation:GetAttribute('IgnoreActive') then
				self.Parent.Character.Rig:SetAttribute('AnimationActive', true);
				return;
			end;
		end;
		
		self.Parent.Character.Rig:SetAttribute('AnimationActive', nil);
	end);
	
	return self;
end;

local function getAnimation(animId)
	if AnimationCache[animId] then
		return AnimationCache[animId]
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://"..animId
	AnimationCache[animId] = anim
	return anim
end

-- AnimationManager:Get("Weapons", "Cutlass", "Light1")
-----------------------------------------------------
function AnimatorManager:Get(...)
	local path = {...}
	local node = Server.AnimationData

	for _, key in ipairs(path) do
		node = node[key]
		if node == nil then
			warn("Animation path invalid:", table.concat(path, " > "))
			return nil
		end
	end

	return node
end

-- Example: Play("General", "Eat")
-----------------------------------------------------
function AnimatorManager:Play(...)
	local animId = self:Get(...)
	if not animId then return end

	local track = self.Parent.Character.Humanoid:LoadAnimation(getAnimation(animId))

	-- Track bookkeeping
	self.AnimStore = self.AnimStore or {}
	local key = table.concat({...}, "/")
	self.AnimStore[key] = track

	track:Play()
	return track
end

function AnimatorManager:Stop(...)
	local key = table.concat({...}, "/")
	local anims = self.AnimStore
	if not anims then return end
	if anims[key] then
		anims[key]:Stop()
		anims[key] = nil
	end
end

function AnimatorManager:StopAll()
	local anims = self.AnimStore
	if not anims then return end

	for _, track in pairs(anims) do
		track:Stop()
	end

	self.AnimStore = {}
end
--[[
function AnimatorManager:Cache()
	self.Loaded = {};

	local Loading = {'General', "Victim",self.Parent.Weapon, 
		self.Parent.FightingStyle, self.Parent.PrimaryTechnique
		, self.Parent.SecondaryTechnique};

	for _,MovesetName: string in Loading do
		if not MovesetName then continue end
		local AnimationFolder = AnimationsFolder:FindFirstChild(MovesetName);
		if not AnimationFolder then continue end
		for _,Anim: Animation in AnimationFolder:GetDescendants() do
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

function AnimatorManager:StopAllAnimations(Exceptions: {any}?, FadeTime: number?)
	for _,v: AnimationTrack in self.Loaded do
		if Exceptions and table.find(Exceptions, v.Animation.Name) then continue end;
		v:Stop(FadeTime);
	end;
end;
]]

function AnimatorManager:Destroy()
	for _,v: RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;
end;



return AnimatorManager;