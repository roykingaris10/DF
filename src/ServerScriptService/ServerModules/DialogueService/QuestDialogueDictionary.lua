
local QuestDialogueDictionary = {
	--[[ EXAMPLE
	Soren = {
		[1] = {
			Name = 'BanditBeater',
			Initial = {
				Default = {
					Text = {
						"Hi there, can you help me by defeating a few bandits?"
					},
					Choices = {
						[1] = "Yes",
						[2] = "No"
					},
					Sound = nil,
					AnimationID = nil
				},
				['1'] = {
					Text = {
						"Thank you! Please let me know when you have defeated them",
					},
					Choices = nil,
					Sound = nil,
					AnimationID = nil,
					AcceptedQuest = 'BanditBeater'
				},
				['2'] = {
					Text = {
						"I guess I will suffer with these bandits :(",
					},
					Choices = nil,
					Sound = nil,
					AnimationID = nil
				},
			},
			InProgress = {
				Default = {
					Text = {
						"Please let me know when you have killed 2 bandits"
					},
					Choices = nil,
					Sound = nil,
					AnimationID = nil
				},

			},
			Completed = {
				Default = {
					Text = {
						"Thank you for defeating the bandits!"
					},
					Choices = nil,
					Sound = nil,
					AnimationID = nil
				},
				
			}
		},
	},
	]]
}

return QuestDialogueDictionary
