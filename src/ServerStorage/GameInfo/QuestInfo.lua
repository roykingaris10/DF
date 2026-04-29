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

QuestInfo.DummyTraining = {
	Id = "DummyTraining",
	Name = "Combat Training",
	Description = "Hone your fists on a few training dummies.",
	Category = "Normal",
	Giver = "TrainerSign",
	TurnInTo = "TrainerSign",

	Stages = {
		{
			Title = "Defeat training dummies",
			Objectives = {
				{ Id = "dummy_kills", Type = "Kill", Target = "Dummy", Count = 3, Description = "Defeat Training Dummies" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Combat", Amount = 75 },
		{ Type = "Beli", Amount = 50 },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
	Repeatable = true,
	TrackedDefault = true,
}

QuestInfo.SpeedRun = {
	Id = "SpeedRun",
	Name = "Speed Trial",
	Description = "Reach Logue Town within the time limit.",
	Category = "Special",
	Giver = "Wanderer",
	TurnInTo = "Wanderer",

	TimeLimit = 120,

	Stages = {
		{
			Title = "Reach Logue Town in time",
			Objectives = {
				{ Id = "speed_reach", Type = "Reach", Target = "LogueTown", Count = 1, Description = "Get to Logue Town" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Exploration", Amount = 200 },
		{ Type = "Beli", Amount = 300 },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
	Repeatable = true,
}

QuestInfo.SnackRun = {
	Id = "SnackRun",
	Name = "Snack Run",
	Description = "Round up some watermelons for a hungry crew.",
	Category = "Normal",
	Giver = "Cook",
	TurnInTo = "Cook",

	Stages = {
		{
			Title = "Gather watermelons",
			Objectives = {
				{ Id = "watermelons", Type = "Collect", Target = "Watermelon", Count = 5, Description = "Collect Watermelons" },
			},
		},
	},

	Rewards = {
		{ Type = "Beli", Amount = 75 },
		{ Type = "XP", Track = "Exploration", Amount = 25 },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
	Repeatable = true,
}

QuestInfo.LogueTownVisit = {
	Id = "LogueTownVisit",
	Name = "See the Town of Beginnings and Endings",
	Description = "Travel to Logue Town to see the labour first-hand.",
	Category = "Normal",
	Giver = "Wanderer",
	TurnInTo = "Wanderer",

	Stages = {
		{
			Title = "Reach Logue Town",
			Objectives = {
				{ Id = "reach_logue", Type = "Reach", Target = "LogueTown", Count = 1, Description = "Enter Logue Town" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Exploration", Amount = 100 },
		{ Type = "Beli", Amount = 150 },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
}

QuestInfo.BoundaryHunter = {
	Id = "BoundaryHunter",
	Name = "Boundary Hunter",
	Description = "A multi-leg trial across combat, travel, and conversation.",
	Category = "Normal",
	Giver = "TrialMaster",
	TurnInTo = "TrialMaster",

	Stages = {
		{
			Title = "Defeat training dummies",
			Objectives = {
				{ Id = "trial_kills", Type = "Kill", Target = "Dummy", Count = 5, Description = "Defeat Training Dummies" },
			},
		},
		{
			Title = "Travel to Logue Town",
			Objectives = {
				{ Id = "trial_travel", Type = "Reach", Target = "LogueTown", Count = 1, Description = "Reach Logue Town" },
			},
		},
		{
			Title = "Report to the Trial Master",
			Objectives = {
				{ Id = "trial_report", Type = "Talk", Target = "TrialMaster", Count = 1, Description = "Speak with the Trial Master" },
			},
		},
	},

	Rewards = {
		{ Type = "XP", Track = "Combat", Amount = 200 },
		{ Type = "XP", Track = "Exploration", Amount = 100 },
		{ Type = "Beli", Amount = 500 },
		{ Type = "Title", Title = "Boundary Hunter" },
	},

	ProgressScope = "Solo",
	RewardDistribution = "Solo",
}

return QuestInfo

