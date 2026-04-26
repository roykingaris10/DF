local WeaponInfo = {
	["Default"] = {
		Location = "Right Arm",
		C0 = CFrame.new(0,0,0),
	},
	["Melee"] = {
		Type = "Weapon",
		Sort = "Weapon",
		WeaponType = 'Melee',
		Desc = "Your basic fighting style.",
		Stackable = false,
	},
	["Cutlass"] = {
		Type = "Weapon",
		Sort = "Weapon",
		WeaponType = 'Sword',
		Desc = "A bandits' favorite weapon.",
		Stackable = false,
	},
	["Flintlock"] = {
		Type = "Weapon",
		Sort = "Weapon",
		WeaponType = 'Pistol',
		Desc = "Not to be used lightly.",
		Stackable = false,
	},  
}

return WeaponInfo
