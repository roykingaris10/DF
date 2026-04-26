local Debris = {};
Debris.Removing = {};

function Debris:AddItem(Item: Instance, Duration: number)
	Debris.Removing[Item] = true;
	
	task.delay(Duration, function()
		if not Item:IsDescendantOf(game) then return end;
		if not Debris.Removing[Item] then return end;
		
		Debris.Removing[Item] = nil;
		Item:Destroy();
	end)
end;

function Debris:RemoveItem(Item: Instance)
	if not Debris.Removing[Item] then return end;
	Debris.Removing[Item] = nil;
end;

return Debris; 