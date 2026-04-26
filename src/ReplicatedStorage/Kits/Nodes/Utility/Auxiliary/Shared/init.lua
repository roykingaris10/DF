--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local HttpService = game:GetService('HttpService');
local RunService = game:GetService('RunService');
local VoiceChatService = game:GetService('VoiceChatService');
local TweenService = game:GetService('TweenService');
local Players: Players = game:GetService('Players');

local Kits = ReplicatedStorage.Kits
local Nodes: Folder = Kits.Nodes;

local Information = require(Nodes.Data.Information);
local TroveFactory = require(Nodes.Utility.Trove);

local Map: Folder = workspace:WaitForChild('Map');
local Tangible = Map:WaitForChild('Physical');
local Entities = workspace:WaitForChild('Entities');

local CACHING_CLASSES = {
	Enabled = {'PointLight', 'SpotLight', 'Highlight', 'ParticleEmitter', 'Trail', 'Beam'};
	Transparency = {'BasePart', 'Decal'};
};

local function CheckCachingProperty(v: Instance)
	for PropertyName: string, ClassList: {any} in CACHING_CLASSES do
		for _,ClassName: string in ClassList do
			if v:IsA(ClassName) then
				return PropertyName;
			end;
		end;
	end;
end;

local function CheckForSurface(RigFilter: RaycastParams, SurfaceRay: RaycastResult, HitboxMargin: number)
	if not SurfaceRay then return end;
	local Hit = false;

	for i = 1,10 do
		local Result = workspace:GetPartBoundsInBox(CFrame.new(SurfaceRay.Position), Vector3.one*HitboxMargin, RigFilter);
		if #Result > 0 then
			Hit = true;
			break;
		end;

		task.wait(.01);
	end;

	if not Hit then return end;
	return true, SurfaceRay;
end;

local function MultiplyValue(v: any, Multiplier: number)
	if typeof(v) == 'Color3' then
		return Color3.new(v.R*Multiplier, v.G*Multiplier, v.B*Multiplier);
	end;
	
	return v*Multiplier;
end;

local function GetMultipliedValues(Values: {any}, Multiplier: number)
	local New = {};
	for i: any, v: any in Values do
		New[i] = MultiplyValue(v, Multiplier);
	end;
	
	return New;
end;

--//Module
local Auxiliary = {
	
	Ran = Random.new();
	FullCircle = math.pi*2;
	
	MapInstances = {};
	_HiddenModels = {};
	
	RandomList = require(script.RandomListClass);
};

Auxiliary.Ran = Random.new();
Auxiliary.FullCircle = math.pi*2;
Auxiliary.MapInstances = {};
Auxiliary.RandomList = require(script.RandomListClass);

local ParamFuncs = {
	Map = (function()
		local NewParams: RaycastParams = RaycastParams.new();
		NewParams.FilterType = Enum.RaycastFilterType.Include;
		NewParams.FilterDescendantsInstances = Auxiliary.MapInstances;

		return NewParams;
	end);
	--[[
	Hitboxes = (function()
		local NewParams: RaycastParams = RaycastParams.new();
		NewParams.FilterType = Enum.RaycastFilterType.Include;
		NewParams.FilterDescendantsInstances = {workspace:WaitForChild('Hitboxes')};
		NewParams.CollisionGroup = 'Hitbox';

		return NewParams;
	end);
	]]
	MapAndEntities = (function()
		local NewParams: RaycastParams = RaycastParams.new();
		NewParams.FilterType = Enum.RaycastFilterType.Include;
		NewParams.FilterDescendantsInstances = {Entities, Auxiliary.MapInstances};

		return NewParams;
	end);
};

local function UpdateParams()
	Auxiliary.RayParams.Map = ParamFuncs.Map();
	Auxiliary.RayParams.MapAndEntities = ParamFuncs.MapAndEntities();
end;

