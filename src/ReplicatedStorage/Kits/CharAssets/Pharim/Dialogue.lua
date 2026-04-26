local Dialogue = {
	[1] = {
		Default = {
			Text = {
				"The land has lost all hope, were the transgressions of my predecessor that great?"
			},
			Choices = {
				[1] = "Sir?", 
			},
			Sound = nil,
			AnimationID = nil
		},
		['1'] = {
			Text = {
				"Oh! Hey there young one, don't mind me I was just deliberating with myself!"
			},
			Choices = {
				[1] = "Does that weapon belong to you?",
			},
			Sound = nil,
			AnimationID = nil
		},
		['11'] = {
			Text = {
				"Ah this old thing? it belonged to my master, he is no longer bound by this world but I keep it as a testament to the life he lived."
			},
			Choices = {
				[1] = "I'm sorry to hear that, what was your Masters name?"
			},
			Sound = nil,
			AnimationID = nil

		},	


		['111'] = {
			Text = {
				"His name was Apo-, ... I only know the wicked thunder as thunder and my Master as Master."
			},
			Choices = {

				[1] = "Alright well I hope your master is in a better place."

			},
			Sound = nil,
			AnimationID = nil
		},

		['1111'] = {
			Text = {
				"*Instantly, his face begins to turn pale and lips behind to tremble, unable to utter another word."
			},
			Choices = nil,
			Sound = nil,
			AnimationID = nil
		},
	}
}

return Dialogue
