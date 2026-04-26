--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local TweenService = game:GetService('TweenService');

local Kits = ReplicatedStorage.Kits
local Nodes: Folder = Kits.Nodes;

local Effects: Folder = workspace:WaitForChild('EffectsFolder');

local AuxiliaryShared = require(script.Parent.Shared);
local Debris = require(Nodes.Utility.Debris);

local function FetchGround(Pos: Vector3, NegY: number?)
	local GroundRay = workspace:Raycast(Pos, Vector3.yAxis * -(NegY or 8), AuxiliaryShared.RayParams.Map);
	if not GroundRay then return end;
	
	return {
		Position = GroundRay.Position;
		Normal = GroundRay.Normal;
		Color = GroundRay.Instance.Color;
		Material = GroundRay.Instance.Material;
		Raw = GroundRay;
	};
end;

--//Module
local Auxiliary = {};

Auxiliary.Crater = function(Origin: CFrame | Vector3, Params: {any}?)
	Params = Params or {};

	local OriginPos = (typeof(Origin) == 'CFrame' and Origin.Position) or Origin;
	local Ground = FetchGround(OriginPos+Vector3.yAxis*2, Params.RayRange or 10, AuxiliaryShared.RayParams.Map);
	if not Ground then return end;

	local OriginCFr = (typeof(Origin) == 'CFrame' and (Origin - Origin.Position) + Ground.Position) or CFrame.new(Ground.Position, Ground.Position+Ground.Normal) * CFrame.Angles(math.rad(-90),0,0);

	local RockCount = Params.Rocks or 4; -- How many pieces of rocks are in the crater
	local Distance = Params.Distance or 3; -- Distance from center
	local SizeMagnitude = Params.SizeMagnitude or 1 -- Accepts Vector3 and number;
	local BaseDuration = Params.BaseDuration or 2; -- Base duration for each crater piece
	local ExposeLevel = Params.ExposeLevel or 0; -- Exposure level of the rocks to the surface
	local OpenSpace = Params.OpenSpaces or 0; -- Amount of open spaces in the crater, gaps will always appear in the same spot
	local Layers = Params.Layers or 1;
	local LayerScaling = Params.LayerScaling or 0.075
	
	local LayerRingRandomization = Params.LayerRingRandomization or false
	local LayerOffsetRange = Params.LayerOffsetRange or 30
	
	local IsMagnitude = (typeof(SizeMagnitude) == 'number');

	local SizeMultipliers = {};
	if IsMagnitude then
		SizeMultipliers.X=SizeMagnitude;
		SizeMultipliers.Y=SizeMagnitude;
		SizeMultipliers.Z=SizeMagnitude;
	else
		SizeMultipliers.X=SizeMagnitude.X;
		SizeMultipliers.Y=SizeMagnitude.Y;
		SizeMultipliers.Z=SizeMagnitude.Z;
	end;

	--Variation range in crater piece distance
	local MinVariation = Params.VariationMin or 0.95;
	local MaxVariation = Params.VariationMax or 1.05;

	--Variation range in crater piece size
	local MinSizeVariation = Params.SizeVariationMin or 0.95;
	local MaxSizeVariation = Params.SizeVariationMax or 1.05;

	--Variation in angle
	local MinAngleVariation = Params.MinAngleVariation or 40;
	local MaxAngleVariation = Params.MaxAngleVariation or 45;

	--Axis bases
	local BaseX = Params.BaseX or 3;
	local BaseY = Params.BaseY or 1.5;
	local BaseZ = Params.BaseZ or 2.1;

	local BaseSize = Vector3.new(BaseX, BaseY, BaseZ);
	BaseSize *= Vector3.new(SizeMultipliers.X,SizeMultipliers.Y,SizeMultipliers.Z);

	--Fetch randomly generated variation in size
	local function FetchVariatedSize()
		return BaseSize*(AuxiliaryShared.Ran:NextNumber(MinSizeVariation, MaxSizeVariation));
	end;

	--Fetch randomly generated variation in distance
	local function GetDistanceVariation()
		return (Distance*(AuxiliaryShared.Ran:NextNumber(MinVariation, MaxVariation)));
	end;
	
	local function GetLayerRingOffset(layer: number)
		if not LayerRingRandomization then
			return 0
		end
		-- Each layer gets a different ring offset so they're not aligned
		return math.rad(AuxiliaryShared.Ran:NextNumber(-LayerOffsetRange, LayerOffsetRange))
	end

	local RockSpace = (RockCount+OpenSpace);
	
	--Create crater piece
	local function CreatePiece(i: number)
		local baseAngle = (i*(AuxiliaryShared.FullCircle/RockSpace))+math.rad(AuxiliaryShared.Ran:NextNumber(-30,30));

		for i = 1,Layers do
			task.spawn(function()
				-- NEW: Apply layer-specific ring offset
				local layerOffset = GetLayerRingOffset(i)
				local finalAngle = baseAngle + layerOffset

				local X,Z = math.sin(finalAngle), math.cos(finalAngle);

				X*=GetDistanceVariation();
				Z*=GetDistanceVariation();

				local OffsetPos = OriginCFr.Position + Vector3.new(X,0,Z);
				local GroundRay = workspace:Raycast(OffsetPos+Vector3.yAxis*2, Vector3.yAxis*-7, AuxiliaryShared.RayParams.Map);

				if not GroundRay then return end;
				if GroundRay.Normal:Dot(Vector3.yAxis) < 1 then return end;

				local ScaleFactor = (i == 1 and 1) or 1+(i*LayerScaling);
				
				local NewPiece = Instance.new('Part');
				NewPiece.Anchored, NewPiece.CanCollide = true, (Params.CanCollide == nil and false) or Params.CanCollide;
				NewPiece.Color, NewPiece.Material = GroundRay.Instance.Color, GroundRay.Instance.Material;
				NewPiece.Size = FetchVariatedSize()*ScaleFactor;
				
				local VarAngle = math.rad(AuxiliaryShared.Ran:NextNumber(MinAngleVariation,MaxAngleVariation)*ScaleFactor);
				if Params.Inverted then
					VarAngle = -VarAngle;
				end;

				local BaseCFr = CFrame.new(OffsetPos, OriginCFr.Position) * CFrame.new(0,0,(i == 1 and 0) or ScaleFactor*AuxiliaryShared.Ran:NextNumber(1.2,1.7)) * CFrame.Angles(VarAngle,0,0);
				local EndCFr = BaseCFr * CFrame.new(0,NewPiece.Size.Y*.05+ExposeLevel,0);

				NewPiece.CFrame = EndCFr;
				NewPiece.Position -= Vector3.yAxis*4;
	
				NewPiece.Parent = Effects;

				TweenService:Create(NewPiece, TweenInfo.new(AuxiliaryShared.Ran:NextNumber(.1,.15), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = EndCFr}):Play();
				task.wait(BaseDuration*AuxiliaryShared.Ran:NextNumber(.9,1.1));
				TweenService:Create(NewPiece, TweenInfo.new(AuxiliaryShared.Ran:NextNumber(1.1,1.5), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = NewPiece.Position-Vector3.yAxis*4}):Play();
				Debris:AddItem(NewPiece, 2);
			end);
		end;
	end;

	--Create X crater pieces
	for i = 1,RockCount do
		task.spawn(CreatePiece, i);
	end;
