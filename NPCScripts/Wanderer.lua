return {
	[1] = {
		Name = "LogueTownVisit",
		Initial = {
			Default = {
				Text = {
					"You haven't seen Logue Town with your own eyes? Tragic.",
					"The town of beginnings and endings — go look for yourself.",
				},
				Choices = { [1] = "I'll head there now.", [2] = "Some other time." },
			},
			["1"] = {
				Text = { "Walk safe. Come back and tell me what you saw." },
				AcceptedQuest = "LogueTownVisit",
			},
			["2"] = {
				Text = { "Your loss." },
			},
		},
		InProgress = {
			Default = {
				Text = { "You haven't reached Logue Town yet. Get going." },
			},
		},
		Completed = {
			Default = {
				Text = {
					"So you finally saw it. Different in person, isn't it?",
					"Take this — for your eyes' education.",
				},
				TurnInQuest = "LogueTownVisit",
			},
		},
	},
	[2] = {
		Name = "SpeedRun",
		Initial = {
			Default = {
				Text = {
					"Now that you know the way, want to see how fast you can run it?",
					"Two minutes from here to Logue Town. Beat it.",
				},
				Choices = { [1] = "Start the clock.", [2] = "Not today." },
			},
			["1"] = {
				Text = { "Two minutes. Go." },
				AcceptedQuest = "SpeedRun",
			},
			["2"] = {
				Text = { "When you find your legs, come back." },
			},
		},
		InProgress = {
			Default = {
				Text = { "The clock's ticking. Move." },
			},
		},
		Completed = {
			Default = {
				Text = { "Made it. Faster than I'd have given you credit for." },
				TurnInQuest = "SpeedRun",
			},
		},
	},
}
