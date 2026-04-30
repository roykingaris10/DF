return {
	[1] = {
		Name = "SpecialDelivery",
		Initial = {
			Default = {
				Text = {
					"You there — I've got a package that needs to reach the Dockmaster yesterday.",
					"Will you run it down for me?",
				},
				Choices = { [1] = "Hand it over.", [2] = "Find someone else." },
			},
			["1"] = {
				Text = { "Don't lose it. The Dockmaster is waiting." },
				AcceptedQuest = "SpecialDelivery",
			},
			["2"] = {
				Text = { "Tch. Useless." },
			},
		},
		InProgress = {
			Default = {
				Text = { "The Dockmaster is at the harbour. Get moving." },
			},
		},
		Completed = {
			Default = {
				Text = { "Already back? Good — that's between you and the Dockmaster now." },
			},
		},
	},
}
