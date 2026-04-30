return {
	[1] = {
		Name = "MarineTrial",
		Initial = {
			Default = {
				Text = {
					"You want to wear the coat? Earn it.",
					"Five pirates put down. Then we'll talk.",
				},
				Choices = { [1] = "Understood, Captain.", [2] = "Pass." },
			},
			["1"] = {
				Text = { "Dismissed, recruit." },
				AcceptedQuest = "MarineTrial",
			},
			["2"] = {
				Text = { "Then get out of my sight." },
			},
		},
		InProgress = {
			Default = {
				Text = { "Five pirates. Report back when it's done." },
			},
		},
		Completed = {
			Default = {
				Text = { "You've earned your stripes. Welcome to the corps." },
				TurnInQuest = "MarineTrial",
			},
		},
	},
}
