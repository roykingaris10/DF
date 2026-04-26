local CONFIG = {
	LOOP_RATE = 0.1, -- updates every 0.1 seconds
	CombatTagTimer = 40, -- seconds

	Health = {
		BaseRegenOutOfCombat = 4.5,  -- per second
		BaseRegenInCombat = 0.15,     -- per second
		LowHungerPenalty = 0.35,     -- % reduction at 0 hunger9
	},
	Will = {
		RegenCombat  = 0.2,       -- small regen
		RegenOutCombat = 2.0,
		Max = 100,
	},
	Stamina = {
		InCombat = 2,				 -- regen while in combat
		OutCombat = 8, 
	},
	Posture = {
		Max = 100,
		DecayDelay = 3,              -- wait after last hit to start decay
		DecayRate = 12,              -- per second
	},
	Hunger = {
		BaseDecay = 0.35,            -- per second
		MissingHealthDecayMultiplier = 0.04, -- more decay when low HP
		Min = 0,
		Max = 100,
		FullGraceTime = 5
	},
}
return CONFIG