Auxiliary.StartCache = function()
	local function AddPart(v: BasePart?)
		if not v:IsA('BasePart') then return end;
		if v.Transparency >= 1 then return end;
		if not v.CanCollide then return end;
		table.insert(Auxiliary.MapInstances, v);
	end;

	local function RemovePart(v: BasePart)
		table.remove(Auxiliary.MapInstances, table.find(Auxiliary.MapInstances, v));
	end;

	for _,v: BasePart in Tangible:GetDescendants() do
		task.spawn(AddPart, v);
	end;

	Tangible.DescendantAdded:Connect(AddPart);
	Tangible.DescendantRemoving:Connect(RemovePart)

	task.spawn(function()
		UpdateParams();
		while task.wait(1) do
			UpdateParams();
		end;
	end);
end;

Auxiliary.RayParams = {
	Map = ParamFuncs.Map();
--	Hitboxes = ParamFuncs.Hitboxes();
	MapAndEntities = ParamFuncs.MapAndEntities();
};

Auxiliary.OverlapParams = {
	Map = (function()
		local NewParams: RaycastParams = OverlapParams.new();
		NewParams.FilterType = Enum.RaycastFilterType.Include;
		NewParams.FilterDescendantsInstances = {workspace.Map};

		return NewParams;
	end)();
};

Auxiliary.DeepClone = function(original: {any})
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = Auxiliary.DeepClone(v)
		end
		copy[k] = v
	end
	return copy
end;

Auxiliary.Count = function(tab: {any})
	local count = 0;
	for _ in tab do
		count += 1;
	end;
	return count;
end;

