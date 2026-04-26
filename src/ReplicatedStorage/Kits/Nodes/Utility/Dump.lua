local dump = {}

dump.new = function(list)
	local self = setmetatable({
		List = {};
	}, {
		__index = dump,
		__add = function(self, val)
			self:Add(val)
			return self
		end,
	})
	
	list = typeof(list) ~= "table" and {list} or list
	for i, v in list do
		self:AddIndex(i, v)
	end
	
	return self
end

function dump:AddIndex(i, v)
	if typeof(v) == "function" then
		v = coroutine.create(v)
		coroutine.resume(v)
	end

	local prev = self.List[i]
	if prev then self:Clear(i, "Whitelist") end
	self.List[i] = v
end

function dump:ClearIndex(i)
	local v = self.List[i]
	if not v then return end
	
	if typeof(v) == "RBXScriptConnection" then
		v:Disconnect()
	elseif typeof(v) == "thread" then
		task.defer(coroutine.close, v)
	elseif typeof(v) == "Instance" then
		if v:IsA("Tween") then
			v:Cancel()
		else
			v:Destroy()
		end
	end
end

function dump:Add(...)
	for _, v in {...} do
		self:AddIndex(#self.List+1, v)
	end
end

function dump:Clear(...)
	local ignore = {...}
	local whitelist = ignore[#ignore] == "Whitelist"
	
	for i, v in self.List do
		if (table.find(ignore, i) and not whitelist) or (not table.find(ignore, i) and whitelist) then continue end
		self:ClearIndex(i)
	end
end

function dump:ResetIndex(i, f)
	self:ClearIndex(i)
	self:AddIndex(i, f)
end

function dump:Reset(...)
	self:Clear()
	self:Add(...)
end

return dump