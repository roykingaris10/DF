local RunService = game:GetService('RunService');

return {
	Shared = require(script.Shared);
	Rock = require(script.Rock);
	Client = (RunService:IsClient() and require(script.Client));
	
	Mouse = (RunService:IsClient() and require(script.Mouse));
	RayMouse = (RunService:IsClient() and require(script.MouseModule));
	
	VFX = (RunService:IsClient() and require(script.VFX));
};