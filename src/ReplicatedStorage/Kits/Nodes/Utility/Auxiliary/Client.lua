--//Variables
local RunService = game:GetService('RunService');
local Players = game:GetService('Players');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local CollectionService = game:GetService('CollectionService');
local Lighting = game:GetService('Lighting');
local TweenService = game:GetService('TweenService');

local GameSettings = UserSettings():GetService('UserGameSettings')

local Kits = ReplicatedStorage.Kits
local Nodes: Folder = Kits.Nodes;

local LocalPlayer = Players.LocalPlayer;

local Assets = script.Assets;
--local ClientComponents: Folder = LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Client').Components;
local Effects: Folder = workspace:WaitForChild('EffectsFolder');
local Map: Folder = workspace:WaitForChild('Map');
local Other: Folder = workspace:WaitForChild('MockFolder');

local AuxiliaryShared = require(script.Parent.Shared);
local Debris = require(Nodes.Utility.Debris);
local Signal = require(Nodes.Utility.Signal);
local Information = require(Nodes.Data.Information);
local WindShake = require(Nodes.Utility.WindShake);
local TroveFactory = require(Nodes.Utility.Trove);
--local ClientHitbox = require(Nodes.Utility.ClientHitbox);

local QUALITY_VARIATION = {
	Emit = {
		Fast = {
			[1] = .1;
			[2] = .15;
			[3] = .225;
			[4] = .275;
			[5] = .3;
			[6] = .325;
			[7] = .35;
			[8] = .45;
			[9] = .6;
			[10] = .7;
		};

		Default = {
			[1] = .2;
			[2] = .3;
			[3] = .45;
			[4] = .55;
			[5] = .65;
			[6] = .75;
			[7] = .85;
			[8] = 1;
			[9] = 1;
			[10] = 1;
		};
	};
};

local AllowedClasses = {
	Beam=true;
	Trail=true;
	ParticleEmitter=true;
	Decal=true;
};

local function ValidateInstance(Item: any, Blacklist: (table | () -> ())?)
	if typeof(Blacklist) == 'table' then
		local BannedInstances = Blacklist.Instances or {};
		local BannedClasses = Blacklist.Classes or {};
		local Callback = Blacklist.Callback;
		
		if BannedInstances[Item] then
			return false;
		elseif BannedClasses[Item.ClassName] then
			return false;
		end;
	elseif typeof(Blacklist) == 'function' then
		return Blacklist(Item);
	end;
	
	return AllowedClasses[Item.ClassName] ~= nil;
end;
--[[
local function GetEmitCount(Emitter: ParticleEmitter, CurrentQuality: number)
	local EmitCount = Emitter:GetAttribute('EmitCount');
	assert(EmitCount, `{Emitter.Name} does not have a EmitCount attribute!`);
	
	local Mult = QUALITY_VARIATION.Emit[(SettingsHandler:Get('Quality') > 1 and 'Fast') or 'Default'][CurrentQuality];
	return math.ceil(EmitCount*Mult);
end;
]]
local ParseArgs = function(Group: Model, Blacklist: {any}?)
	if Group == nil then
		return {
			Group = nil;
			Items = {};
		};
	end;

	local Items = {};    
	for _,v: any in Group:GetDescendants() do
		if not ValidateInstance(v, Blacklist) then continue end;
		table.insert(Items, v);
	end;

	return {
		Group = Group;
		Items = Items;
	};
end;

--//Module
local Auxiliary = {};
Auxiliary.HiddenPos = Vector3.xAxis*5000;
Auxiliary._Connections = {};
Auxiliary.MapLevel = 0;
Auxiliary.Threads = {};

Auxiliary.Cache = function()
	--Auxiliary.CachedMaterials = {};
	--do
	--	for _,v in Map:WaitForChild('Tangible'):GetDescendants() do
	--		if v:IsA('BasePart') then
	--			Auxiliary.CachedMaterials[v] = {v.Material, CollectionService:HasTag(v, 'WindShake')};
	--		end;
	--	end;

	--	for _,v in ReplicatedStorage:WaitForChild('_EnvironmentCache'):GetDescendants() do
	--		if v:IsA('BasePart') then
	--			Auxiliary.CachedMaterials[v] = {v.Material, CollectionService:HasTag(v, 'WindShake')};
	--		end;
	--	end;
	--end;

	--Auxiliary.CachedEmitters = {};
	--do
	--	for _,v in Map:GetDescendants() do
	--		if not v:IsA('ParticleEmitter') then continue end;
	--		if not v.Enabled then continue end;
	--		table.insert(Auxiliary.CachedEmitters, v);
	--	end;
	--end;
