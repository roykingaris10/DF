local Settings = {
	-- Initial uptilt settings (the first hit that launches)
	InitialLiftoff = {
		TargetHeight = 36,      -- They'll rise 50 studs high
		BackwardDistance = -25,  -- Travel 15 studs backward
		RiseDuration = 0.175,     -- Takes 0.8 seconds to reach peak
		LaunchAngle = 80,           -- Angle of launch (degrees from horizontal)
	};

	-- Arc settings (natural fall if no follow-up)
	ArcSettings = {
		UseWorkspaceGravity = true, -- Use workspace.Gravity instead of custom
		CustomGravity = 196.2,      -- Only used if UseWorkspaceGravity is false
		FallGravityMultiplier = 1.375, -- Multiply gravity by this during falling (1.5 = 50% heavier fall)
		PeakHangTime = 0.4,        -- Time spent at the peak before falling
		BackwardDriftMultiplier = 1.2, -- Multiplier for continued backward drift while falling
	},

	-- Juggle settings (follow-up hits while airborne)
	JuggleHit = {
		UpwardBoost = 35,           -- Upward force per juggle hit
		HorizontalKnockback = 10,   -- Horizontal knockback per juggle hit (in direction of combo)
		ComboDecay = 0.92,          -- Each hit reduces lift (0.92 = 8% reduction per hit)
		MaxComboCount = 15,         -- Maximum juggle hits before forced drop
		ComboWindow = 1.5,          -- Time window to continue combo (seconds)
		FirstHitRedirectBonus = 1.3, -- Multiplier for the first air hit to establish direction
	},

	-- Physics settings
	Physics = {
		CeilingCheckDistance = 4,   -- Raycast distance to check for ceilings above
		GroundCheckDistance = 4,    -- Distance to check for ground
		CeilingDampening = 0.2,     -- How much to dampen velocity when hitting ceiling (0.2 = 80% reduction)
	},

	-- State durations
	Durations = {
		HitstunPerHit = 0.4,        -- Hitstun duration per aerial hit
		RecoveryTime = 0.5,         -- Time before victim can act after landing
	}
}
return Settings
