local TimeConfig = {}

TimeConfig.Time = {
	TimeScale = 24, -- 1 real hour = 1 in-game day
	StartTime = 8,

	Periods = {
		Dawn = {start = 5, finish = 7},
		Morning = {start = 7, finish = 12},
		Afternoon = {start = 12, finish = 17},
		Dusk = {start = 17, finish = 19},
		Evening = {start = 19, finish = 22},
		Night = {start = 22, finish = 5},
	},
}

TimeConfig.Lighting = {
	TimeOfDay = {
		[0] = {
			Ambient = Color3.fromRGB(30, 35, 50),
			OutdoorAmbient = Color3.fromRGB(40, 45, 70),
			Brightness = 0.5,
			ColorShift_Top = Color3.fromRGB(50, 60, 100),
			ColorShift_Bottom = Color3.fromRGB(20, 25, 40),
			FogColor = Color3.fromRGB(20, 25, 45),
			FogEnd = 800,
			FogStart = 50,
		},
		[5] = {
			Ambient = Color3.fromRGB(50, 50, 65),
			OutdoorAmbient = Color3.fromRGB(70, 65, 85),
			Brightness = 0.7,
			ColorShift_Top = Color3.fromRGB(90, 75, 110),
			ColorShift_Bottom = Color3.fromRGB(40, 35, 50),
			FogColor = Color3.fromRGB(55, 50, 75),
			FogEnd = 1000,
			FogStart = 20,
		},
		[6] = {
			Ambient = Color3.fromRGB(100, 95, 90),
			OutdoorAmbient = Color3.fromRGB(150, 130, 120),
			Brightness = 1.1,
			ColorShift_Top = Color3.fromRGB(230, 170, 140),
			ColorShift_Bottom = Color3.fromRGB(90, 75, 70),
			FogColor = Color3.fromRGB(220, 180, 160),
			FogEnd = 1500,
			FogStart = 0,
		},
		[8] = {
			Ambient = Color3.fromRGB(150, 150, 150),
			OutdoorAmbient = Color3.fromRGB(180, 180, 180),
			Brightness = 2,
			ColorShift_Top = Color3.fromRGB(255, 250, 245),
			ColorShift_Bottom = Color3.fromRGB(150, 150, 145),
			FogColor = Color3.fromRGB(200, 215, 240),
			FogEnd = 2500,
			FogStart = 0,
		},
		[12] = {
			Ambient = Color3.fromRGB(180, 180, 180),
			OutdoorAmbient = Color3.fromRGB(200, 200, 200),
			Brightness = 2.5,
			ColorShift_Top = Color3.fromRGB(255, 255, 255),
			ColorShift_Bottom = Color3.fromRGB(180, 180, 175),
			FogColor = Color3.fromRGB(210, 225, 250),
			FogEnd = 3000,
			FogStart = 0,
		},
		[16] = {
			Ambient = Color3.fromRGB(170, 165, 155),
			OutdoorAmbient = Color3.fromRGB(195, 185, 170),
			Brightness = 2.2,
			ColorShift_Top = Color3.fromRGB(255, 235, 210),
			ColorShift_Bottom = Color3.fromRGB(150, 140, 125),
			FogColor = Color3.fromRGB(240, 225, 210),
			FogEnd = 2200,
			FogStart = 0,
		},
		[18] = {
			Ambient = Color3.fromRGB(130, 110, 105),
			OutdoorAmbient = Color3.fromRGB(170, 140, 130),
			Brightness = 1.6,
			ColorShift_Top = Color3.fromRGB(235, 160, 130),
			ColorShift_Bottom = Color3.fromRGB(110, 85, 80),
			FogColor = Color3.fromRGB(220, 170, 150),
			FogEnd = 1400,
			FogStart = 0,
		},
		[19] = {
			Ambient = Color3.fromRGB(90, 85, 100),
			OutdoorAmbient = Color3.fromRGB(120, 110, 135),
			Brightness = 1.2,
			ColorShift_Top = Color3.fromRGB(180, 140, 160),
			ColorShift_Bottom = Color3.fromRGB(70, 65, 85),
			FogColor = Color3.fromRGB(140, 120, 150),
			FogEnd = 1100,
			FogStart = 10,
		},
		[20] = {
			Ambient = Color3.fromRGB(65, 65, 85),
			OutdoorAmbient = Color3.fromRGB(85, 85, 115),
			Brightness = 0.9,
			ColorShift_Top = Color3.fromRGB(100, 95, 140),
			ColorShift_Bottom = Color3.fromRGB(45, 45, 70),
			FogColor = Color3.fromRGB(70, 65, 100),
			FogEnd = 950,
			FogStart = 25,
		},
		[22] = {
			Ambient = Color3.fromRGB(40, 45, 60),
			OutdoorAmbient = Color3.fromRGB(50, 55, 80),
			Brightness = 0.6,
			ColorShift_Top = Color3.fromRGB(60, 70, 110),
			ColorShift_Bottom = Color3.fromRGB(25, 30, 50),
			FogColor = Color3.fromRGB(30, 35, 60),
			FogEnd = 900,
			FogStart = 40,
		},
	},

	Atmosphere = {
		[0] = {Density = 0.35, Offset = 0.1, Haze = 1.5, Glare = 0, Decay = Color3.fromRGB(40, 50, 80)},
		[6] = {Density = 0.28, Offset = 0.18, Haze = 1.8, Glare = 0.2, Decay = Color3.fromRGB(220, 170, 140)},
		[12] = {Density = 0.25, Offset = 0.25, Haze = 1.6, Glare = 0.08, Decay = Color3.fromRGB(200, 210, 250)},
		[18] = {Density = 0.32, Offset = 0.15, Haze = 1.9, Glare = 0.25, Decay = Color3.fromRGB(220, 150, 130)},
		[19] = {Density = 0.35, Offset = 0.12, Haze = 1.6, Glare = 0.1, Decay = Color3.fromRGB(160, 130, 150)},
		[22] = {Density = 0.4, Offset = 0.1, Haze = 1.2, Glare = 0, Decay = Color3.fromRGB(50, 60, 100)},
	},

	ColorCorrection = {
		[0] = {Saturation = -0.1, Contrast = 0.05, TintColor = Color3.fromRGB(200, 210, 255)},
		[6] = {Saturation = 0.05, Contrast = 0.08, TintColor = Color3.fromRGB(250, 240, 235)},
		[12] = {Saturation = 0, Contrast = 0, TintColor = Color3.fromRGB(255, 255, 255)},
		[18] = {Saturation = 0.08, Contrast = 0.08, TintColor = Color3.fromRGB(250, 235, 230)},
		[19] = {Saturation = 0.05, Contrast = 0.06, TintColor = Color3.fromRGB(235, 225, 240)},
		[22] = {Saturation = -0.12, Contrast = 0.06, TintColor = Color3.fromRGB(190, 200, 225)},
	},
}

TimeConfig.Moon = {
	PhaseCycleDays = 8,
	Phases = {
		"New",
		"WaxingCrescent",
		"FirstQuarter",
		"WaxingGibbous",
		"Full",
		"WaningGibbous",
		"ThirdQuarter",
		"WaningCrescent",
	},
	PhaseBrightness = {
		New = 0.3,
		WaxingCrescent = 0.5,
		FirstQuarter = 0.7,
		WaxingGibbous = 0.85,
		Full = 1.0,
		WaningGibbous = 0.85,
		ThirdQuarter = 0.7,
		WaningCrescent = 0.5,
	},
}

function TimeConfig:GetTimePeriod(clockTime)
	for periodName, period in pairs(self.Time.Periods) do
		if period.start <= period.finish then
			if clockTime >= period.start and clockTime < period.finish then
				return periodName
			end
		else
			if clockTime >= period.start or clockTime < period.finish then
				return periodName
			end
		end
	end
	return "Unknown"
end

function TimeConfig:IsNightTime(clockTime)
	return clockTime >= 20 or clockTime < 6
end

function TimeConfig:IsDayTime(clockTime)
	return clockTime >= 6 and clockTime < 20
end

return TimeConfig