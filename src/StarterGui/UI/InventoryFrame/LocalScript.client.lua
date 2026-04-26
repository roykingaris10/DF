local function UpdateCanvasSize(Canvas, Constraint)
	Canvas.CanvasSize = UDim2.new(0, 0, 0, Constraint.AbsoluteContentSize.Y+20)
end

wait(3)
	UpdateCanvasSize(script.Parent.InvFrame.InvScroll, script.Parent.InvFrame.InvScroll.UIListLayout)

