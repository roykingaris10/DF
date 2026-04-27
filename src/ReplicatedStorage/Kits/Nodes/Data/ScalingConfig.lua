-- Tuning + asset references for the scaling/traversal system.
-- Adjust freely; no code changes needed.

local ScalingConfig = {}

ScalingConfig.Stamina = {
	Max = 100,
	-- Drain per second while actively moving on the wall.
	ClimbDrainPerSecond = 14,
	-- Drain per second while just clinging (idle on the wall).
	ClingDrainPerSecond = 4,
	-- Flat cost when starting a wall-jump.
	WallJumpCost = 12,
	-- Flat cost when starting a mantle.
	MantleCost = 6,
	-- Regen per second while grounded and not scaling.
	RegenPerSecond = 28,
	-- Multiplier applied while not grounded but also not scaling (mid-air after a wall-jump).
	AirRegenMultiplier = 0.0,
	-- Below this, climbing automatically disengages and the player slides off the wall.
	MinToCling = 4,
}

ScalingConfig.Climb = {
	-- Player must be within this distance of the wall to grip.
	GripRange = 3.5,
	-- The wall's normal must be more horizontal than this to count as climbable.
	-- 0.85 means ~32° tilt off-vertical max.
	WallVerticalThreshold = 0.85,
	-- Climb movement speeds.
	UpSpeed = 7,
	DownSpeed = 9,
	SidewaysSpeed = 6,
	-- Distance maintained between HRP and wall when clinging.
	ClingOffset = 1.6,
	-- Time spent attaching/snapping to the wall before control returns.
	AttachTime = 0.18,
	-- Player must hold a movement key for this long with no progress to "give up" and drop.
	StuckTimeout = 1.5,
}

ScalingConfig.WallJump = {
	-- Vertical impulse on wall-jump.
	VerticalImpulse = 60,
	-- Horizontal impulse (away from wall).
	HorizontalImpulse = 35,
	-- Brief disable on re-attach to the same wall, prevents instant re-grip.
	NoRegripTime = 0.35,
}

ScalingConfig.Mantle = {
	-- Range of ledge heights above the player's feet that are mantle-able.
	MinHeight = 3.0,
	MaxHeight = 8.0,
	-- How far forward we look for a wall to mantle over.
	ForwardReach = 3.0,
	-- Top platform must have at least this much horizontal clear space.
	TopClearance = 2.0,
	-- Duration of the mantle animation/tween.
	Duration = 0.55,
	-- Forward offset applied at the end of the mantle (lands on top, not flush against the edge).
	LandForwardOffset = 1.4,
	-- Auto-trigger when jumping into a wall (vs. requiring a button press).
	AutoOnJump = true,
}

ScalingConfig.Vault = {
	-- Vault height window, measured from the player's feet upward. This is
	-- intentionally below Mantle's MinHeight so the two don't fight: anything
	-- waist-to-chest height vaults, anything taller mantles.
	MinHeight = 1.5,
	MaxHeight = 4.0,
	-- How far in front of the player the obstacle can be.
	ForwardReach = 3.5,
	-- Obstacle must be no thicker than this on the depth axis (fence/railing
	-- profile). 4 studs covers most fences and low walls without including
	-- 6+ stud-deep walls.
	MaxThickness = 4.5,
	-- Beyond the far edge, the landing area must be at most this much lower
	-- than the take-off height (don't vault off a cliff into a 50-stud drop).
	MaxLandingDrop = 8.0,
	-- Required clear horizontal space immediately past the far edge.
	FarSideClearance = 2.0,
	-- Duration of the arc.
	Duration = 0.45,
	-- Apex of the arc, in studs above the obstacle's top.
	ApexClearance = 1.6,
	-- Forward velocity applied to HRP on landing so the player keeps momentum.
	ExitVelocity = 28,
	-- Cooldown before the next vault can fire.
	Cooldown = 0.8,
}

-- Surfaces. Anything tagged Climbable=true overrides everything; NoClimb=true
-- always blocks. Otherwise we fall back to this material whitelist.
ScalingConfig.Surfaces = {
	WhitelistedMaterials = {
		[Enum.Material.Wood] = true,
		[Enum.Material.WoodPlanks] = true,
		[Enum.Material.Brick] = true,
		[Enum.Material.Concrete] = true,
		[Enum.Material.Slate] = true,
		[Enum.Material.Rock] = true,
		[Enum.Material.Cobblestone] = true,
		[Enum.Material.Pebble] = true,
		[Enum.Material.Sandstone] = true,
		[Enum.Material.CrackedLava] = true,
		[Enum.Material.Granite] = true,
		[Enum.Material.Limestone] = true,
		[Enum.Material.Basalt] = true,
	},
	-- Names of folders/parts the climb raycast should ignore entirely.
	IgnoreFolders = {"FX", "Effects", "Hitboxes", "Bullets", "Projectiles"},
}

-- Animation IDs. Replace with real assets when available; placeholders won't
-- break the system, the AnimHandler:Fetch fallback will just return nil and
-- the mechanic still functions (silently).
ScalingConfig.Animations = {
	ClingIdle = "rbxassetid://0",
	ClimbUp = "rbxassetid://0",
	ClimbDown = "rbxassetid://0",
	ClimbSide = "rbxassetid://0",
	WallJump = "rbxassetid://0",
	Mantle = "rbxassetid://0",
}

ScalingConfig.Sounds = {
	Grip = "rbxassetid://0",
	ClimbStep = "rbxassetid://0",
	Mantle = "rbxassetid://0",
	WallJump = "rbxassetid://0",
	StaminaEmpty = "rbxassetid://0",
}

-- Lock-outs: scaling won't engage if any of these CombatData/character flags is set.
ScalingConfig.BlockingStates = {
	"CurrentlyAttacking", "Dashing", "Blocking", "Sliding", "Stunned", "Aerial",
}

return ScalingConfig
