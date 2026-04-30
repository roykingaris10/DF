return {
	[1] = {
		Name = "DummyTraining",
		Initial = {
			Default = {
				Text = {
					"Three dummies. Knock them down. Come back.",
					"That's the training. Want a go?",
				},
				Choices = { [1] = "Let's train.", [2] = "Maybe later." },
			},
			["1"] = {
				Text = { "Hit hard. Hit clean." },
				AcceptedQuest = "DummyTraining",
			},
			["2"] = {
				Text = { "The dummies aren't going anywhere." },
			},
		},
		InProgress = {
			Default = {
				Text = { "Three dummies. Don't come back until they're down." },
			},
		},
		Completed = {
			Default = {
				Text = { "Solid work. Take the pay and run it back any time." },
				TurnInQuest = "DummyTraining",
			},
		},
	},
}
