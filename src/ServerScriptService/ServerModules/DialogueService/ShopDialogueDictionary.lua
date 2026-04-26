
local ShopDialogueDictionary = {
	--[[ EXAMPLE
	NPCMerchant = {
		Name = 'NPCMerchant',
		Default = {
			Text = {
				"Hi there, care to purchase anything?"
			},
			Choices = {
				[1] = "Yes",
				[2] = "No"
			},
			Sound = nil,
			AnimationID = nil,
		},
		['1'] = {
			Text = {
				"Thank you! Come again!",
			},
			Choices = nil,
			Sound = nil,
			AnimationID = nil,
			ShopInventory = true,
		},
		['2'] = {
			Text = {
				"Farewell.",
			},
			Choices = nil,
			Sound = nil,
			AnimationID = nil
		},
	},
	]]
}

return ShopDialogueDictionary