end;

Auxiliary.SpawnCameraRig = function()
	Auxiliary.CameraRig = Kits.Storage.CameraRig:Clone();
	
	Auxiliary.CameraRig:PivotTo(CFrame.new(Auxiliary.HiddenPos));
	Auxiliary.CameraRig.Parent = workspace.MockFolder.Cam;
end;

Auxiliary.CheckCameraDistance = function(Point: Vector3, MaxDistance: number)
	return (workspace.CurrentCamera.CFrame.Position-Point).Magnitude <= MaxDistance;
end;

Auxiliary.GetUserSetting = function(FetchingName: string)
	if FetchingName == 'Quality' then
		local FetchedQuality = tonumber(GameSettings.SavedQualityLevel.Value);
		return (FetchedQuality == 0 and 10) or FetchedQuality;
	end;
end;

local function EmitItem(Item: ParticleEmitter, CurrentQuality: number)
	local EmitDuration = Item:GetAttribute('EmitDuration');
	local EmitDelay = Item:GetAttribute('EmitDelay');
	local EmitCount = Item:GetAttribute('EmitCount');
	
	if EmitDelay then
		task.wait(EmitDelay);
	end;
	
	if EmitDuration then
		Item.Enabled = true;
		task.delay(EmitDuration, function()
			Item.Enabled = false;
		end);
	end;
	
	if EmitCount then
	--	Item:Emit(GetEmitCount(Item, CurrentQuality));
		Item:Emit(EmitCount)
	end;
end;

Auxiliary.Emit = function(...)
	local args = {...};
	task.spawn(function()
		local Parsed = ParseArgs(table.unpack(args));
		if Parsed.Group:GetAttribute('_Hidden') then return end;
		
		local Items = Parsed.Items;
		
		local CurrentQuality = Auxiliary.GetUserSetting('Quality');
		assert(CurrentQuality, debug.traceback('Could not fetch quality level!'));

		for _,Item: ParticleEmitter? in Items do
			if not Item:IsA('ParticleEmitter') then continue end;
			task.spawn(EmitItem, Item, CurrentQuality);
		end;
	end);
end;

Auxiliary.Clear = function(...)
	local args = {...};
	task.spawn(function()
		local Parsed = ParseArgs(table.unpack(args));
		local Items = Parsed.Items;
		
		for _,Item: ParticleEmitter? in Items do
			if not Item:IsA('ParticleEmitter') then continue end;
			Item:Clear();
		end;
	end);
end;

Auxiliary.Toggle = function(Bool: boolean, ...)
	local args = {...};
	task.spawn(function()
		local Parsed = ParseArgs(table.unpack(args));
		if Parsed.Group ~= nil and Parsed.Group:GetAttribute('_Hidden') then 
			repeat
				RunService.Heartbeat:Wait();
			until not (Parsed.Group ~= nil and Parsed.Group:GetAttribute('_Hidden'));	
		end;

		local Items = Parsed.Items;

		if Items then
			for _,Item: ParticleEmitter? in Items do
				Item.Enabled = Bool;
			end;
		end
	end);
end;

--Used for tweening meshes etc
Auxiliary.BindMesh = function(Mesh: BasePart, Callback: () -> (), Destroying: boolean?)
	local IsDestroying = (Destroying == nil and true) or Destroying;
	task.spawn(function()
		Callback(Mesh);
		if not IsDestroying then return end;
		Mesh:Destroy();
	end);
end;

Auxiliary.SpawnGroup = function(Cloning: Model, NewCFr: CFrame?, Duration: number?)
	local NewGroup = Cloning:Clone();
	if NewCFr then
		NewGroup:PivotTo(NewCFr);
	end;
	NewGroup.Parent = Effects;
	
	if Duration then
		Debris:AddItem(NewGroup, Duration);
	end;
	return NewGroup;
end;

