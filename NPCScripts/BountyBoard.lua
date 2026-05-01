return {
	Fallback = {
		Default = {
			Text = {
				"*The board is plastered with names you don't recognise.*",
				"Nothing here for someone like you yet. Make a name for yourself first.",
			},
		},
	},

	[1] = {
		Name = "WantedBounty",
		Initial = {
			Default = {
				Text = {
					"There's paper here on a Pirate Captain — alive or dead, the marks pay.",
					"Take it?",
				},
				Choices = { [1] = "I'll hunt them.", [2] = "Not my fight." },
			},
			["1"] = {
				Text = { "Mark's posted. Bring back the proof." },
				AcceptedQuest = "WantedBounty",
			},
			["2"] = {
				Text = { "Paper stays up." },
			},
		},
		InProgress = {
			Default = {
				Text = { "The captain's still drawing breath. Fix that." },
			},
		},
		Completed = {
			Default = {
				Text = { "Bounty paid. There's always more paper." },
				TurnInQuest = "WantedBounty",
			},
		},
	},
}
