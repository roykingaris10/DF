return {
	[1] = {
		Name = "BanditBeater",
		Initial = {
			Default = {
				Text = {
					"Bandits have been raiding the outskirts again.",
					"I could use a hand thinning their numbers — two of them, if you can manage it.",
				},
				Choices = { [1] = "I'll take care of it.", [2] = "Not interested." },
			},
			["1"] = {
				Text = { "Good. Find me here when it's done." },
				AcceptedQuest = "BanditBeater",
			},
			["2"] = {
				Text = { "Suit yourself. Stay safe out there." },
			},
		},
		InProgress = {
			Default = {
				Text = { "Two bandits down. I'll be here when you're finished." },
			},
		},
		Completed = {
			Default = {
				Text = {
					"That's the bandits handled. The town owes you.",
					"Take this for your trouble.",
				},
				TurnInQuest = "BanditBeater",
			},
		},
	},
}
