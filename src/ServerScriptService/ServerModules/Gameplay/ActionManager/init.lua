--//Variable
local Server = require(script.Parent)
local Network = Server.Network
local LibraryInfo = Server.LibraryInfo

local ServerScriptService = game:GetService('ServerScriptService');
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService('Players');
local RunService = game:GetService("RunService")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local Maid = require(Nodes.Utility.Maid)

local ServerSkills = script.ServerSkills

local ActionManager = {};

local Validator = require(script.Validator)(Server);
ActionManager.Validator = Validator
ActionManager.ActionCache = {}
local function LoadFolder(folder, container)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			container[child.Name] = require(child)(Server)

		elseif child:IsA("Folder") then
			container[child.Name] = {}
			LoadFolder(child, container[child.Name])
		end
	end
end
LoadFolder(ServerSkills, ActionManager.ActionCache)

local function FetchMoveDataByName(ClassName, SkillName: string)
	if not LibraryInfo[ClassName] then return end
	local CharacterMoveset = LibraryInfo[ClassName].Moveset;

	for _,MoveData: {any} in CharacterMoveset do
		if MoveData.Name == SkillName then
			return MoveData;
		end;
	end;
end;

--//Module

ActionManager.__index = ActionManager;

ActionManager.new = function(Entity: {any})
	local self = setmetatable({
		
		Parent = Entity;	
		Validator = Validator;
		
		ActiveActions = {};
		
		_Connections = {};
		_Cached = {};
		
	}, ActionManager);
	
	return self;
end;

function ActionManager:Fetch(SkillName: string)
	return ActionManager.ActionCache[SkillName];
end;


function ActionManager:StartAction(ActionPathing, ...)
	local actionModule = ActionManager.ActionCache
	for _, key in ipairs(ActionPathing) do
		actionModule = actionModule[key]
		if not actionModule then
			warn("Action '" .. table.concat(ActionPathing, "/") .. "' not found.")
			return
		end
	end

	local ActionClass = actionModule
	local instance = ActionClass.new(self.Parent)
	self.ActiveActions[table.concat(ActionPathing, "/")] = instance
	local Args = ...

	self.Parent.Server.Held[ActionPathing[#ActionPathing]] = Args.Held;
	
	task.spawn(function() instance:Start(Args) end)
	return instance
end;

function ActionManager:Destroy()
	for _,v:RBXScriptConnection in self._Connections do
		v:Disconnect();
	end;
end;


return ActionManager;