Auxiliary.AlignGroup = function(Aligning: Model, BaseCFr: CFrame?, DestroyNonGrounded: boolean?)
	if BaseCFr then
		Aligning:PivotTo(BaseCFr);
	end;
	
	local GroundStatus = {};
	for _,v: BasePart in Aligning:GetDescendants() do
		if not v:IsA('BasePart') then continue end;
		if v:GetAttribute('Grounded') or CollectionService:HasTag(v, 'Grounded') then
			local GroundRay = workspace:Raycast(v.Position+Vector3.yAxis*2, Vector3.yAxis*-10, AuxiliaryShared.RayParams.Map);
			if not GroundRay and DestroyNonGrounded then
				v:Destroy();
				continue;
			end;
			
			if GroundRay then
				v.CFrame = (v.CFrame - v.Position) + GroundRay.Position;
				continue;
			end;
			
			GroundStatus[v] = (GroundRay ~= nil);
		end;
	end;
	
	return Aligning, GroundStatus;
end;

Auxiliary.CreateEffectPart = function(MakeSphere: boolean?, NoParenting: boolean?)
	local P: Part = Instance.new('Part');
	P.Anchored, P.CanCollide = true, false;
	
	if MakeSphere then
		Instance.new('SpecialMesh', P).MeshType = Enum.MeshType.Sphere;
	end;
	
	if not NoParenting then
		P.Parent = Effects;
	end;

	return P;
end;

Auxiliary.GetRandomVelocity = function(Speed: number, Direction: Vector3, Variation: number?)
	local Variation = Vector3.new(
		(math.random() - 0.5) * 2 * (Variation or .4),
		(math.random() - 0.5) * 2 * (Variation or .4),
		0
	);
	return (Direction+Variation)*Speed;
end;


Auxiliary.SpawnImpactFrame = function(Highlighting, ...)
	local Params = {...};
	task.spawn(function()
		local Highlights = {}
		
		for _,v: Model | BasePart in Highlighting:GetChildren() do
			local NewHighlight = Assets.ImpactFrameHighlight:Clone();
			
			NewHighlight.FillColor = Params.Highlight1 or Color3.new(0,0,0);
			NewHighlight.Parent = v
			
			table.insert(Highlights, NewHighlight)
		end;
		
		local NewColorCorrection = Assets.ImpactFrameCorrection
		NewColorCorrection.Parent = game.Lighting
		NewColorCorrection.Contrast = -55
		
		task.wait(.1);
		NewColorCorrection.Contrast = 55
		
		for _,v in Highlights do
			v.FillColor = Color3.new(1,1,1);
		end;
		
		task.wait(.1);
		NewColorCorrection.Parent = Assets
		for _,v in Highlights do
			v:Destroy()
		end;
		table.clear(Highlights)
	end);
end;

