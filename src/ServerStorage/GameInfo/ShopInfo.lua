local ShopInfo = {
	['Shopkeeper'] = {

		['Details'] = {
			ShopName = 'Keeper\'s Inn',
			ShopSlogan = 'Keepers of the sea, keepers of the land.',
			ShopType = 'Food',
			ShopEmblem = ''
		},

		['Stock'] = {
			['Ham'] = {
				Price = 10,
				Desc = 'Fresh beef, marinated and brazed in sweat smoke.',
				Stats = {
					Hunger = 5,
				}
			},
			['Watermelon'] = {
				Price = 1,
				Desc = 'A good watermelon is one that is brittle.',
				Stats = {
					Hunger = 7
				}
			},
			
			['Apple'] = {
				Price = 15,
				Desc = 'A good watermelon is one that is brittle.',
				Stats = {
					Hunger = 20
				}
			}
		}

	},

	['Joe'] = {

		['Details'] = {
			ShopName = 'The Black Swarn',
			ShopSlogan = 'Need It? We Got It. Pay In Gold.. or Blood.',
			ShopType = 'Weapon'
		},

		['Stock'] = {
			
			['Slingshot'] = {
				Price = 5,
				Desc = 'Precision and power, all in one.',
				Stats = {
					STR = 8,
					AGI = 35,
					INT = 10,
					VIT = 2,
					["MISC-1"] = 15,
					["MISC-2"] = 5
				}
			},
	
			['Sword'] = {
				Price = 45,
				Desc = 'Refined Steel, crafted by the finest blacksmiths.',
				Stats = {
					STR = 30,
					AGI = 15,
					VIT = 5,
					INT = 2
				}
			},
			['Flintlock'] = {
				Price = 235,
				Desc = 'A sword that is sharp and deadly.',
				Stats = {
					STR = 18,
					AGI = 22,
					VIT = 8,
					INT = 5,
					["MISC-1"] = 12
				}
			},
			['Bronze Pickaxe'] = {
				Price = 15,
				Desc = 'Chip by chip, you can mine the richest ore.',
				Stats = {
					STR = 15,
					["MISC-1"] = 50,
					["MISC-2"] = 25
				}
			},
			
			['Cutlass'] = {
				Price = 50,
				Desc = 'Fresh Axe, marinated and brazed in sweat smoke.',
				Stats = {
					STR = 25,
					AGI = 5,
					VIT = 10
				}
			},
		}
	}
}
return ShopInfo