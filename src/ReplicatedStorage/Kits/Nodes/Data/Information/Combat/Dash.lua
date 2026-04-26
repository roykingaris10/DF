return {
	
	Cooldown = 1.5,
	Front = {
		AnimSpeed = 0.8,
		Power = 80,
		DecelStart = 0.35,
		DecelTween = 0.4,
		DebrisTime = 0.45
	},
	Side = {
		AnimSpeed = 0.95,
		Power = 90,
		DecelStart = 0.225,
		DecelTween = 0.35,
		DebrisTime = 0.4
	},
	
	Durations = {
		HitEndlag = {
			Hit=.3;
			Miss=.5;
		};
		ForwardDurationMultiplier = .55;
		Forward = 1;
		Side = .6;
		Backward = {
			[1] = 0.2;
			[2] = 0.4;
		};
	};
};