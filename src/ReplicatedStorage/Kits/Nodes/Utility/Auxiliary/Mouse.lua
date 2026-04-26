--//Variables
local UserInputService = game:GetService('UserInputService');

local AuxiliaryShared = require(script.Parent.Shared);

local Constants = {
	MAX_DISTANCE = 1000;
};

--//Module
local Auxiliary = {};

function Auxiliary:GetScreenLocation()
	return UserInputService:GetMouseLocation();
end;

function Auxiliary:GetPointing(RayParams: RaycastParams?, MaxDistance: number?)
	local ScreenPos = UserInputService:GetMouseLocation();
	local ViewportRay = workspace.CurrentCamera:ViewportPointToRay(ScreenPos.X, ScreenPos.Y);
	local MaxCastDistance = MaxDistance or Constants.MAX_DISTANCE;
	
	local MouseCast: RaycastResult = workspace:Raycast(ViewportRay.Origin, ViewportRay.Direction*(MaxCastDistance), (RayParams or AuxiliaryShared.RayParams.Map));
	local EndPos = (MouseCast and MouseCast.Position) or ViewportRay.Origin+(ViewportRay.Direction*MaxCastDistance);
	
	return CFrame.new(EndPos, EndPos+ViewportRay.Direction);
end;

function Auxiliary:GetPointingObject(RayParams: RaycastParams?, MaxDistance: number?)
	local ScreenPos = UserInputService:GetMouseLocation();
	
	local ViewportRay = workspace.CurrentCamera:ViewportPointToRay(ScreenPos.X, ScreenPos.Y);
	local MaxCastDistance = MaxDistance or Constants.MAX_DISTANCE;
	local MouseCast: RaycastResult = workspace:Raycast(ViewportRay.Origin, ViewportRay.Direction*(MaxCastDistance), (RayParams or AuxiliaryShared.RayParams.Map));
	
	local ObjectHovered : BasePart = nil;
	if MouseCast and MouseCast.Instance then
		if MouseCast.Instance:IsDescendantOf(workspace.Map.Throwable) then
			ObjectHovered = MouseCast.Instance.Parent;
		end
	end
	
	return ObjectHovered
end

return Auxiliary;