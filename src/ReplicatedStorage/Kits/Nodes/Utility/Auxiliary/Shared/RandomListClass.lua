local RandomListClass = {};
RandomListClass.__index = RandomListClass;

RandomListClass.new = function(Values: {any}?)
	local self = setmetatable({
		
		_Values = Values;	
		_PrevValue = nil;
		
	}, RandomListClass);
	
	self.RollUnique = false;
	
	return self;
end;

function RandomListClass:UpdateValues(NewValues: {any}?)
	self._Values = NewValues;
end;

function RandomListClass:Roll()
	local RolledIndex = math.random(1,#self._Values);
	local RolledValue = self._Values[RolledIndex];
	
	if self._PrevValue then
		table.insert(self._Values, self._PrevValue);
	end;
	
	self._PrevValue = RolledValue;
	table.remove(self._Values, RolledIndex);
	
	return RolledValue;
end;

return RandomListClass;