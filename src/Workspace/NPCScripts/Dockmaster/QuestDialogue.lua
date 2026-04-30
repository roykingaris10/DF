return {
	[1] = {
		Name = "SpecialDelivery",
		Initial = {
			Default = {
				Text = { "If you're here without the Quartermaster's package, you're wasting my time." },
			},
		},
		InProgress = {
			Default = {
				Text = {
					"The package — finally. I was starting to think it'd never get here.",
					"Here, take this for the trouble.",
				},
				TurnInQuest = "SpecialDelivery",
			},
		},
		Completed = {
			Default = {
				Text = { "Safe seas, runner." },
			},
		},
	},
}
