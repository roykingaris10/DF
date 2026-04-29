local QuestInfo = {}

QuestInfo.BanditBeater = {
	Id = "BanditBeater",
	Name = "Bandit Trouble",
	Description = "Soren needs help clearing out the bandits causing trouble around the outskirts.",
	Category = "Normal",
	Giver = "Soren",
	TurnInTo = "Soren",

	Prerequisites = {
		MinLevel = 1,
	},

	Stages = {
		{
			Title = "Defeat the bandits",
			Objectives = {
				{ Id = "kill_bandits", Type = "Kill", Target = "Bandit", Count = 2, Description = "Defeat Bandits" },
			},
		},
		{
			Title = "Report back to Soren",
			Objectives = {
				{ Id = "talk_soren", Type = "Talk", Target = "Soren", Count = 1, Description = "Speak with Soren" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Combat", Amount = 50 },
		{ Type = "Beli", Amount = 100 },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
	Repeatable = false,
	TrackedDefault = true,
}

QuestInfo.SpecialDelivery = {
	Id = "SpecialDelivery",
	Name = "Special Delivery",
	Description = "The Quartermaster needs an urgent package delivered to the docks.",
	Category = "Normal",
	Giver = "Quartermaster",
	TurnInTo = "Dockmaster",

	Prerequisites = {
		CompletedQuests = { "BanditBeater" },
	},

	Stages = {
		{
			Title = "Pick up the package",
			Objectives = {
				{ Id = "pickup", Type = "Talk", Target = "Quartermaster", Count = 1, Description = "Get the package from the Quartermaster" },
			},
		},
		{
			Title = "Deliver to the docks",
			Objectives = {
				{ Id = "deliver", Type = "Talk", Target = "Dockmaster", Count = 1, Description = "Deliver the package to the Dockmaster" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Combat", Amount = 30 },
		{ Type = "Beli", Amount = 250 },
		{ Type = "Item", ItemId = "Watermelon", Amount = 1 },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
}

QuestInfo.MarineTrial = {
	Id = "MarineTrial",
	Name = "Marine Trial",
	Description = "Prove your worth to the Marines.",
	Category = "Faction",
	Giver = "MarineCaptain",
	TurnInTo = "MarineCaptain",

	Prerequisites = {
		Faction = "Marine",
		MinLevel = 5,
	},

	Stages = {
		{
			Title = "Eliminate pirates",
			Objectives = {
				{ Id = "kill_pirates", Type = "Kill", Target = "Pirate", Count = 5, Description = "Defeat Pirates" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Combat", Amount = 200 },
		{ Type = "Beli", Amount = 500 },
		{ Type = "Reputation", Faction = "Marine", Amount = 100 },
		{ Type = "Title", Title = "Marine Apprentice" },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
}

QuestInfo.WantedBounty = {
	Id = "WantedBounty",
	Name = "Wanted: Captain's Bounty",
	Description = "Hunt down a notorious pirate captain.",
	Category = "Special",
	Giver = "BountyBoard",
	TurnInTo = "BountyBoard",

	Prerequisites = {
		MinBounty = 50000,
		Faction = "Pirate",
	},

	Stages = {
		{
			Title = "Defeat the captain",
			Objectives = {
				{ Id = "kill_captain", Type = "Kill", Target = "PirateCaptain", Count = 1, Description = "Defeat the Pirate Captain" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Combat", Amount = 1000 },
		{ Type = "Beli", Amount = 5000 },
		{ Type = "Bounty", Amount = 25000 },
		{ Type = "Title", Title = "Captain Hunter" },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
	Repeatable = true,
}

QuestInfo.CrewRaid = {
	Id = "CrewRaid",
	Name = "Crew Raid",
	Description = "Coordinate with your crew to clear a hideout.",
	Category = "Crew",
	Giver = "CrewQuartermaster",
	TurnInTo = "CrewQuartermaster",

	Prerequisites = {
		RequiresCrew = true,
		MinCrewSize = 2,
	},

	Stages = {
		{
			Title = "Raid the hideout",
			Objectives = {
				{ Id = "raid_kills", Type = "Kill", Target = "Bandit", Count = 10, Description = "Crew defeats Bandits (any member)" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Combat", Amount = 300 },
		{ Type = "Beli", Amount = 1000 },
	},

	ProgressScope = "CrewShared",
	RewardDistribution = "Solo",
	Repeatable = true,
}

return QuestInfo