end;

Auxiliary.SideRocks = function(OriginFetch: () -> () | BasePart, Offset: number, ZAxis: boolean, SizeMag: number, Frequency: number, BaseVelocity: number?, RockDuration: number?)	
	local _Bind = Instance.new('BindableEvent');
	local Continue = true;
	
	_Bind.Event:Once(function()
		Continue = false;
		_Bind:Destroy();
	end);
	
	local IsFunction = typeof(OriginFetch) == 'function';
	
	local function RockTick(i)
		local Origin = (IsFunction and OriginFetch()) or OriginFetch.CFrame;
		
		local Dif = (i==1 and Offset) or -Offset;
		local CFr = Origin * CFrame.new((not ZAxis and Dif),0,(ZAxis and Dif));
		
		local Ground = FetchGround(CFr.Position);
		if not Ground then return end;
		
		local Rock = Instance.new('Part');
		Rock.Anchored, Rock.CanCollide = true, false;
		Rock.Color, Rock.Material = Ground.Color, Ground.Material;
		
		Rock.Size = Vector3.zero;
		
		Rock.Position = Ground.Position;
		Rock.Orientation += AuxiliaryShared.GetRandomOrientation();
		
		Rock.Parent = Effects;
		
		TweenService:Create(Rock, TweenInfo.new(.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = Vector3.one*SizeMag}):Play();
		task.wait(RockDuration or 2);
		TweenService:Create(Rock, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = Vector3.zero}):Play();
		Debris:AddItem(Rock, 3);
	end;
	
	task.spawn(function()
		repeat
			task.spawn(function()
				for i = 1,2 do
					task.spawn(RockTick, i);
					task.wait(AuxiliaryShared.Ran:NextNumber(.01,.04));
				end;
			end);
			
			local Mult = 1;
			if BaseVelocity then
				local Vel = OriginFetch.AssemblyLinearVelocity.Magnitude;
				Mult = 2-(Vel/BaseVelocity);
			end;
			
			task.wait((Frequency*Mult)*AuxiliaryShared.Ran:NextNumber(.8,1.2));
		until not Continue;
	end);
	
	return _Bind;
