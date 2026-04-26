return {
	Denji = {
		Full = 'Devil Hunter';
		AwakeningName = 'Chainsaw Devil';

		Icon = 'rbxassetid://0';
		LayoutOrder = 1;

		Moveset = {
			Base = {
				[1] = {Name='Palm Strike', Vanity='Palm Strike'};
				[2] = {Name='Fury Combo', Vanity='Fury Combo',
					Data = {
						KickSpeed = 250;
						Duration = 1;
					};
				};
				[3] = {Name='Crushing Slam', Vanity='Crushing Slam', Data = {
					Duration = 1.13,
					MoveSpeed = 15;
				}};
			--	[3] = {Name='Leg Sweep', Vanity='Leg Sweep', Data = {
			--		Duration = 1.13,
			--		MoveSpeed = 15;
			--	}};
				[4] = {Name='Nut Kick', Vanity='Nut Kick', Data = {
					StunDuration = 1.5;
				}}
			};
			Awakening = {
				[1] = {Name='CoolCombo', Vanity='Cool Combo'};
				[2] = {Name='2ndCoolCombo', Vanity='Drag Skill'};
				[3] = {Name='Helicopter', Vanity='Spinny'};
				[4] = {Name='Sky Breaker', Vanity='Sky Breaker'};
			};
		};
	};
	Aki = {
		Full = 'Aki';
		AwakeningName = 'hahahhaha';

		Icon = 'rbxassetid://0';
		LayoutOrder = 2;

		Moveset = {
			Base = {
				[1] = {Name='Counter', Vanity='Counter', Data = {
					Duration = 1;
				}};
				[2] = {Name='Kon', Vanity='Kon'};
				StunDuration = 1;
				
				[3] = {Name='Down Strike', Vanity='Down Strike'};
				
				[4] = {Name='Slash Barrage', Vanity='Slash Barrage'};
			};
			
			
			Awakening = {
				
			};
		};
	};
	Power = {
		Full = 'Blood Baby';
		AwakeningName = 'Blood Fiend';

		Icon = 'rbxassetid://0';
		LayoutOrder = 3;

		Moveset = {
			Base = {
				[1] = {Name='Blood Cutter', Vanity='Blood Cutter'};
				[2] = {Name='Blood Buster', Vanity='Blood Buster'};
			};
			Awakening = {
				[1] = {Name='Example Awakening Skill', Vanity='Example Awakening Skill'};
			};
		};
	};
};