local sharedModule = {}

setmetatable(sharedModule,{
	__index = function(tbl,index)
		if typeof(index) == "string" then
			local module = script:FindFirstChild(index)
			if module then
				rawset(sharedModule,index,require(module))
			end
			return rawget(sharedModule,index)
		end
	end
})

return sharedModule