--Retrieve a OS styled path to an instance starting from Top to Bottom
Auxiliary.GetPath = function(Bottom, Top)
	local CurrentParent = Bottom;
	local Occurences = {};
	local PathStr = '';

	repeat
		Occurences[#Occurences+1] = CurrentParent.Name;
		CurrentParent = CurrentParent.Parent;
	until CurrentParent == Top;

	for i = #Occurences,1,-1 do
		PathStr ..= Occurences[i]..'/';
	end;

	return PathStr:sub(1,#PathStr-1);
end;

Auxiliary.CreateVelocity = function(Parent: BasePart)
	local BodyVelocity: BodyVelocity = Instance.new('BodyVelocity');
	BodyVelocity.P = 20_000;
	BodyVelocity.MaxForce = Vector3.one*4e4;
	
	BodyVelocity.Parent = Parent;
	return BodyVelocity;
end;

Auxiliary.CreatePosition = function(Parent: BasePart)
	local BodyPosition: BodyPosition = Instance.new('BodyPosition');
	BodyPosition.P = 20_000;
	BodyPosition.MaxForce = Vector3.one*math.huge;
	BodyPosition.Position = Parent.Position;

	BodyPosition.Parent = Parent;
	return BodyPosition;
end;

Auxiliary.CreateGyro = function(Parent: BasePart)
	local BodyGyro: BodyGyro = Instance.new('BodyGyro');
	BodyGyro.P = 20_000;
	BodyGyro.MaxTorque = Vector3.one*5e9;
	
	BodyGyro.Parent = Parent;
	return BodyGyro;
end;

Auxiliary.GetRandomOrientation = function()
	return Vector3.new(360*math.random(), 360*math.random(), 360*math.random());
end;

Auxiliary.GetRandomRad = function()
	return Vector3.new(Auxiliary.FullCircle*math.random(), Auxiliary.FullCircle*math.random(), Auxiliary.FullCircle*math.random());
end;

Auxiliary.GetLightAnimation = function(Animator: {any}, CurrentAttack: number, CurrentWeapon: string, Character: {any})
	--local IsAPlayer: Player? = Players:GetPlayerFromCharacter(Character.Rig);

	local NonAwakenedPath: string = `Weapons/{CurrentWeapon}/LightAttack/Light{CurrentAttack}`;
	local ChosenPath: string = NonAwakenedPath;
	local Animation: AnimationTrack = Animator:Fetch(ChosenPath);
	--[[
	local PreviousName: number;
	if FinalAction then
		PreviousName = 4;
	else
		PreviousName = CurrentAttack-1;
	end;
	
	local PreviousAnimation: AnimationTrack = Animator:Fetch(`Universal/{CurrentWeapon}/LightAttack/Light{CurrentAttack}`);
	if PreviousAnimation then
		PreviousAnimation:Stop(.1);
	end;
	]]
	return Animation, ChosenPath;
end;

Auxiliary.GetCriticalAnimation = function(Animator: {any}, CurrentWeapon: string, Character: {any})
	--local IsAPlayer: Player? = Players:GetPlayerFromCharacter(Character.Rig);

	local NonAwakenedPath: string = `Weapons/{CurrentWeapon}/Critical`;
	local ChosenPath: string = NonAwakenedPath;
	local Animation: AnimationTrack = Animator:Fetch(ChosenPath);
	--[[
	local PreviousName: number;
	if FinalAction then
		PreviousName = 4;
	else
		PreviousName = CurrentAttack-1;
	end;
	
	local PreviousAnimation: AnimationTrack = Animator:Fetch(`Universal/{CurrentWeapon}/LightAttack/Light{CurrentAttack}`);
	if PreviousAnimation then
		PreviousAnimation:Stop(.1);
	end;
	]]
	return Animation, ChosenPath;
end;

Auxiliary.GetAerialAnimation = function(Animator: {any}, CurrentWeapon: string, Character: {any})
	--local IsAPlayer: Player? = Players:GetPlayerFromCharacter(Character.Rig);

	local NonAwakenedPath: string = `Weapons/{CurrentWeapon}/Aerial`;
	local ChosenPath: string = NonAwakenedPath;
	local Animation: AnimationTrack = Animator:Fetch(ChosenPath);
	--[[
	local PreviousName: number;
	if FinalAction then
		PreviousName = 4;
	else
		PreviousName = CurrentAttack-1;
	end;
	
	local PreviousAnimation: AnimationTrack = Animator:Fetch(`Universal/{CurrentWeapon}/LightAttack/Light{CurrentAttack}`);
	if PreviousAnimation then
		PreviousAnimation:Stop(.1);
	end;
	]]
	return Animation, ChosenPath;
end;

Auxiliary.RemoveFirstValue = function(tab: {any})
	for i in tab do
		table.remove(tab,i);
		break;
	end;
end;

Auxiliary.FindFirstChildOfClass = function(Inst: Instance, ClassName: string, Recursive: boolean?)
	local LookingThrough: {any} = (Recursive and Inst:GetDescendants()) or Inst:GetChildren();
	for _,v: Instance in LookingThrough do
		if v.ClassName == ClassName then
			return v;
		end;
	end;
end;

Auxiliary.CalculateInterval = function(Duration: number, TargetPrints: number)
	return Duration / TargetPrints;
end;

Auxiliary.VectorIsInsideBorder = function(Position: Vector3, Border: BasePart)
	local v3 = Border.CFrame:PointToObjectSpace(Position)
	return (math.abs(v3.X) <= Border.Size.X / 2)
		and (math.abs(v3.Y) <= Border.Size.Y / 2)
		and (math.abs(v3.Z) <= Border.Size.Z / 2);
end;

Auxiliary.LightAttackHitbox = function(Caster: {any} | Player, PunchHitbox: {any}, PunchIdentity: {any}, OnHit: () -> ())
	PunchHitbox.Offset = CFrame.new(0,0,-3.5);
	PunchHitbox.Size = Information:Get('Combat/LightAttack').HitboxSize
	PunchHitbox.OnHit = OnHit;
	PunchHitbox:Fire();
end;

Auxiliary.TumbleHitbox = function(Caster: {any} | Player, PunchHitbox: {any}, PunchIdentity: {any}, OnHit: () -> ())
	PunchHitbox.Offset = CFrame.new(0,.5,0);
	PunchHitbox.Size = Vector3.new(4,4,3)
	PunchHitbox.OnHit = OnHit;
	PunchHitbox:Fire();
end;

Auxiliary.ItemHitbox = function(Caster: {any} | Player, PunchHitbox: {any}, PunchIdentity: {any}, ItemData,OnHit: () -> ())
	PunchHitbox.Offset = ItemData.Hitbox.CFrame
	PunchHitbox.Size = ItemData.Hitbox.Size
	PunchHitbox.OnHit = OnHit;
	PunchHitbox:Fire();
end;

Auxiliary.FindTopMostClass = function(Inst: Instance, ClassName: string)
	local CurrentInstance = Inst;
	local TopMostModel;
	
	while CurrentInstance ~= nil do
		if CurrentInstance.ClassName == ClassName then
			TopMostModel = CurrentInstance;
		end;
		CurrentInstance = CurrentInstance.Parent;
	end;
	
	return TopMostModel;
end;

Auxiliary.FindFirstAncestorOfAttribute = function(Inst: Instance, Attribute: string)
	local CurrentInstance = Inst;
	while CurrentInstance ~= nil do
		if CurrentInstance:GetAttribute(Attribute) ~= nil then
			return CurrentInstance;
		end;
		CurrentInstance = CurrentInstance.Parent;
	end;
end;

Auxiliary.Lerp = function(Start: number, Goal: number, Alpha: number)
	return Start + (Goal - Start) * Alpha;
end;

Auxiliary.PlayerHasVC = function(Player: Player)
	local Success, IsEnabled = pcall(function()
		return VoiceChatService:IsVoiceEnabledForUserIdAsync(Player.UserId);
	end);
	
	if not Success then return end;
	return IsEnabled;
end;

Auxiliary.InvertColor3 = function(Inverting: Color3)
	return Color3.new(1 - Inverting.R, 1 - Inverting.G, 1 - Inverting.B);
end;

Auxiliary.GetMajorityElement = function(array: {any})
	local Candidate = nil;
	local Count = 0;
	
	for _,v in array do
		if Count == 0 then
			Candidate = v;
		end;
		
		Count += ((Candidate == v and 1) or -1);
	end;
	
	return Candidate;
end;

Auxiliary.DeflectVector = function(V: Vector3, N: Vector3)
	return V - (2 * N * V:Dot(N));
end;

Auxiliary.HideModel = function(Model: Model)
	local ExistingObject = Auxiliary._HiddenModels[Model];
	if ExistingObject then
		ExistingObject:Add();
		return;
	end;
	
	local HideObject = {
		_Toggles = {};
		_Trove = TroveFactory.new();
		_Hidden = false;
		_Tracked = {};
	};
	
	HideObject._OnUpdate = HideObject._Trove:Add(Instance.new('BindableEvent')) :: BindableEvent;
	
	function HideObject:_UpdateTracked(v: Instance, Property: {any})
		local Visible = not HideObject._Hidden;
		
		if Property.Name == 'Enabled' then
			v.Enabled = (Property.OldValue == true and Visible);
		elseif Property.Name == 'Transparency' then
			v.Transparency = (Visible and Property.OldValue) or 1;
		end;
	end;
	
	function HideObject:Add()
		table.insert(HideObject._Toggles, true);
		HideObject._OnUpdate:Fire();
	end;
	
	function HideObject:Remove()
		table.remove(HideObject._Toggles, 1);
		HideObject._OnUpdate:Fire();
	end;
	
	function HideObject:_Clean()
		HideObject._Trove:Destroy();
	end;
	
	HideObject._Trove:Connect(HideObject._OnUpdate.Event, function()
		if #HideObject._Toggles == 0 then
			Auxiliary._HiddenModels[Model] = false;
			HideObject._Hidden = false;
			HideObject:_Clean();
		else
			HideObject._Hidden = true;
		end;
		
		for v: Instance, Property: {any} in HideObject._Tracked do
			HideObject:_UpdateTracked(v, Property);
		end;
	end);
	
	local function TrackObject(v: Instance)
		local PropertyName = CheckCachingProperty(v);
		if not PropertyName then return end;
		
		HideObject._Tracked[v] = {
			Name = PropertyName;
			OldValue = v[PropertyName];
		};
	end;
	
	for _,v: Instance in Model:GetDescendants() do
		TrackObject(v);
	end;
	
	HideObject._Trove:Connect(Model.DescendantAdded, function(v: Instance)
		TrackObject(v);
	end);
	
	HideObject._Trove:Connect(Model.DescendantRemoving, function(v: Instance)
		HideObject._Tracked[v] = nil;
	end);
	
	HideObject:Add();
	Model:SetAttribute('_Hidden', true);
	
	HideObject._Trove:Connect(Model:GetPropertyChangedSignal('Parent'), function()
		if not Model:IsDescendantOf(workspace) then
			HideObject:_Clean();
		end;
	end);
	
	Auxiliary._HiddenModels[Model] = HideObject;
	return HideObject;
end;

Auxiliary.ResizeCharacter = function(Rig: Model, characterScale: number)
	local Motors = {}
	table.insert(Motors, Rig.HumanoidRootPart.RootJoint)
	for i,Motor in pairs(Rig.Torso:GetChildren()) do
		if Motor:IsA("Motor6D") == false then continue end
		table.insert(Motors, Motor)
	end
	for _, v in pairs(Motors) do
		v.C0 = CFrame.new((v.C0.Position * characterScale)) * (v.C0 - v.C0.Position)
		v.C1 = CFrame.new((v.C1.Position * characterScale)) * (v.C1 - v.C1.Position)
	end
	-- RESIZE PARTS
	for _, Part in pairs(Rig:GetChildren()) do
		if Part:IsA("BasePart") == false then continue end
		Part.Size = Part.Size * characterScale
		if Part.Name == "Head" then
			Part.Mesh.Scale = Vector3.new(1.5, 1.5, 1.5) 
		end
	end
	-- RESIZE ACCESSORIES
	for _, Accessory in pairs(Rig:GetChildren()) do
		if not Accessory:IsA("Accessory") then continue end
		Accessory.Handle.AccessoryWeld.C0 = CFrame.new((Accessory.Handle.AccessoryWeld.C0.Position * characterScale)) * (Accessory.Handle.AccessoryWeld.C0 - Accessory.Handle.AccessoryWeld.C0.Position)
		Accessory.Handle.AccessoryWeld.C1 = CFrame.new((Accessory.Handle.AccessoryWeld.C1.Position * characterScale)) * (Accessory.Handle.AccessoryWeld.C1 - Accessory.Handle.AccessoryWeld.C1.Position)
		local AccessoryMesh = Accessory.Handle:FindFirstChildOfClass("SpecialMesh")
		if AccessoryMesh then
			AccessoryMesh.Scale *= characterScale
		end
		local AccessoryPart = Accessory.Handle:FindFirstChild("Part")
		if AccessoryPart then
			Accessory.Handle.Part.Scale *= characterScale
		end
	end
end;

Auxiliary.TweenCharacterSize = function(Rig: Model, EndScale: number, TwInfo: TweenInfo)
	local Motors = {}
	table.insert(Motors, Rig.HumanoidRootPart.RootJoint)
	for i,Motor in pairs(Rig.Torso:GetChildren()) do
		if Motor:IsA("Motor6D") == false then continue end
		table.insert(Motors, Motor)
	end
	for _, v in pairs(Motors) do
		TweenService:Create(v, TwInfo, {
			C0 = CFrame.new((v.C0.Position * EndScale)) * (v.C0 - v.C0.Position);
			C1 = CFrame.new((v.C1.Position * EndScale)) * (v.C1 - v.C1.Position);
		}):Play();
	end
	-- RESIZE PARTS
	for _, Part in pairs(Rig:GetChildren()) do
		if Part:IsA("BasePart") == false then continue end
		local OrigSize = Part.Size;
		
		TweenService:Create(Part, TwInfo, {Size = OrigSize*EndScale}):Play();
		
		if Part.Name == "Head" then
			Part.Mesh.Scale = Vector3.new(1.5, 1.5, 1.5) 
		end
	end
	-- RESIZE ACCESSORIES
	for _, Accessory in pairs(Rig:GetChildren()) do
		if not Accessory:IsA("Accessory") then continue end
		
		TweenService:Create(Accessory.Handle.AccessoryWeld, TwInfo, {
			C0 = CFrame.new((Accessory.Handle.AccessoryWeld.C0.Position * EndScale)) * (Accessory.Handle.AccessoryWeld.C0 - Accessory.Handle.AccessoryWeld.C0.Position);
			C1 = CFrame.new((Accessory.Handle.AccessoryWeld.C1.Position * EndScale)) * (Accessory.Handle.AccessoryWeld.C1 - Accessory.Handle.AccessoryWeld.C1.Position);
		}):Play();
		
		local AccessoryMesh = Accessory.Handle:FindFirstChildOfClass("SpecialMesh")
		if AccessoryMesh then
			TweenService:Create(AccessoryMesh, TwInfo, {Scale = AccessoryMesh.Scale*EndScale}):Play();
		end
		local AccessoryPart = Accessory.Handle:FindFirstChild("Part")
		if AccessoryPart then
			TweenService:Create(AccessoryPart, TwInfo, {Scale = Accessory.Scale*EndScale}):Play();
		end
	end
end;

Auxiliary.GetRaySurface = function(RayResult: RaycastResult)
	return CFrame.new(RayResult.Position, RayResult.Position+RayResult.Normal) * CFrame.Angles(math.rad(-90),0,0);
end;

Auxiliary.FetchSurface = function(Origin: Vector3, Direction: Vector3)
	local SurfaceRay = workspace:Raycast(Origin, Direction, Auxiliary.RayParams.Map);
	if not SurfaceRay then return end;

	return {
		_Raw = SurfaceRay;
		
		Position = SurfaceRay.Position;
		Normal = SurfaceRay.Normal;
		
		Color = SurfaceRay.Instance.Color;
		Material = SurfaceRay.Instance.Material;
		
		Instance = SurfaceRay.Instance;
		Perpendicular = Auxiliary.GetRaySurface(SurfaceRay);
	};
end;

Auxiliary.PlayFlipbook = function(Object: any, TextureList: {string}, Delay: number, Callback: (Decal) -> (), Count: number, Mode: boolean, FallbackTexture: boolean)
	local Decal: Decal = Object:FindFirstChildOfClass('Decal')
	if Decal then
		if TextureList then
			if Callback then
				Callback(Decal)
			end
			task.spawn(function()
				for i: number = 1, Count, 1 do
					local Texture = TextureList[i]
					if not Texture then
						break;
					end;
					Decal.Texture = Texture
					if Mode then
						Texture = i
						Callback(Texture, Decal)
					end
					task.wait(Delay);
						Decal.Texture = ''
				if FallbackTexture then
					local Texture = TextureList[i];
					if not Texture then
						return;
					end;
					Decal.Texture = Texture
					if Mode then
						Texture = i
						Callback(Texture, Decal)
					end
					task.wait(Delay);
				end
				if Mode == 'Texture' then
					local Texture = TextureList[i];
					if not Texture then
						return;
					end;
					Decal.Texture = Texture
					if Callback then
						Texture = i
						Callback(Texture, Decal)
					end
					task.wait(Delay);
				end;
				end
			
			end);
		end;
	end;
end;

Auxiliary.AlignCFrame = function(cf, up, visualize)
	local up = up and up.Magnitude > 0 and up or Vector3.yAxis --> Vector3.new(0,1,0)
	local position = cf.p
	local right = cf.LookVector:Cross(up).Unit
	right = (right.Magnitude > 1e-3 and right or cf.RightVector).Unit
	local look = right:Cross(up).Unit

	if visualize then
		local a = Instance.new("Part")
		a.TopSurface, a.BottomSurface = 0, 0
		a.FrontSurface = 6
		a.Anchored, a.CanCollide = true, false
		a.Size = Vector3.new(1,1,1)
		a.Color = Color3.new(0,1,0) -- green: right
		local b = a:Clone()
		b.Color = Color3.new(1,1,0) -- yellow: up
		local c = a:Clone()
		c.Color = Color3.new(1,0,0) -- red: look

		a.CFrame = CFrame.new(position, position + right)
		b.CFrame = CFrame.new(position, position + up)
		c.CFrame = CFrame.new(position, position + look)
		a.Parent, b.Parent, c.Parent = workspace._WorldOrigin, workspace._WorldOrigin, workspace._WorldOrigin
	end

	return CFrame.fromMatrix(position, right, up, look)
end

Auxiliary.PlayFlipbook = function(Object: any, TextureList: {string}, Delay: number, Callback: (Decal) -> (), Count: number, Mode: boolean, FallbackTexture: boolean)
	local Decal: Decal = Object:FindFirstChildOfClass('Decal')
	if Decal then
		if TextureList then
			if Callback then
				Callback(Decal)
			end
			task.spawn(function()
				for i: number = 1, Count, 1 do
					local Texture = TextureList[i]
					if not Texture then
						break;
					end;
					Decal.Texture = Texture
					if Mode then
						Texture = i
						Callback(Texture, Decal)
					end
					task.wait(Delay);
					
						Decal.Texture = ''
				if FallbackTexture then
					local Texture = TextureList[i];
					if not Texture then
						return;
					end;
					Decal.Texture = Texture
					if Mode then
						Texture = i
						Callback(Texture, Decal)
					end
					task.wait(Delay);
				end
				if Mode == 'Texture' then
					local Texture = TextureList[i];
					if not Texture then
						return;
					end;
					Decal.Texture = Texture
					if Callback then
						Texture = i
						Callback(Texture, Decal)
					end
					task.wait(Delay);
				end;
				end
			
			end);
		end;
	end;
end;

Auxiliary.SetOrientation = function(Object: CFrame, Direction:{ Magnitude: number }, UpVector: CFrame)
	if Direction then
		if Direction.Magnitude > 0 then
			local UpVector = Direction or Vector3.new(0, 1, 0);
		end;
	end;
	
	local UpVector: Vector3 = Vector3.new(0, 1, 0);
	local Threshold: number = 0.001;

	if Threshold < Object.LookVector:Cross(UpVector).Unit.Magnitude then
		if Direction and Direction.Magnitude > 0 then
			UpVector = Direction or Vector3.new(0, 1, 0)
		end
	end

	local RightVector = Object.RightVector.Unit
	if UpVector then
		if Direction and Direction.Magnitude > 0 then
			UpVector = Direction or Vector3.new(0, 1, 0)
		end
	end

	local Position: Vector3 = Object.Position
	return CFrame.fromMatrix(Position, RightVector, UpVector, RightVector:Cross(UpVector).Unit);
end

Auxiliary.AnticipateSurface = function(Character: Model, Callback: () -> (), RayDistance: number?, HitboxMargin: number?, Timeout: number?, NoRagdoll: boolean?, VisualizeRays: boolean?)
	local Root: BasePart = Character:WaitForChild('HumanoidRootPart')
	local _GroundConnec: RBXScriptConnection
	local PassedTime = 0
	local SelfFilter = OverlapParams.new()
	SelfFilter.FilterType = Enum.RaycastFilterType.Include
	SelfFilter.FilterDescendantsInstances = {Character}

	local function CreateRayVisual(origin: Vector3, direction: Vector3, hit: boolean, rayResult: RaycastResult?)
		if not VisualizeRays then return end

		local distance = direction.Magnitude
		local endPos = hit and rayResult.Position or (origin + direction)

		local rayPart = Instance.new("Part")
		rayPart.Name = "RayBeam"
		rayPart.Anchored = true
		rayPart.CanCollide = false
		rayPart.CanQuery = false
		rayPart.Size = Vector3.new(0.1, 0.1, distance)
		rayPart.CFrame = CFrame.lookAt(origin, endPos) * CFrame.new(0, 0, -distance/2)
		rayPart.Color = hit and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
		rayPart.Material = Enum.Material.Neon
		rayPart.Transparency = 0.5
		rayPart.Parent = workspace.EffectsFolder
		game.Debris:AddItem(rayPart,0.5)

		if hit then
			local hitMarker = Instance.new("Part")
			hitMarker.Name = "HitPoint"
			hitMarker.Anchored = true
			hitMarker.CanCollide = false
			hitMarker.CanQuery = false
			hitMarker.Size = Vector3.new(0.5, 0.5, 0.5)
			hitMarker.Shape = Enum.PartType.Ball
			hitMarker.Position = rayResult.Position
			hitMarker.Color = Color3.fromRGB(255, 255, 0)
			hitMarker.Material = Enum.Material.Neon
			hitMarker.Transparency = 0.3
			hitMarker.Parent = workspace.EffectsFolder
			game.Debris:AddItem(hitMarker,0.5)

			local normalPart = Instance.new("Part")
			normalPart.Name = "Normal"
			normalPart.Anchored = true
			normalPart.CanCollide = false
			normalPart.CanQuery = false
			normalPart.Size = Vector3.new(0.1, 0.1, 2)
			normalPart.CFrame = CFrame.lookAt(rayResult.Position, rayResult.Position + rayResult.Normal) * CFrame.new(0, 0, -1)
			normalPart.Color = Color3.fromRGB(0, 255, 255)
			normalPart.Material = Enum.Material.Neon
			normalPart.Transparency = 0.4
			normalPart.Parent = workspace.EffectsFolder
			game.Debris:AddItem(normalPart,0.5)
		end
		
		
	end

	_GroundConnec = RunService.Heartbeat:Connect(function(DT: number)
		if not Character:GetAttribute('Ragdolled') and not NoRagdoll then
			_GroundConnec:Disconnect()
			return
		end

		PassedTime += DT
		if PassedTime < .1 then
			return
		end
		PassedTime = 0

		local Vel = Root.AssemblyLinearVelocity.Unit
		if Vel.Magnitude == 0 then return end
		if Vel:Dot(Vector3.yAxis) > 0 then
			return
		end

		local rayDirection = Vel * (RayDistance or 10)
		local rayResult = workspace:Raycast(Root.Position, rayDirection, Auxiliary.RayParams.Map)

		-- Visualize the ray
		CreateRayVisual(Root.Position, rayDirection, rayResult ~= nil, rayResult)

		local Valid, NewRay = CheckForSurface(SelfFilter, rayResult, HitboxMargin or 3)

		if not _GroundConnec.Connected then return end

		if Valid then
			local reflectionVector = nil
			if NewRay then
				if VisualizeRays then
					local velocityDirection = Vel
					local normal = NewRay.Normal
					local dotProduct = velocityDirection:Dot(normal)
					reflectionVector = velocityDirection - (2 * dotProduct * normal)
					
					local reflectionPart = Instance.new("Part")
					reflectionPart.Name = "ReflectionVector"
					reflectionPart.Anchored = true
					reflectionPart.CanCollide = false
					reflectionPart.CanQuery = false
					reflectionPart.Size = Vector3.new(0.15, 0.15, 3)
					reflectionPart.CFrame = CFrame.lookAt(NewRay.Position, NewRay.Position + (reflectionVector * 3)) * CFrame.new(0, 0, -1.5)
					reflectionPart.Color = Color3.fromRGB(255, 0, 255)
					reflectionPart.Material = Enum.Material.Neon
					reflectionPart.Transparency = 0.3
					reflectionPart.Parent = workspace.EffectsFolder
					
				end
			end
			_GroundConnec:Disconnect()
		
			task.spawn(Callback, NewRay, reflectionVector)
			return
		end
	end)

	if Timeout then
		task.delay(Timeout or 5, function()
			if not _GroundConnec.Connected then return end
			_GroundConnec:Disconnect()
		
		end)
	end

	return _GroundConnec
end

return Auxiliary