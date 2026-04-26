local LibraryInfo = {}

function mergeDictionaries(...)

	for _, dictionary in ipairs({...}) do
		for key, value in pairs(dictionary) do
			LibraryInfo[key] = value
		end
	end

	return LibraryInfo
end

for i,v in pairs(script:GetChildren()) do 
	local infoHolder = require(v)
	
	mergeDictionaries(infoHolder)
end

return LibraryInfo