end;

local RockGenerationData = {
	['Look'] = {
		['Points'] = { Vector3.new(-2, 0, 0), Vector3.new(2, 0, 0) },
		['Generate'] = function()
			local randomXOffset = Random.new():NextNumber(-0.9, 0.9)
			return Vector3.new(randomXOffset, 0, 0)
		end
	},
	['Sides'] = {
		['Points'] = { Vector3.new(0, 0, 2), Vector3.new(0, 0, -2) },
		['Generate'] = function()
			local randomZOffset = Random.new()
			return Vector3.new(0, 0, randomZOffset:NextNumber(-0.95, 0.95));
		end;
	};
};

local function GenerateRock(DurationBeforeDestruction: number, SizeMultiplier: number, _Delay: number, GroundResult: RaycastResult)
	local NewRock: BasePart = Instance.new('Part');
	NewRock.CFrame = CFrame.lookAt(GroundResult.Position, GroundResult.Position + GroundResult.Normal) * CFrame.new(0, 0, 1);
	NewRock.Size = Vector3.zero;
	NewRock.Color = GroundResult.Instance.Color;
	NewRock.Material = GroundResult.Material;
	NewRock.CanCollide = false;
	NewRock.CollisionGroup = 'Debris';
	NewRock.CanTouch = false;
	NewRock.CanQuery = false;
	NewRock.Anchored = true;
	NewRock.Massless = true;
	NewRock.Parent = Effects;

	local InitialSize: number = AuxiliaryShared.Ran:NextNumber(0.75, 1.25) * SizeMultiplier;
	local FinalSize: number = AuxiliaryShared.Ran:NextNumber(1.15, 2.2) * SizeMultiplier;
	local MoveRocks: Tween;

	if AuxiliaryShared.Ran:NextInteger(1, 3) == 3 then
		MoveRocks = TweenService:Create(NewRock, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			['Size'] = Vector3.one * FinalSize,
			['CFrame'] = NewRock.CFrame * CFrame.new(0, 0, AuxiliaryShared.Ran:NextNumber(-1, -0.5)) * CFrame.Angles(AuxiliaryShared.Ran:NextNumber(-math.pi, math.pi), AuxiliaryShared.Ran:NextNumber(-math.pi, math.pi), AuxiliaryShared.Ran:NextNumber(-math.pi, math.pi));
		});
	else
		MoveRocks = TweenService:Create(NewRock, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			['Size'] = Vector3.one * InitialSize,
			['CFrame'] = NewRock.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(AuxiliaryShared.Ran:NextNumber(-math.pi/2, math.pi/2), AuxiliaryShared.Ran:NextNumber(-math.pi/2, math.pi/2), AuxiliaryShared.Ran:NextNumber(-math.pi/2, math.pi/2));
		});
	end;

	MoveRocks:Play();
	MoveRocks.Completed:Connect(function()
		MoveRocks:Destroy();
		task.wait(_Delay);
		task.wait(DurationBeforeDestruction / 5);
		MoveRocks = TweenService:Create(NewRock, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In, 0, false, 0), {
			['Size'] = Vector3.zero,
			['Position'] = NewRock.Position + Vector3.new(0, -2, 0),
			['Orientation'] = Vector3.zero;
		});
		MoveRocks:Play();
		MoveRocks.Completed:Wait();
		MoveRocks:Destroy();
		NewRock:Destroy();
	end);
end;

