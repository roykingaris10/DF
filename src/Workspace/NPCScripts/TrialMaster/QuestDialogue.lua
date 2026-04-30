return {
	[1] = {
		Name = "BoundaryHunter",
		Initial = {
			Default = {
				Text = {
					"A trial in three parts: combat, travel, conversation.",
					"Five dummies. Then Logue Town. Then back here. Take it?",
				},
				Choices = { [1] = "I accept the trial.", [2] = "Not yet." },
			},
			["1"] = {
				Text = { "Then begin. The trial doesn't wait." },
				AcceptedQuest = "BoundaryHunter",
			},
			["2"] = {
				Text = { "Return when your nerve does." },
			},
		},
		InProgress = {
			Default = {
				Text = { "The trial isn't done. Finish it." },
			},
		},
		Completed = {
			Default = {
				Text = {
					"All three legs. You've earned the title.",
					"Boundary Hunter — wear it well.",
				},
				TurnInQuest = "BoundaryHunter",
			},
		},
	},
}