Auxiliary.TweenNumberSequence = function(numberSequence, targetSequence, smoothness, timeTaken, objectToUpdate, propertyName, easeStyle, easeDirection)
	assert(numberSequence and typeof(numberSequence) == "NumberSequence", "Invalid numberSequence")
	assert(targetSequence and typeof(targetSequence) == "NumberSequence", "Invalid targetSequence")
	assert(smoothness and type(smoothness) == "number" and smoothness > 0, "Invalid smoothness")
	assert(timeTaken and type(timeTaken) == "number" and timeTaken > 0, "Invalid timeTaken")
	assert(type(objectToUpdate[propertyName]) == "userdata" , "Invalid objectToUpdate")
	assert(propertyName and type(propertyName) == "string", "Invalid propertyName")

	local keypoints = numberSequence.Keypoints
	local targetKeypoints = targetSequence.Keypoints

	local originalTimes = {}
	local originalValues = {}
	local originalEnvelopes = {}
	for _, keypoint in ipairs(keypoints) do
		table.insert(originalTimes, keypoint.Time)
		table.insert(originalValues, keypoint.Value)
		table.insert(originalEnvelopes, keypoint.Envelope)
	end

	local function updateNumberSequence(progress)
		local newKeypoints = {}
		for i, originalTime in ipairs(originalTimes) do
			local closestTargetKeypointIndex = 1
			local closestTimeDifference = math.abs(originalTime - targetKeypoints[1].Time)
			for j, targetKeypoint in ipairs(targetKeypoints) do
				local timeDifference = math.abs(originalTime - targetKeypoint.Time)
				if timeDifference < closestTimeDifference then
					closestTimeDifference = timeDifference
					closestTargetKeypointIndex = j
				end
			end

			local targetValue = targetKeypoints[closestTargetKeypointIndex].Value
			local targetEnvelope = targetKeypoints[closestTargetKeypointIndex].Envelope

			local newValue = AuxiliaryShared.Lerp(originalValues[i], targetValue, progress)
			local newEnvelope = AuxiliaryShared.Lerp(originalEnvelopes[i], targetEnvelope, progress)
			table.insert(newKeypoints, NumberSequenceKeypoint.new(originalTime, newValue, newEnvelope))
		end
		return NumberSequence.new(newKeypoints)
	end

	for t = 0, 1, 1 / (smoothness * timeTaken) do
		local ta = game.TweenService:GetValue(t, easeStyle, easeDirection)
		local newNumberSequence = updateNumberSequence(ta)
		objectToUpdate[propertyName] = newNumberSequence
		task.wait(1 / smoothness)
	end

	local newKeypoints = {}
	for i, originalTime in ipairs(originalTimes) do
		local closestTargetKeypointIndex = 1
		local closestTimeDifference = math.abs(originalTime - targetKeypoints[1].Time)
		for j, targetKeypoint in ipairs(targetKeypoints) do
			local timeDifference = math.abs(originalTime - targetKeypoint.Time)
			if timeDifference < closestTimeDifference then
				closestTimeDifference = timeDifference
				closestTargetKeypointIndex = j
			end
		end

		local targetValue = targetKeypoints[closestTargetKeypointIndex].Value
		local targetEnvelope = targetKeypoints[closestTargetKeypointIndex].Envelope

		table.insert(newKeypoints, NumberSequenceKeypoint.new(originalTime, targetValue, targetValue))
	end
	objectToUpdate[propertyName] = NumberSequence.new(newKeypoints)
end;

Auxiliary.FetchEmitterProperties = function(ParticlesHolder)
	local Orig : ParticleCounterpart = {};

	for _,v : ParticleEmitter in ParticlesHolder:GetDescendants() do
		if not v:IsA('ParticleEmitter') then continue end;
		Orig[v] = {Size = v.Size, ZOffset = v.ZOffset, Acceleration = v.Acceleration, Speed = v.Speed};
	end;

	return Orig;
end;