Auxiliary.NewSideRocks = function(TargetObject, Parameters: {any})
	local Side: string = Parameters[1] or 'Look'
	local Duration: number = Parameters[2] or 1
	local MinSize: number = Parameters[3] or 1
	local MaxSize: number = Parameters[4] or 1
	local WaitInterval: number = Parameters[5] or 0.058823529411764705
	local RepeatCount: number = Parameters[6] or 2
	local EndTime: number = os.clock() + Duration;

	local function GenerateEnvironment(Index: number)
		local PointData = RockGenerationData[Side].Points[Index];
		local PointGenerator = RockGenerationData[Side].Generate;
		local IterationCount: number = 0;
		while true do
			IterationCount = IterationCount + 1;
			local PositionOffset: CFrame = TargetObject.CFrame * CFrame.new(PointData) * CFrame.new(0, -2, 0) * CFrame.new(PointGenerator() * MaxSize)
			local GroundRay: RaycastResult = workspace:Raycast(PositionOffset.Position, Vector3.yAxis * -2, AuxiliaryShared.RayParams.Map)
			if GroundRay then
				GenerateRock(IterationCount, MinSize, RepeatCount, GroundRay);
			end;
			task.wait(WaitInterval);
			if EndTime < os.clock() then
				return;
			end;
		end;
	end;
	task.spawn(GenerateEnvironment, 1);
	task.spawn(GenerateEnvironment, 2);
end;

Auxiliary.Explode = function(Origin: CFrame | Vector3, Params: {any})
	Params = Params or {};
	local OriginPos = (typeof(Origin) == 'CFrame' and Origin.Position) or Origin;
	
	local Ground = FetchGround(OriginPos+Vector3.yAxis*2,Params.RayRange or 10);
	if not Ground then return end;
	
	Origin = (typeof(Origin) == 'CFrame' and (Origin - Origin.Position) + Ground.Position) or CFrame.new(Ground.Position, Ground.Position + Ground.Normal);-- * CFrame.Angles(math.rad(-90),0,0);
	
	local BaseRockCount = Params.Rocks or 10; -- Base rock count for how many pieces of rocks are to explode
	local SizeMagnitude = Params.SizeMagnitude or .8; -- Size magnitude for the rocks
	local Distance = Params.MaxDistance or 3; -- Max distance from center for rocks to spawn
	local HorizontalVelocity = Params.HorizontalVelocity or 13; -- Max horizontal velocity
	local VerticalVelocity = Params.VerticalVelocity or 10; -- Max vertical velocity
	local BaseLifespan = Params.Lifespan or 3; -- Base rock lifespan
	
	local RockCount = BaseRockCount + math.random(-3,3);
	
	local function CreateRock()
		local Sizes = {};
		for i = 1,3 do
			table.insert(Sizes, SizeMagnitude*AuxiliaryShared.Ran:NextNumber(.8,1.2));
		end;
		local RockSize = Vector3.new(table.unpack(Sizes));
		
		local StartPos = Ground.Position + Vector3.new(AuxiliaryShared.Ran:NextNumber(-Distance, Distance),RockSize.Y+.3,AuxiliaryShared.Ran:NextNumber(-Distance, Distance));
		
		local NewRock = Instance.new('Part');
		NewRock.Anchored, NewRock.CanCollide = false, not Params.NoCollide;
		NewRock.Color, NewRock.Material = Ground.Color, Ground.Material;
		
		NewRock.Position = StartPos;
		
		NewRock.Size = RockSize;
		NewRock.Orientation = AuxiliaryShared.GetRandomOrientation();
		
		NewRock.CustomPhysicalProperties = PhysicalProperties.new(.3,0,0,0,1);
		NewRock.CollisionGroup = 'Debris';

		local forwardDirection = Origin.LookVector
		local randomizedDirection = Vector3.new(
			forwardDirection.X + AuxiliaryShared.Ran:NextNumber(-0.2, 0.2), 
			forwardDirection.Y + AuxiliaryShared.Ran:NextNumber(-0.2, 0.2), 
			forwardDirection.Z + AuxiliaryShared.Ran:NextNumber(-0.2, 0.2)
		).Unit
		
		local impulseStrength = Vector3.new(
			randomizedDirection.X * AuxiliaryShared.Ran:NextNumber(HorizontalVelocity*.7, HorizontalVelocity),
			randomizedDirection.Y * AuxiliaryShared.Ran:NextNumber(VerticalVelocity*.1, VerticalVelocity),
			randomizedDirection.Z * AuxiliaryShared.Ran:NextNumber(HorizontalVelocity*.7, HorizontalVelocity)
		)

		NewRock.Parent = Effects;
		NewRock:ApplyImpulse(impulseStrength * RockSize)
		
		if Params.NoCollide then 
			Debris:AddItem(NewRock, Params.Lifespan or 20);
			return;
		end;
		task.wait(BaseLifespan*AuxiliaryShared.Ran:NextNumber(.8,1.2));
		
		local TweenTime = AuxiliaryShared.Ran:NextNumber(.7,1.3);
		TweenService:Create(NewRock, TweenInfo.new(TweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = Vector3.zero}):Play();
		Debris:AddItem(NewRock, TweenTime);
	end;
	
	for i: number = 1,RockCount do
		task.spawn(CreateRock);
	end;
