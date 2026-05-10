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
			Ambient = Color3.fromRGB(78, 88, 118),
			OutdoorAmbient = Color3.fromRGB(95, 110, 145),
			Brightness = 1.35,
			ColorShift_Top = Color3.fromRGB(115, 140, 195),
			ColorShift_Bottom = Color3.fromRGB(60, 75, 115),
			FogColor = Color3.fromRGB(60, 78, 120),
			FogEnd = 2400,
			FogStart = 0,
		},
		[5] = {
			Ambient = Color3.fromRGB(95, 95, 115),
			OutdoorAmbient = Color3.fromRGB(120, 115, 135),
			Brightness = 1.4,
			ColorShift_Top = Color3.fromRGB(140, 120, 155),
			ColorShift_Bottom = Color3.fromRGB(75, 70, 90),
			FogColor = Color3.fromRGB(100, 95, 125),
			FogEnd = 2200,
			FogStart = 0,
		},
		[6] = {
			Ambient = Color3.fromRGB(120, 110, 105),
			OutdoorAmbient = Color3.fromRGB(170, 145, 130),
			Brightness = 1.7,
			ColorShift_Top = Color3.fromRGB(235, 175, 145),
			ColorShift_Bottom = Color3.fromRGB(105, 90, 85),
			FogColor = Color3.fromRGB(225, 190, 170),
			FogEnd = 2400,
			FogStart = 0,
		},
		[8] = {
			Ambient = Color3.fromRGB(155, 155, 155),
			OutdoorAmbient = Color3.fromRGB(185, 185, 185),
			Brightness = 2.1,
			ColorShift_Top = Color3.fromRGB(255, 250, 245),
			ColorShift_Bottom = Color3.fromRGB(155, 155, 150),
			FogColor = Color3.fromRGB(205, 220, 245),
			FogEnd = 3000,
			FogStart = 0,
		},
		[12] = {
			Ambient = Color3.fromRGB(185, 185, 185),
			OutdoorAmbient = Color3.fromRGB(205, 205, 205),
			Brightness = 2.6,
			ColorShift_Top = Color3.fromRGB(255, 255, 255),
			ColorShift_Bottom = Color3.fromRGB(185, 185, 180),
			FogColor = Color3.fromRGB(215, 230, 252),
			FogEnd = 3500,
			FogStart = 0,
		},
		[16] = {
			Ambient = Color3.fromRGB(175, 170, 160),
			OutdoorAmbient = Color3.fromRGB(200, 190, 175),
			Brightness = 2.25,
			ColorShift_Top = Color3.fromRGB(255, 235, 210),
			ColorShift_Bottom = Color3.fromRGB(155, 145, 130),
			FogColor = Color3.fromRGB(245, 230, 215),
			FogEnd = 2600,
			FogStart = 0,
		},
		[18] = {
			Ambient = Color3.fromRGB(140, 120, 115),
			OutdoorAmbient = Color3.fromRGB(180, 150, 140),
			Brightness = 1.85,
			ColorShift_Top = Color3.fromRGB(240, 165, 135),
			ColorShift_Bottom = Color3.fromRGB(120, 95, 90),
			FogColor = Color3.fromRGB(225, 175, 155),
			FogEnd = 2000,
			FogStart = 0,
		},
		[19] = {
			Ambient = Color3.fromRGB(110, 105, 130),
			OutdoorAmbient = Color3.fromRGB(140, 130, 160),
			Brightness = 1.55,
			ColorShift_Top = Color3.fromRGB(195, 155, 180),
			ColorShift_Bottom = Color3.fromRGB(90, 80, 110),
			FogColor = Color3.fromRGB(160, 140, 175),
			FogEnd = 1900,
			FogStart = 0,
		},
		[20] = {
			Ambient = Color3.fromRGB(95, 100, 130),
			OutdoorAmbient = Color3.fromRGB(115, 125, 165),
			Brightness = 1.45,
			ColorShift_Top = Color3.fromRGB(120, 130, 185),
			ColorShift_Bottom = Color3.fromRGB(70, 80, 115),
			FogColor = Color3.fromRGB(85, 95, 145),
			FogEnd = 2100,
			FogStart = 0,
		},
		[22] = {
			Ambient = Color3.fromRGB(80, 90, 120),
			OutdoorAmbient = Color3.fromRGB(100, 115, 150),
			Brightness = 1.35,
			ColorShift_Top = Color3.fromRGB(95, 120, 185),
			ColorShift_Bottom = Color3.fromRGB(55, 70, 110),
			FogColor = Color3.fromRGB(60, 80, 130),
			FogEnd = 2300,
			FogStart = 0,
		},
	},

	Atmosphere = {
		[0] = {Density = 0.22, Offset = 0.12, Haze = 1.2, Glare = 0, Decay = Color3.fromRGB(70, 95, 140)},
		[6] = {Density = 0.25, Offset = 0.18, Haze = 1.6, Glare = 0.22, Decay = Color3.fromRGB(220, 175, 145)},
		[12] = {Density = 0.23, Offset = 0.25, Haze = 1.4, Glare = 0.08, Decay = Color3.fromRGB(205, 220, 250)},
		[18] = {Density = 0.27, Offset = 0.15, Haze = 1.7, Glare = 0.25, Decay = Color3.fromRGB(225, 155, 130)},
		[19] = {Density = 0.25, Offset = 0.13, Haze = 1.4, Glare = 0.12, Decay = Color3.fromRGB(170, 140, 165)},
		[22] = {Density = 0.22, Offset = 0.11, Haze = 1.0, Glare = 0, Decay = Color3.fromRGB(75, 100, 150)},
	},

	ColorCorrection = {
		[0] = {Saturation = -0.05, Contrast = 0.08, Brightness = 0.06, TintColor = Color3.fromRGB(185, 210, 255)},
		[6] = {Saturation = 0.06, Contrast = 0.09, Brightness = 0.02, TintColor = Color3.fromRGB(250, 240, 235)},
		[12] = {Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Color3.fromRGB(255, 255, 255)},
		[18] = {Saturation = 0.1, Contrast = 0.1, Brightness = 0.02, TintColor = Color3.fromRGB(250, 230, 225)},
		[19] = {Saturation = 0.06, Contrast = 0.07, Brightness = 0.04, TintColor = Color3.fromRGB(225, 215, 240)},
		[22] = {Saturation = -0.06, Contrast = 0.08, Brightness = 0.05, TintColor = Color3.fromRGB(175, 205, 250)},
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
		New = 0.72,
		WaxingCrescent = 0.8,
		FirstQuarter = 0.86,
		WaxingGibbous = 0.93,
		Full = 1.0,
		WaningGibbous = 0.93,
		ThirdQuarter = 0.86,
		WaningCrescent = 0.8,
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