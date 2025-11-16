local Config = {}

-- ParkourController Config
Config.Movement = {
	WalkSpeed = 16,
	SprintSpeed = 28,
	CrouchSpeed = 8,
	SlideSpeedBoost = 32, -- Initial speed when starting a slide
	SlideDeceleration = 10, -- How quickly slide speed drops
	MinSlideSpeed = 10, -- Speed at which slide transitions to crouch-walk
}

Config.Physics = {
	Gravity = 196.2, -- Default Roblox gravity
}

Config.Raycasts = {
	WallCheckDistance = 2.5,
	LedgeCheckHeight = 4, -- How far down from a wall hit to check for a ledge
	LedgeCheckForward = 1.5, -- How far forward from the ledge to check for ground
	GroundCheckDistance = 3, -- From HRP
}

-- FullBodyCameraController Config
Config.Camera = {
	Sensitivity = 0.15,
	MaxPitch = 85, -- Max degrees up/down
	RotationSmoothness = 20, -- A higher 'k' value for frame-rate independent smoothing
	FovSmoothness = 12,

	DefaultFov = 70,
	SprintFov = 85,
	CrouchFov = 65,
	SlideFov = 95,

	-- Procedural Camera Bob
	WalkBobFrequency = 10,
	WalkBobAmplitude = 0.15,
	SprintBobFrequency = 16,
	SprintBobAmplitude = 0.25,
	CrouchBobFrequency = 8,
	CrouchBobAmplitude = 0.1,

	-- Camera Roll
	MaxStrafeRoll = 2.5, -- Max degrees of roll when strafing
	RollSmoothness = 10,
}

-- AnimationController Config
Config.Animation = {
	WeightSmoothness = 10, -- 'k' value for lerping animation weights
	DirectionalBlendSpeed = 15, -- How fast the directional blend vector updates
	DefaultFadeTime = 0.2,
}

return Config