local CharacterInfo = {
	["Fists"] = {
		Description = "";
		Classification = "Melee";
		ResetComboTimer = 1.2;
		ComboMax = 5;
		ComboCooldown = 1.05;
		HeavyCooldown = 2;
		AerialCooldown = 3;
		LightDamage = 2;
		LightPostureDamage = 20,
		LightStun = 0.45;
		HeavyDamage = 6,
		HeavyPostureDamage = 100,
		CriticalClashWindow = 0.4, --0.3
		AerialDamage = 3,
		AerialPostureDamage = 20,
		AerialClashDuration = 0.25;
		AerialClashWindow = 0.4;
		Range = 5;
		CriticalRange = 6.5;
		AerialRange = 7.5;
		SwingSpeed = 1;
		Pen = .3;
		Timings = {
			Hitbox = {
				Light1 = 0.25;
				Light2 = 0.25;
				Light3 = 0.25;
				Light4 = 0.25;
				Light5 = 0.27;
				Uptilt = 0.4;
				Downslam = 0.33;
				Airpush = 0.38;
				Critical = 0.4;
				AirCritical = 0.5;
				Aerial = 0.22;
			};
			Endlag = {
				Light1 = 0.42;
				Light2 = 0.48;
				Light3 = 0.47;
				Light4 = 0.47;
				Light5 = 0.57;
				Uptilt = 0.56;
				Downslam = 0.55;
				Airpush = 0.62;
				Critical = 0.68;
				AirCritical = 0.56;
				Aerial = 0.55;
			};
			Duration = {
				Aerial = 0.21;
			}
		};
		AnimationTimes = {
			Light1 = 1.1;
			Light2 = 1.1;
			Light3 = 1.1;
			Light4 = 1.1;
			Light5 = 1.1;
			Critical = 1;
			Uptilt = 0.8;
			Downslam = 0.8;
			Aerial = 1.15;
		};
		HitboxProp = {
			Range = 6;
			Width = 6;
			Height = 8;
		};
		HitStun = {
			[1] = 0.5,
			[2] = 0.5,
			[3] = 0.3,
			[4] = 0.3,
			[5] = 0.8,
		}
	},
}

return CharacterInfo