Auxiliary.ScaleEmitters = function(Holder, Multiplier: number, Orig: {any})
	local function scaleNumberSequence(ns, scale)
		local keypoints = ns.Keypoints
		for i = 1, #keypoints do
			keypoints[i] = NumberSequenceKeypoint.new(keypoints[i].Time, keypoints[i].Value * scale, keypoints[i].Envelope * scale)
		end
		return NumberSequence.new(keypoints)
	end

	local function scaleNumberRange(nr, scale)
		return NumberRange.new(nr.Min * scale, nr.Max * scale)
	end

	local function scale(particle)
		local Counter_Part = Orig[particle];

		particle.Size = scaleNumberSequence(Counter_Part.Size, Multiplier)
		particle.ZOffset = Counter_Part.ZOffset * Multiplier
		particle.Acceleration = Counter_Part.Acceleration * Multiplier
		particle.Speed = scaleNumberRange(Counter_Part.Speed, Multiplier)
	end;

	for _,v in pairs(Holder:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			coroutine.wrap(scale)(v)
		end
	end
end;

Auxiliary.PlayAnimatedCameraSequence = function(Path: string, Root: BasePart | CFrame, StaticFOV: number?, FOVOUT: number?)
	local IsPart = typeof(Root) == 'Instance';
	
	local FullPath = 'Camera/'..Path;
	local Track: AnimationTrack = _G.ClientAnimator:Fetch(FullPath);
	assert(Track, debug.traceback(`Could not find camera track of path {FullPath}`));
	
	if not IsPart then
		Auxiliary.CameraRig:PivotTo(Root);
	end;
	
	if StaticFOV then
		workspace.CurrentCamera.FieldOfView = StaticFOV;
	end;
	
	local OldCFr: CFrame = workspace.CurrentCamera.CFrame;
	
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable;
	RunService:BindToRenderStep('CameraRigConnection', Enum.RenderPriority.Camera.Value-1, function()
		workspace.CurrentCamera.CFrame = Auxiliary.CameraRig.Cam.CFrame;
		print(Track.TimePosition)
		
		if IsPart then
			Auxiliary.CameraRig:PivotTo(Root.CFrame);
		end;
	end);
	
	Track:Play(0);
	Track.Ended:Wait();
	
	if StaticFOV then
		if FOVOUT then
			TweenService:Create(workspace.CurrentCamera, TweenInfo.new(FOVOUT, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = Information:Get('Default').FOV}):Play();
		else
			workspace.CurrentCamera.FieldOfView = Information:Get('Default').FOV;
		end;
	end;
	
	RunService:UnbindFromRenderStep('CameraRigConnection');
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom;
	Auxiliary.CameraRig:PivotTo(CFrame.new(Auxiliary.HiddenPos));
end;

Auxiliary.OptimizeMap = function(Level: number)
	Auxiliary.MapLevel = Level
	
	if Level > 1 then
		WindShake:Pause();
		
		for _, Object in pairs(workspace.Map:GetDescendants()) do
			if Object:IsA("ParticleEmitter") and Object.Name == "Leaves" then
				Object.Enabled = false
			end
			
			if not Object:IsA("BasePart") then
				continue;
			end;
			
			if not Object:GetAttribute("ShadowEnabled") then
				Object:SetAttribute("ShadowEnabled", Object.CastShadow); -- those 32 parts with CastShadow to false..
				Object.CastShadow = false;
			end
			
			if Level > 2 then
				Object:SetAttribute("OldMaterial", Object.Material);
				Object.Material = Enum.Material.SmoothPlastic;
			end;
		end;
		
		if Auxiliary._Connections.OptimizePart then
			return
		end
		
		Auxiliary._Connections.OptimizePart = workspace.Map.DescendantAdded:Connect(function(Object)
			if Object:IsA("ParticleEmitter") and Object.Name == "Leaves" then
				Object.Enabled = false
				return
			end
			
			if not Object:IsA("BasePart") then
				return
			end
			
			if not Object:GetAttribute("ShadowEnabled") then
				Object:SetAttribute("ShadowEnabled", Object.CastShadow);
				Object.CastShadow = false;
			end
			
			if Auxiliary.MapLevel > 2 then
				Object:SetAttribute("OldMaterial", Object.Material);
				Object.Material = Enum.Material.SmoothPlastic;
			end
		end)
	else
		WindShake:Resume();
		
		Auxiliary._Connections.OptimizePart:Disconnect()
		
		for _, Object in pairs(workspace.Map:GetDescendants()) do
			if Object:IsA("ParticleEmitter") and Object.Name == "Leaves" then
				Object.Enabled = true
			end
			
			if not Object:IsA("BasePart") then
				continue;
			end;
			
			Object.CastShadow = Object:GetAttribute("ShadowEnabled") or true;
			Object:SetAttribute("ShadowEnabled", nil)
			
			Object.Material = Object:GetAttribute("OldMaterial") or Object.Material;
			Object:SetAttribute("OldMaterial", nil);
		end;
	end;
end;

Auxiliary.OffsetPart = function(Animating: BasePart | Weld, TwInfo: TweenInfo, OffsetPosition: Vector3?, OffsetOrientation: Vector3?)
	OffsetPosition = OffsetPosition or Vector3.zero;
	OffsetOrientation = OffsetOrientation or Vector3.zero;
	
	local _Trove = TroveFactory.new();
	local Prop = (Animating:IsA('Weld') and 'C0') or 'CFrame';
	
	local Origin = _Trove:Add(Instance.new('Part'));
	Origin.Anchored, Origin.CanCollide = true, false;
	Origin.Transparency = 1;
	
	Origin.CFrame = Animating[Prop];
	Origin.Parent = Other;
	
	local BaseAttachment = Instance.new('Attachment');
	BaseAttachment.Name = '_AnimatingAttachment';
	
	BaseAttachment.Parent = Origin;
	
	_Trove:Connect(BaseAttachment.Changed, function(property: string)  
		Animating[Prop] = BaseAttachment.WorldCFrame;
	end);
	
	local Tw: Tween = TweenService:Create(BaseAttachment, TwInfo, {Position = OffsetPosition, Orientation = OffsetOrientation});
	Tw:Play();
	
	_Trove:Connect(Tw.Completed, function(playbackState: Enum.PlaybackState) 
		_Trove:Destroy();
	end);
	
	return Tw;
end;

return Auxiliary;