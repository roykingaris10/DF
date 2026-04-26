return {
	OwnerGroup = 34702126;
	GameID = 18711700982;
	
	Coins = "rbxassetid://15993201893";
	Gems = "rbxassetid://126821991";

	BANNED_ACCESSORY_TYPES = {
		[Enum.AccessoryType.Back] = true;
		[Enum.AccessoryType.Shoulder] = true;
		[Enum.AccessoryType.Waist] = true;
		[Enum.AccessoryType.Neck] = true;
	};
	
	InCombatDuration = 15;
	StatMax = 50;
	WalkSpeed = 15;
	RunSpeed = 25;
	Jump = 50;
	Gravity = 196.2;
	DoubleJumpCD = 1;
	ClashDuration = 0.7;
	WillProc = {
		Cooldown = 4,
		Duration = 3.5,
		Cost = 35,
	};
	WillDashInfo = {
		Cooldown = 5,
		Duration = 0.3,
		Speed = 95,
	},
	AirDashInfo = {
		Cooldown = 3;
		Power = 75,
		DecelerateTime = 0.23,
		DecelTween = 0.25,
		DebrisTime = 0.27,
	};
	DashInfo = {
		Cooldown = 2.5;
		Front = {
			Power = 70;
			DecelStart = 0.165;
			DecelTween = 0.295;
			DebrisTime = 0.295;
			IFrameDuration = 0.325;
		};
		Backward = {
			Power = 75;
			DecelStart = 0.175;
			DecelTween = 0.425;
			DebrisTime = 0.35;
			IFrameDuration = 0.325;
		};
		Side = {
			Power = 70,
			DecelStart = 0.15;
			DecelTween = 0.28;
			DebrisTime = 0.33;
			IFrameDuration = 0.43;
		};
	};
	Camera = {
		Distance = 12,
		Height = 4,
		LeftOffset = 0,
		ForwardFollow = 0.85,
		SideFollow = 1.0,
		VerticalFollow = 1, -- How much camera follows vertical movement
		Smoothness = 0.05,
		SettingsLerpSpeed = 0.1, -- How fast settings transition
	}
}
