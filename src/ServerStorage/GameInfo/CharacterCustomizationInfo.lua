local CharInformation = {
	Races = {
		["Human"] = {
			RaceName = 'Human',
			Title = 'Limitless Dreamers',
			Desc = 'The biggest dreamers and the boldest fools.',
			SkinTones = {
				Color3.fromRGB(255, 223, 196),
				Color3.fromRGB(234, 203, 168),
				Color3.fromRGB(247, 208, 174),
				Color3.fromRGB(236, 191, 131),
				Color3.fromRGB(172, 139, 100),
				Color3.fromRGB(148, 97, 60),
				Color3.fromRGB(98, 58, 24),
			},

			HairColors = {
				Color3.fromRGB(230, 206, 87),
				Color3.fromRGB(112, 199, 122),
				Color3.fromRGB(63, 48, 36),
				Color3.fromRGB(199, 137, 37),
				Color3.fromRGB(225, 58, 25),
				Color3.fromRGB(255, 237, 171),
				Color3.fromRGB(33, 33, 33),
				Color3.fromRGB(153, 253, 255),
				Color3.fromRGB(54, 38, 95),
			},

			EyeColors = {
				Color3.fromRGB(112, 222, 255),
				Color3.fromRGB(139, 255, 162),
				Color3.fromRGB(70, 35, 24),
			},

			RaceEyes = {"HumanEyes","HumanEyes2","HumanEyes3"},

			RaceMouth = {
				"Mouth1","Mouth2","Mouth3"
			},

			RaceMarkings = {
				"Marking1","Marking2","Marking3"
			},

			RaceAccessories = {

			},
		},

		["Fishman"] = {
			RaceName = 'Fishman',
			Title = 'Seaborn',
			Desc = 'Sovereigns of the sea, with the strength of the depths.',
			SkinTones = {
				Color3.fromRGB(170, 247, 255),
				Color3.fromRGB(134, 141, 208),
				Color3.fromRGB(255, 121, 121),
				Color3.fromRGB(164, 186, 202),
				Color3.fromRGB(162, 255, 178),
				Color3.fromRGB(255, 194, 218),
			},

			HairColors = {
				Color3.fromRGB(32, 35, 59),
				Color3.fromRGB(54, 46, 37),
				Color3.fromRGB(21, 21, 20),
				Color3.fromRGB(164, 186, 202),
				Color3.fromRGB(255, 194, 218),
			},

			EyeColors = {
				Color3.fromRGB(255, 75, 75),
				Color3.fromRGB(155, 255, 243),
				Color3.fromRGB(0, 0, 0),
			},

			RaceEyes = {"FishmanEyes","FishmanEyes2","FishmanEyes3"},

			RaceMouth = {
				"Mouth1","Mouth2","Mouth3"
			},

			RaceMarkings = {
				"Marking1","Marking2","Marking3"
			},
			RaceAccessories = {
				[1] = {
					Tone = true,
					backfin = CFrame.new(0.000228881836, -0.181023121, 1.03920746, 1, 0, 0, 0, 1, 0, 0, 0, 1),

				},
				[2] = {
					Tone = true,
					backfin = CFrame.new(-0.000183105469, 0, 0.746170044, 1, 0, 0, 0, 1, 0, 0, 0, 1),
					leftfin = CFrame.new(-0.600189209, 0, -0.000276565552, 1, 0, 0, 0, 1, 0, 0, 0, 1),
					rightfin = CFrame.new(0.599884033, 0, -0.000276565552, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
			},

		},

		["Mink"] = {
			RaceName = 'Mink', 
			Title = 'Tribe of Storm',
			Desc = 'Fierce warriors with the storm in their fur.',
			SkinTones = {
				Color3.fromRGB(255, 166, 93),
				Color3.fromRGB(94, 70, 52),
				Color3.fromRGB(233, 234, 255),
				Color3.fromRGB(202, 131, 74),
				Color3.fromRGB(255, 200, 0),
				Color3.fromRGB(129, 126, 140),
			},

			InitialHairColor = Color3.new(0.870588, 0.52549, 0.352941),
			FinalHairColor = Color3.new(0.654902, 0.933333, 0.678431),

			EyeColors = {
				Color3.fromRGB(255, 0, 0),
				Color3.fromRGB(238, 255, 131),
				Color3.fromRGB(0, 0, 0),
			},

			RaceEyes = {"MinkEyes","MinkEyes2","MinkEyes3"},

			RaceMouth = {
				"Mouth1","Mouth2","Mouth3"
			},

			RaceMarkings = {
				"Marking1","Marking2","Marking3"
			},

			RaceAccessories = {
				[1] = {
					Tone = true,
					innerear = CFrame.new(-7.62939453e-06, 0.627854824, -0.135757446, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
				[2] = {
					Tone = true,
					innerear = CFrame.new(0.00032043457, 0.710549355, -0.243364334, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
				[3] = {
					Tone = true,
					innerear = CFrame.new(0.000312805176, 0.884300709, -0.4459095, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
				[4] = {
					Tone = true,
					minkear = CFrame.new(-9.15527344e-05, -0.0471229553, -0.000276565552, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
			},
		},

		["Skypiean"] = {
			RaceName = 'Skypiean',
			Title = 'Children of the White Sea',
			Desc = 'Children of the sky, once thought of as myths.',
			SkinTones = {
				Color3.fromRGB(255, 223, 196),
				Color3.fromRGB(234, 203, 168),
				Color3.fromRGB(247, 226, 171),
				Color3.fromRGB(236, 191, 131),
				Color3.fromRGB(172, 139, 100),
				Color3.fromRGB(148, 97, 60),
				Color3.fromRGB(98, 58, 24),
			},

			HairColors = {
				Color3.fromRGB(95, 67, 48),
				Color3.fromRGB(221, 213, 127),
				Color3.fromRGB(221, 219, 184),
				Color3.fromRGB(93, 31, 11),
			},

			EyeColors = {
				Color3.fromRGB(44, 41, 39),
				Color3.fromRGB(221, 255, 229),
				Color3.fromRGB(226, 196, 162),
			},

			RaceEyes = {"SkypieanEyes","SkypieanEyes2","SkypieanEyes3"},

			RaceMouth = {
				"Mouth1","Mouth2","Mouth3"
			},

			RaceMarkings = {
				"Marking1","Marking2","Marking3"
			},

			RaceAccessories = {
				[1] = {
					Tone = false,
					SkypeianWings = CFrame.new(6.10351562e-05, 0.834632158, 0.559682846, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
			},
		},
		["Buccaneer"] = {
			RaceName = 'Buccaneer',	
			Title = 'Forgotten Giants',
			Desc = 'Giants carrying the weight of a lost legacy.',
			SkinTones = {
				Color3.fromRGB(170, 112, 71),
				Color3.fromRGB(200, 148, 111),
				Color3.fromRGB(125, 85, 70),
				Color3.fromRGB(81, 58, 44),
			},

			HairColors = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(211, 211, 211),
				Color3.fromRGB(213, 219, 243),
			},

			EyeColors = {
				Color3.fromRGB(255, 33, 17),
				Color3.fromRGB(232, 255, 131),
				Color3.fromRGB(117, 28, 83),
			},

			RaceEyes = {"BuccaneerEyes","BuccaneerEyes2","BuccaneerEyes3"},

			RaceMouth = {
				"Mouth1","Mouth2","Mouth3"
			},

			RaceMarkings = {
				"Marking1","Marking2","Marking3"
			},

			RaceAccessories = {

			},
		},
		["Oni"] = {
			RaceName = 'Oni',
			Title = 'Primal Demons',
			Desc = 'Primal demons of conquest and ruin.',
			SkinTones = {
				Color3.fromRGB(195, 255, 138),
				Color3.fromRGB(185, 140, 88),
				Color3.fromRGB(95, 118, 162),
				Color3.fromRGB(255, 129, 129),
			},

			HairColors = {
				Color3.fromRGB(33, 23, 15),
				Color3.fromRGB(211, 101, 65),
				Color3.fromRGB(96, 128, 243),
			},

			EyeColors = {
				Color3.fromRGB(30, 81, 18),
				Color3.fromRGB(255, 120, 67),
				Color3.fromRGB(21, 49, 70),
			},

			RaceEyes = {"OniEyes","OniEyes2","OniEyes3"},

			RaceMouth = {
				"Mouth1","Mouth2","Mouth3"
			},

			RaceMarkings = {
				"Marking1","Marking2","Marking3"
			},

			RaceAccessories = {
				[1] = {
					Tone = false,
					Horn = CFrame.new(0.00023651123, 0.674601555, -0.496259689, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
				[2] = {
					Tone = false,
					Horn = CFrame.new(-0.000465393066, 0.648652077, -0.000276565552, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
				[3] = {
					Tone = false,
					Horn = CFrame.new(-0.000144958496, 0.259847641, -0.405004501, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
				[4] = {
					Tone = false,
					Horn = CFrame.new(-0.000144958496, 0.265771866, -0.635292053, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
				[5] = {
					Tone = false,
					Horn = CFrame.new(0.000442504883, 0.474628448, -0.486692429, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
			},
		},

		["Lunarian"] = {
			RaceName = 'Lunarian',	
			Title = 'Fallen Angels',
			Desc = 'A scarce race with flames to match their rage.',
			SkinTones = {
				Color3.fromRGB(170, 112, 71),
				Color3.fromRGB(200, 148, 111),
				Color3.fromRGB(125, 85, 70),
				Color3.fromRGB(81, 58, 44),
			},

			HairColors = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(211, 211, 211),
				Color3.fromRGB(213, 219, 243),
			},

			EyeColors = {
				Color3.fromRGB(255, 33, 17),
				Color3.fromRGB(232, 255, 131),
				Color3.fromRGB(117, 28, 83),
			},

			RaceEyes = {"LunarianEyes","LunarianEyes2","LunarianEyes3"},

			RaceMouth = {
				"Mouth1","Mouth2","Mouth3"
			},

			RaceMarkings = {
				"Marking1","Marking2","Marking3"
			},

			RaceAccessories = {
				[1] = {
					Tone = false,
					LunarianWings = CFrame.new(-9.15527344e-05, -0.39706707, 0.88586235, 1, 0, 0, 0, 1, 0, 0, 0, 1),
				},
			},
		},

	},

	StarterOutfits = {
		"Peasant","Pirate","Reef Bandit"
	},

	LastNames = {
		["Global"] = {
			"Skytte",
			"Aurentia",
			"Black",
			"Bay",
			"Jones",
			"Nast",
			"Mavetti",
			"Xarda",
			"Straxx",
			"Vale",
		},
		["Human"] = {
			"Donquixote",
			"Shimotsuki",
			"Teach",
			"Xebec",
			"Monkey",
			"Newgate",
			"Silver",
			"Gol",
			"Alder",
			"Briar",
			"Reed",
			"Sparda",
			"Roux",
			"Nefertari",
			"Kidd",
		},
		["Fishman"] = {
			"Tiger",
			"Decken",
			"Rivers",
			"Dwoaga",
			"Frost",
			"Flosc",
			"Draedin",
		},
		["Mink"] = {
			"Calico",
			"Silk",
			"Greycoat",
			"Blackmane",
			"Whitepelt",
			"Twill",
			"Drift",
			"Jasper",
			"Onyx",
		},
		["Skypiean"] = {
			"Cirrus",
			"Azura",
			"Lumen",
			"Iris",
			"Seraph",
			"Stratus",
		},
		["Buccaneer"] = {
			"Kuma",
			"Bonney",
			"Atlas",
			"Stonehand",
			"Danitz",
			"Jorg",
			"Jaguar",
			"Oars",
		},
		["Oni"] = {
			"Grim",
			"Ifrit",
			"Yami",
			"Ashmaw",
			"Kragan",
			"Zul"
		},
		["Lunarian"] = {
			"Ignacio",
			"Solani",
			"Helamence",
			"Pyre",
			"Fallen"
		},
	},
	MiddleNames = {
		["Global"] = {
			"D.",
			"X.",
			"Lux",
			"Cree",
			"Valor",
			"Nyx",
			"Ruin",
			"Star",
			"Noctis",
		},
		["Male"] ={
			"Orion",
			"Abyrus",
			"Ash",
			"J.",
			"M.",
			"Von",
			"Vex"
		},
		["Female"] = {
			"Fleur",
			"Aumara",
			"Artemis",
			"S.",
			"V.",
			"Rose",
			"Xenne",
			"Seletine",
			"Queen",
			"Faye"
		},
	},
}


return CharInformation