-- Quest dialogues. Each NPC entry is a list of quests in priority order;
-- the first one whose state is unmet (Initial / InProgress / Completed) is
-- shown when the player talks to them.
--
-- Node fields:
--   Text        : array of lines shown sequentially
--   Choices     : array of choice strings; the chosen index is appended to
--                 the dialogue version key (Default -> "1" -> "11" ...)
--   AcceptedQuest : quest id to AcceptQuest when this node is reached
--   TurnInQuest   : quest id to CompleteQuest when this node is reached
--   AbandonQuest  : quest id to AbandonQuest when this node is reached
--   Action        : faction/crew action ("Marine", "Pirate", etc.)

local QuestDialogueDictionary = {

	Soren = {
		[1] = {
			Name = "BanditBeater",
			Initial = {
				Default = {
					Text = {
						"Bandits have been raiding the outskirts again.",
						"I could use a hand thinning their numbers — two of them, if you can manage it.",
					},
					Choices = { [1] = "I'll take care of it.", [2] = "Not interested." },
				},
				["1"] = {
					Text = { "Good. Find me here when it's done." },
					AcceptedQuest = "BanditBeater",
				},
				["2"] = {
					Text = { "Suit yourself. Stay safe out there." },
				},
			},
			InProgress = {
				Default = {
					Text = { "Two bandits down. I'll be here when you're finished." },
				},
			},
			Completed = {
				Default = {
					Text = {
						"That's the bandits handled. The town owes you.",
						"Take this for your trouble.",
					},
					TurnInQuest = "BanditBeater",
				},
			},
		},
	},

	Quartermaster = {
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
	},

	Dockmaster = {
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
	},

	TrainerSign = {
		[1] = {
			Name = "DummyTraining",
			Initial = {
				Default = {
					Text = {
						"Three dummies. Knock them down. Come back.",
						"That's the training. Want a go?",
					},
					Choices = { [1] = "Let's train.", [2] = "Maybe later." },
				},
				["1"] = {
					Text = { "Hit hard. Hit clean." },
					AcceptedQuest = "DummyTraining",
				},
				["2"] = {
					Text = { "The dummies aren't going anywhere." },
				},
			},
			InProgress = {
				Default = {
					Text = { "Three dummies. Don't come back until they're down." },
				},
			},
			Completed = {
				Default = {
					Text = {
						"Solid work. Take the pay and run it back any time.",
					},
					TurnInQuest = "DummyTraining",
				},
			},
		},
	},

	Cook = {
		[1] = {
			Name = "SnackRun",
			Initial = {
				Default = {
					Text = {
						"My pantry's empty and I've got mouths to feed.",
						"Bring me five watermelons and you'll eat well tonight.",
					},
					Choices = { [1] = "I'll grab them.", [2] = "Pass." },
				},
				["1"] = {
					Text = { "Five. Don't come back light." },
					AcceptedQuest = "SnackRun",
				},
				["2"] = {
					Text = { "Then keep walking." },
				},
			},
			InProgress = {
				Default = {
					Text = { "Five watermelons. Grab them and get back here." },
				},
			},
			Completed = {
				Default = {
					Text = { "That'll do nicely. Here's your share." },
					TurnInQuest = "SnackRun",
				},
			},
		},
	},

	Wanderer = {
		[1] = {
			Name = "LogueTownVisit",
			Initial = {
				Default = {
					Text = {
						"You haven't seen Logue Town with your own eyes? Tragic.",
						"The town of beginnings and endings — go look for yourself.",
					},
					Choices = { [1] = "I'll head there now.", [2] = "Some other time." },
				},
				["1"] = {
					Text = { "Walk safe. Come back and tell me what you saw." },
					AcceptedQuest = "LogueTownVisit",
				},
				["2"] = {
					Text = { "Your loss." },
				},
			},
			InProgress = {
				Default = {
					Text = { "You haven't reached Logue Town yet. Get going." },
				},
			},
			Completed = {
				Default = {
					Text = {
						"So you finally saw it. Different in person, isn't it?",
						"Take this — for your eyes' education.",
					},
					TurnInQuest = "LogueTownVisit",
				},
			},
		},
		[2] = {
			Name = "SpeedRun",
			Initial = {
				Default = {
					Text = {
						"Now that you know the way, want to see how fast you can run it?",
						"Two minutes from here to Logue Town. Beat it.",
					},
					Choices = { [1] = "Start the clock.", [2] = "Not today." },
				},
				["1"] = {
					Text = { "Two minutes. Go." },
					AcceptedQuest = "SpeedRun",
				},
				["2"] = {
					Text = { "When you find your legs, come back." },
				},
			},
			InProgress = {
				Default = {
					Text = { "The clock's ticking. Move." },
				},
			},
			Completed = {
				Default = {
					Text = { "Made it. Faster than I'd have given you credit for." },
					TurnInQuest = "SpeedRun",
				},
			},
		},
	},

	TrialMaster = {
		[1] = {
			Name = "BoundaryHunter",
			Initial = {
				Default = {
					Text = {
						"A trial in three parts: combat, travel, conversation.",
						"Five dummies. Then Logue Town. Then back here. Take it?",
					},
					Choices = { [1] = "I accept the trial.", [2] = "Not yet." },
				},
				["1"] = {
					Text = { "Then begin. The trial doesn't wait." },
					AcceptedQuest = "BoundaryHunter",
				},
				["2"] = {
					Text = { "Return when your nerve does." },
				},
			},
			InProgress = {
				Default = {
					Text = { "The trial isn't done. Finish it." },
				},
			},
			Completed = {
				Default = {
					Text = {
						"All three legs. You've earned the title.",
						"Boundary Hunter — wear it well.",
					},
					TurnInQuest = "BoundaryHunter",
				},
			},
		},
	},

	CrewQuartermaster = {
		[1] = {
			Name = "CrewRaid",
			Initial = {
				Default = {
					Text = {
						"There's a hideout that needs clearing — a crew job.",
						"Ten bandits between you and the spoils. Up for it?",
					},
					Choices = { [1] = "Crew's ready.", [2] = "Some other time." },
				},
				["1"] = {
					Text = { "Move out. Spoils when it's done." },
					AcceptedQuest = "CrewRaid",
				},
				["2"] = {
					Text = { "Don't take too long." },
				},
			},
			InProgress = {
				Default = {
					Text = { "Ten bandits. Get to work." },
				},
			},
			Completed = {
				Default = {
					Text = { "Hideout's quiet. Good work, crew." },
					TurnInQuest = "CrewRaid",
				},
			},
		},
	},

	MarineCaptain = {
		[1] = {
			Name = "MarineTrial",
			Initial = {
				Default = {
					Text = {
						"You want to wear the coat? Earn it.",
						"Five pirates put down. Then we'll talk.",
					},
					Choices = { [1] = "Understood, Captain.", [2] = "Pass." },
				},
				["1"] = {
					Text = { "Dismissed, recruit." },
					AcceptedQuest = "MarineTrial",
				},
				["2"] = {
					Text = { "Then get out of my sight." },
				},
			},
			InProgress = {
				Default = {
					Text = { "Five pirates. Report back when it's done." },
				},
			},
			Completed = {
				Default = {
					Text = { "You've earned your stripes. Welcome to the corps." },
					TurnInQuest = "MarineTrial",
				},
			},
		},
	},

	BountyBoard = {
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
	},

}

return QuestDialogueDictionary
