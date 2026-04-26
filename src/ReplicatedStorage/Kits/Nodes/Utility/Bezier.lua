-- Functions
local function lerp(a, b, c)
	return a + (b - a) * c
end

return {
	QuadBezier = function(t, p0, p1, p2)
		local l1 = lerp(p0, p1, t)
		local l2 = lerp(p1, p2, t)
		local Quad = lerp(l1, l2, t)
		return Quad
	end,
}