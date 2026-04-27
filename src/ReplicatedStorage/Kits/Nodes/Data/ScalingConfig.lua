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
	-- Vault height window, measured from the player's feet upward.
	-- Original game's rule was: top of obstacle within 1 stud above HRP center
	-- (HRP center is ~3 studs above feet, so up to ~4 above feet).
	MinHeight = 1.5,
	MaxHeight = 4.0,
	-- How far in front of the player the obstacle face can be.
	ForwardReach = 5.0,
	-- BodyVelocity tunables (matches the original game's feel).
	-- Forward velocity in studs/s applied for VelocityDuration.
	ForwardImpulse = 40,
	-- Vertical velocity component, gives the hop arc.
	UpwardImpulse = 15,
	-- Duration the BodyVelocity stays attached. Long enough to clear the
	-- obstacle, short enough that physics takes over for the landing.
	VelocityDuration = 0.2,
	-- Animation playback speed multiplier (original used 1.2).
	AnimSpeed = 1.2,
	-- Cooldown before the next vault can fire.
	Cooldown = 1.5,
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
