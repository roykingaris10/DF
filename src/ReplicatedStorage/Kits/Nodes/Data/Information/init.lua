--//Variables
local function DeepFreeze(tbl: {any})
	table.freeze(tbl)
	for _, v in pairs(tbl) do
		if type(v) == "table" then
			DeepFreeze(v)
		end
	end
	
	return tbl;
end;

function GetPath(Bottom, Top)
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

--//Module
local Information = {};
Information._Cached = {};

function Information:_Cache()
	for _,v: ModuleScript? in script:GetDescendants() do
		if not v:IsA('ModuleScript') then continue end;
		Information._Cached[GetPath(v, script)] = DeepFreeze(require(v));
	end;
end;

function Information:Get(Str: string)
	return Information._Cached[Str];
end;

return Information;