end;

Auxiliary.SideCrater = function(Params: {any})
	local Origin: CFrame = Params.Origin;
	
	local Distance: number = Params.Distance or 35;
	local Iterations: number = Params.Iterations or 10;
	local Lifetime: number = Params.Lifetime or 10;
	local SpacedOut = Params.SpacedOut or 13;
	local Scale = Params.Scale or 1;
	
	local DisappearTime = Params.DisappearTime or 1.5;
	local AppearTime = Params.AppearTime or .2
	
	local HideFactor = Params.HideFactor or {.3,.4};
	
	local MinSpace = SpacedOut*.3;
	
	local IterationDelay = Params.IterationDelay;
	
	local TargetPoint = Origin * CFrame.new(0,0,-Distance);
	
	local function CreateRock(GroundRay, Section: CFrame, Side: boolean, SpaceDistance: number)
		if Params.SpaceVariation then
			SpaceDistance *= AuxiliaryShared.Ran:NextNumber(Params.SpaceVariation[1], Params.SpaceVariation[2]);
		end;
		
		local NewRock = Instance.new('Part');
		NewRock.Anchored, NewRock.CanCollide = true, false;
		
		NewRock.Color, NewRock.Material = GroundRay.Color, GroundRay.Material;
		NewRock.Size = Vector3.new(AuxiliaryShared.Ran:NextNumber(.9,1.1), AuxiliaryShared.Ran:NextNumber(.9,1.1), AuxiliaryShared.Ran:NextNumber(.9,1.4)) * Scale;
		
		local RotatedAngle = AuxiliaryShared.Ran:NextNumber(13,20);
		if not Side then
			RotatedAngle = -RotatedAngle;
		end;
		
		local RockPos: Vector3 = (Section * CFrame.new((Side and SpaceDistance) or -SpaceDistance, 0, 0)).Position;
		local RockCFrame = (CFrame.new(RockPos, Section.Position) * CFrame.Angles(math.rad(AuxiliaryShared.Ran:NextNumber(45,60)),0,
			math.rad(RotatedAngle))
		) - 
			Vector3.new(0,NewRock.Size.Y*AuxiliaryShared.Ran:NextNumber(table.unpack(HideFactor)),0);
		
		NewRock.CFrame = RockCFrame;
		NewRock.Position -= Vector3.new(0,NewRock.Size.Y*2,0);
		
		NewRock.Parent = Effects;
		
		TweenService:Create(NewRock, TweenInfo.new(AppearTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = RockCFrame}):Play();
		task.wait(Lifetime);
		TweenService:Create(NewRock, TweenInfo.new(DisappearTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = RockCFrame.Position - Vector3.new(0,NewRock.Size.Y*2,0)}):Play();
		Debris:AddItem(NewRock, DisappearTime);
	end;
	
	for i = 1,Iterations do
		task.spawn(function()
			local Alpha = i/Iterations;
			local Section: CFrame = Origin:Lerp(TargetPoint, Alpha);
			local Ground = FetchGround(Section.Position + Vector3.yAxis*2, 10);
			if not Ground then return end;
			
			local SpaceDistance = AuxiliaryShared.Lerp(MinSpace, SpacedOut, Alpha)
			
			local Oriented: CFrame = (Section-Section.Position) + Ground.Position;
			for i = 1,2 do
				task.spawn(CreateRock, Ground, Oriented, i==1, SpaceDistance);
			end;
		end);
		
		if IterationDelay then
			task.wait(IterationDelay);
		end;
	end;
end;

return Auxiliary;