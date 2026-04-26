local self = {}

for _, Folder in script:GetChildren() do
	for _, v in Folder:GetChildren() do
		self[v.Name] = require(v)
 	end
end

return self