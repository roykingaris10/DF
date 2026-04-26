local FactionInfo = {}

FactionInfo.LevelRanks = {
	Pirate = {
		{Name = "Unknown", MinLevel = 1},
		{Name = "Troublemaker", MinLevel = 10},
		{Name = "Rising Star", MinLevel = 25},
		{Name = "Wanted", MinLevel = 50},
		{Name = "Dangerous", MinLevel = 75},
		{Name = "Feared", MinLevel = 100},
		{Name = "Supernova", MinLevel = 175},
		{Name = "Warlord", MinLevel = 300},
		{Name = "Emperor Commander", MinLevel = 500},
		{Name = "Emperor", MinLevel = 750},
	},

	Marine = {
		{Name = "Recruit", MinLevel = 1},
		{Name = "Seaman", MinLevel = 10},
		{Name = "Petty Officer", MinLevel = 25},
		{Name = "Ensign", MinLevel = 50},
		{Name = "Lieutenant", MinLevel = 75},
		{Name = "Commander", MinLevel = 100},
		{Name = "Captain", MinLevel = 175},
		{Name = "Rear Admiral", MinLevel = 300},
		{Name = "Vice Admiral", MinLevel = 500},
		{Name = "Admiral", MinLevel = 750},
	},

	Revolutionary = {
		{Name = "Sympathizer", MinLevel = 1},
		{Name = "Supporter", MinLevel = 10},
		{Name = "Member", MinLevel = 25},
		{Name = "Operative", MinLevel = 50},
		{Name = "Officer", MinLevel = 75},
		{Name = "Captain", MinLevel = 100},
		{Name = "Chief of Staff", MinLevel = 175},
		{Name = "Deputy Commander", MinLevel = 300},
		{Name = "Commander", MinLevel = 500},
		{Name = "Army Commander", MinLevel = 750},
		{Name = "Supreme Leader", MinLevel = 750},

	},

	Civilian = {
		{Name = "Civilian", MinLevel = 1}, -- he's a civilly bruv
	},
}

FactionInfo.BountyLevelRequirements = {
	[1000] = 5,
	[10000] = 15,
	[50000] = 30,
	[150000] = 50,
	[500000] = 100,
	[1000000] = 150,
	[5000000] = 250,
	[15000000] = 400,
	[50000000] = 600,
}

FactionInfo.Factions = {
	Pirate = {
		DisplayName = "Pirate",
		EnemyFactions = {"Marine"},
		CanHaveCrew = true,
	},

	Marine = {
		DisplayName = "Marine",
		EnemyFactions = {"Pirate", "Revolutionary"},
		CanHaveCrew = false,
		JoinRequirements = {
			MaxBounty = 0,
		},
	},

	Revolutionary = {
		DisplayName = "Revolutionary Army",
		EnemyFactions = {"Marine"},
		CanHaveCrew = false,
		JoinRequirements = {
			MinLevel = 50,
		},
	},

	Civilian = {
		DisplayName = "Civilian",
		EnemyFactions = {},
		CanHaveCrew = false,
	},
}

FactionInfo.DefaultFaction = "Pirate"

return FactionInfo