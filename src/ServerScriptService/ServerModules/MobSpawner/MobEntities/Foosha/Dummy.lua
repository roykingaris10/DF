local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local self = {
	MobType = "Dummy";
	WalkSpeed = 0;
	SprintSpeed = 0;
	Data = {
		UserData = {
			FirstName = "Dummy",
			LastName = " ",
			Race = "Human",
			--		Class = "Sword",
			Level = 999,
		},

		statInfo = {
			StatValues = {
				Strength = 0,
				Vitality = 0,
				Dexterity = 0,
				Cognition = 0,
				Will = 0,
				Haki = 0,
			},

			Health = 100,
			Stamina = 80,
			Hunger = 100,
			Will = 60,
		},

		equipped = {
		},
	};

	Drops = {
		{Item = "OfficerCutlass", Chance = 5},
		{Item = "Beli", Amount = {200, 400}, Chance = 100},
	};
}



return self