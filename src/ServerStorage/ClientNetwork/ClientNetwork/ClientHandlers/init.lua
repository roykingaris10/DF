return function(Client)
	local Modules = {}
	for _,Module in script:GetChildren() do
		local moduleResult = require(Module)(Client)

		-- If the module returns a table of functions, merge them into Modules
		if type(moduleResult) == "table" then
			for funcName, func in pairs(moduleResult) do
				Modules[funcName] = func
			end
		end
	end
return Modules end