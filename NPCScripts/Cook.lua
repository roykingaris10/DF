return {
	[1] = {
		Name = "SnackRun",
		Initial = {
			Default = {
				Text = {
					"My pantry's empty and I've got mouths to feed.",
					"Bring me five watermelons and you'll eat well tonight.",
				},
				Choices = { [1] = "I'll grab them.", [2] = "Pass." },
			},
			["1"] = {
				Text = { "Five. Don't come back light." },
				AcceptedQuest = "SnackRun",
			},
			["2"] = {
				Text = { "Then keep walking." },
			},
		},
		InProgress = {
			Default = {
				Text = { "Five watermelons. Grab them and get back here." },
			},
		},
		Completed = {
			Default = {
				Text = { "That'll do nicely. Here's your share." },
				TurnInQuest = "SnackRun",
			},
		},
	},
}
