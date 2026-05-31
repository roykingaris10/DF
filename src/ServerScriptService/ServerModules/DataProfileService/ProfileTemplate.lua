local HttpService = game:GetService("HttpService")

local ProfileTemplate = {
	ServerData = {
		ChosenSlot = 1,
		Banned = false,
	};
	CrewData = {
		
		CrewId = "",
		CrewName = "",
		CreatedAt = 0,
		CaptainUserId = 0,
		Members = {},
		History = {}
		
	};
	
	FactionData = {
		FactionId = "Civilian",
		JoinedAt = 0,
	},
	
	Settings = {
		SoundVolume = 1;
		MusicVolume = 1;
		ScreenShake = true;
		ShadowsEnabled = true;
		Sprint = "Shift";
	};
	Slots = {};
	
	SlotData = {
		SlotsAvailable = 1,
		SlotTemplate = {
			Finalized = false,
			FirstRaceRolled = false,
			HasSeenInnerDialogue = false,
			UserData = {
				FirstName = nil, 
				MiddleName = nil,
				LastName = nil,
				Class = "Default",
				Faction = "Civilian",
				FactionRank = "",
				Crew = "None",
				WillColor = nil,
				Race = nil,
				DreamTrait = nil,
				Gender = nil,
				Level = 53,
				Beli = 1000,
				XP = 0,
				Bounty = 0,
			};
			statInfo = {
				StatValues = {
					Strength = 0,
					Vitality = 0,
					Dexterity = 0,
					Cognition = 0,
					Will = 0,
					Haki = 0,
				},
				StatPoints = 0,
				SkillPoints = 0,
				AchievementPoints = 0,
				Ammo = 0,
				Health = 100,
				Will = 100,
				Stamina = 100,
				Energy = 100,
				Hunger = 100,
			},
			XPInfo = {
				Total = {
					Level = 1,
				},
				Combat = {
					Level = 1,
					Exp = 0,
					ExpToNextLevel = 100,
				},
				Exploration = {
					Level = 1,
					Exp = 0,
					ExpToNextLevel = 100,
				},
				Profession = {
					Level = 1,
					Exp = 0,
					ExpToNextLevel = 100,
				},
			},
			summaryInfo = {
				TimePlayed = 0,
			},
			playerAppearance = {
				Outfit = nil,
				Eyes = nil,
				Mouth = nil,
				Marking = nil,
				RaceAcc = nil,
				HairColor = {},
				EyeColor = {},
				ToneColor = {}
			},
			equipped = {
				Weapon = nil,
				Head = nil,
				Torso = nil,
				Legs = nil,
				Back = nil,
				Neck = nil,
				Ring1 = nil,
				Ring2 = nil,
			},
			Inventory = {
			},
			Toolbar = {
			},
			SkillInventory = {
			},
			Dreams = {
				[1] = {},
				[2] = {},
				[3] = {},
			},
			packs = {},
			currentQuests = {},
			questsCompleted = {},
			TrackedQuest = nil,
		},
		
	},
	
}

return ProfileTemplate
