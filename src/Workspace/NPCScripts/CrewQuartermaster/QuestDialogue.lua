return {
	[1] = {
		Name = "CrewRaid",
		Initial = {
			Default = {
				Text = {
					"There's a hideout that needs clearing — a crew job.",
					"Ten bandits between you and the spoils. Up for it?",
				},
				Choices = { [1] = "Crew's ready.", [2] = "Some other time." },
			},
			["1"] = {
				Text = { "Move out. Spoils when it's done." },
				AcceptedQuest = "CrewRaid",
			},
			["2"] = {
				Text = { "Don't take too long." },
			},
		},
		InProgress = {
			Default = {
				Text = { "Ten bandits. Get to work." },
			},
		},
		Completed = {
			Default = {
				Text = { "Hideout's quiet. Good work, crew." },
				TurnInQuest = "CrewRaid",
			},
		},
	},
}
