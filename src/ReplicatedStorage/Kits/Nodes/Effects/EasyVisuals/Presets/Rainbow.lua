local TextEffects = require(script.Parent.Parent);

return function(uiInstance: GuiObject, speed: number,Size,CustomColor)

	local mainGradient 
	if CustomColor then
		mainGradient = TextEffects.Gradient.new(uiInstance, CustomColor, 0);
	else
		mainGradient = TextEffects.Gradient.new(uiInstance, TextEffects.Templates.Rainbow.Color, 0);
	end
  
	mainGradient:SetOffsetSpeed(speed, 1);
	mainGradient:SetRotation(45,1);
    return {
        Effects = { mainGradient }
    };
end