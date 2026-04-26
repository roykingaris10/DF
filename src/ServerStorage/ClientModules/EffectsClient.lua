return function(Client)
	local EffectsClient = {}
	EffectsClient._Cache = {};
	local player = Client.player
	local Network = Client.Network
	local Utilities = Client.Utilities
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	local Kits = ReplicatedStorage.Kits
	local Nodes = Kits.Nodes
	local Auxiliary = require(Nodes.Utility.Auxiliary);
	
	local EffectsFolder = Nodes.EffectsModules
	
	local Modules = script:GetDescendants()
	
	
	
--	local BasicEffects = require(script.BasicEffect)(Client)
--	local UIEffects = require(script.UIEffect)(Client)
--[[
	for _,v: ModuleScript in script:GetChildren() do
		if not v:IsA('ModuleScript') then continue end;
		EffectsClient._Cache[Auxiliary.Shared.GetPath(v, script)] = require(v)(Client);
	end
	]]
	function EffectsClient.IsCaster(Entity: {any})
		if Entity.player == player then
			return true;
		elseif Entity.Character.Rig == player.Character then
			return true;
		end;

		return false;
	end;
	
	function EffectsClient.GetMockEntity(Target: Player | Model)
		local IsPlayer = Target:IsA('Player');
		local Character = (IsPlayer and Target.Character) or Target;

		return {
			Player = IsPlayer and Target;
			Character = {
				Humanoid = Character.Humanoid;
				Root = Character:WaitForChild('HumanoidRootPart');
				Rig = Character;
			};
		};
	end;
	
	--[[
	function EffectsClient.Execute(Params: {any})
		local ModulePath = Params.Module;
		local SubModule = Params.SubModule
		local EffectName = Params.Effect;
	--	local EffectModule = EffectsClient._Cache[ModulePath];
		local EffectModule = EffectsClient._Cache[ModulePath][SubModule];
		assert(EffectModule, debug.traceback('Could not find VFX module!'));

		local Caster = Params.Caster;
		if not Caster.Character.Root then return end;

		Caster.IsClient = EffectsClient.IsCaster(Caster);

		--Simple VFX optimization based on distance, for more complex conditions to run VFX the calling module function should handle it
		if not Caster.IsClient and Params.MaxDistance and not Auxiliary.Client.CheckCameraDistance(Caster.Character.Root.Position, Params.MaxDistance) then 
			return;
		end;
		if not EffectModule[EffectName] then warn("MISSING FUNCTION INSIDE MODULE ".. SubModule) return end
		task.spawn(EffectModule[EffectName], Caster, Params.Data, Params.ServerCall);
	end;
	]]
	
	function EffectsClient:Execute(EffectData: {any}, EffectInfo: {any})
		if not EffectData.Func then warn("NO EFFECT FUNC") return end
		local EffectModule = EffectData.EffectModule
		EffectModule = EffectsClient._Cache[EffectModule]
		if not EffectModule then warn("NO PRELOADED EFFECT MODULE "..EffectData.EffectModule.Name) return end
		
		local Caster = EffectData.Caster;
		if not Caster.Character.Root then return end;

--		Caster.IsClient = EffectsClient.IsCaster(Caster);
--		if not Caster.IsClient then return end
		
		if not EffectModule[EffectData.Func] then warn("MISSING FUNCTION INSIDE MODULE "..EffectData.Func) return end
		
		task.spawn(EffectModule[EffectData.Func], Caster, EffectInfo, EffectData.ServerCall);
	end
	
	function EffectsClient:Init()
		for i, obj in pairs(EffectsFolder:GetChildren()) do
			if obj:IsA("Folder") then
				for i,module in pairs(obj:GetChildren()) do
					if module:IsA("ModuleScript") then
						local requiredModule = require(module)(Client)
						EffectsClient._Cache[module] = requiredModule
					end
				end
			end
		end
	end
	
	function EffectsClient:Setup()
	--	Network:bindEvent("VFX",EffectsClient.Execute)
	--	EffectsClient._Cache["BasicEffects"]["CombatBasics"]["BasicHit"]()
	end;

	return EffectsClient end

