local RegionConfig = {
	Major = {
		StarterTown = {
			DisplayName = "Starter Town",
			Subtitle = "The Town of the Beginning and End",
			-- Single track (plays for all times)
			Music = "rbxassetid://1", ---"rbxassetid://88397674474346",
			Volume = 0,
			EnterSFX =  "rbxassetid://1",
			Chatter = true,
			ChatterSounds = {
				"rbxassetid://126127022308564",
			},
			ClimateZone = "Default",
			UIStyle = {
				PrimaryColor = Color3.fromRGB(139, 90, 43),
				Icon = "rbxassetid://",
			},
		},
		LogueTown = {
			DisplayName = "Logue Town",
			Subtitle = "The people labour, in hopes of liberation.",
			-- Day/Night variants (optional)
			Music = {
				Day = "rbxassetid://79556994575040",
				Night = "rbxassetid://79556994575041", -- Different night track
			},
			Volume = 0.1,
			EnterSFX = "rbxassetid://987654322",
			Chatter = true,
			ChatterSounds = {
				"rbxassetid://126127022308564",
			},
			ClimateZone = "Default",
			UIStyle = {
				PrimaryColor = Color3.fromRGB(255, 255, 127),
				Icon = "rbxassetid://",
			},
		},
		
		LalaLand = {
			DisplayName = "Lala Land",
			Subtitle = "These dreams are not yours",
			-- Day/Night variants (optional)
			Music = {
				Day = "rbxassetid://79556994575040",
				Night = "rbxassetid://79556994575041", -- Different night track
			},
			Volume = 0.1,
			EnterSFX = "rbxassetid://987654322",
			Chatter = true,
			ChatterSounds = {
				"rbxassetid://126127022308564",
			},
			ClimateZone = "Default",
			UIStyle = {
				PrimaryColor = Color3.fromRGB(255, 255, 127),
				Icon = "rbxassetid://",
			},
		},
		
		TownHall = {
			DisplayName = "The Town Hall",
			Subtitle = "The community gathers for special events.",
			Music = "rbxassetid://123456790",
			Volume = 0.1,
			EnterSFX = "rbxassetid://987654322",
			Chatter = true,
			ChatterSounds = {},
			ClimateZone = "Default",
			UIStyle = {
				PrimaryColor = Color3.fromRGB(50, 80, 150),
				Icon = "rbxassetid://",
			},
		},
	},
	Minor = {
		TheDocks = {
			DisplayName = "The Docks",
			Subtitle = "Set your sights on the blues ahead.",
			Music = "rbxassetid://123456791",
			Volume = 0.1,
			EnterSFX = "rbxassetid://987654323",
			Chatter = true,
			ChatterSounds = {
				"rbxassetid://126127022308564",
			},
			ClimateZone = "Default",
			UIStyle = {
				PrimaryColor = Color3.fromRGB(180, 120, 60),
				Icon = "rbxassetid://333333335",
			},
		},
		BellemerePub = {
			DisplayName = "Bellemere's Bar",
			Subtitle = "",
			Music = "rbxassetid://123456791",
			Volume = 0.1,
			EnterSFX = "rbxassetid://987654323",
			Chatter = true,
			ChatterSounds = {},
			ClimateZone = "Default",
			UIStyle = {
				PrimaryColor = Color3.fromRGB(180, 120, 60),
				Icon = "rbxassetid://333333335",
			},
		},
	},
	Special = {
		GolDRogerExecution = {
			DisplayName = "Execution Platform",
			Subtitle = "Where the Pirate King met his end",
			Music = "rbxassetid://123456792",
			Volume = 0.15,
			EnterSFX = "rbxassetid://987654324",
			Chatter = false,
			ClimateZone = "Default",
			UIStyle = {
				PrimaryColor = Color3.fromRGB(80, 80, 80),
				Icon = "rbxassetid://333333336",
			},
		},
	},
	Default = {
		DisplayName = "",
		Subtitle = "",
		Music = "",
		Volume = 0.1,
		Chatter = false,
	},
}

function RegionConfig:GetRegion(regionType, regionName)
	if self[regionType] and self[regionType][regionName] then
		return self[regionType][regionName], regionType
	end
	return nil, nil
end

return RegionConfig