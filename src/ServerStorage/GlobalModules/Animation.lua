local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimHandler = {}
AnimHandler.__index = AnimHandler

function AnimHandler.new(Character: Model)
	local self = setmetatable({}, AnimHandler)
	
	self.Character = Character
	local humanoid = Character:FindFirstChild("Humanoid")
	if humanoid and humanoid:FindFirstChild("Animator") then
		self.Animator = humanoid:FindFirstChild("Animator")
	elseif Character:FindFirstChild("AnimationController") then
		local animController = Character:FindFirstChild("AnimationController")
		self.Animator = animController:FindFirstChild("Animator")
	end
	
	if not self.Animator then
		warn("No Animator found for rig:", self.Character)
		return self
	end
	
	self.StoredAnims = {
		General = {},
		BaseCombat = {},
		WeaponCombat = {},
		Temp = {},
	}
	return self;
end

function AnimHandler:GetAnim(Name, Section)
	if self.StoredAnims[Section][Name] then
		return self.StoredAnims[Section][Name]
	end
end

function AnimHandler:Play(Name, Section)
	if self.StoredAnims[Section][Name] then
		self.StoredAnims[Section][Name]:Play()
		return self.StoredAnims[Section][Name]
	end
end

function AnimHandler:PlayId(TrackId,Name,NotAutoCleanup)
	local Animation = Instance.new("Animation")
	Animation.Name = Name or "Animation"
	Animation.AnimationId = 'rbxassetid://'..TrackId
	local Anim = self.Animator:LoadAnimation(Animation)
	Anim:Play()
	if not NotAutoCleanup then
		Anim.Stopped:Connect(function()
			Animation:Destroy()
		end)
	end
	return Anim
end

function AnimHandler:Load(Name,Track,Section)
	if not Section then
		Section = "Temp"
	end
	
	if not self.StoredAnims[Section][Name] then
		local Animation = Instance.new("Animation")
		Animation.Name = Name
		Animation.AnimationId = 'rbxassetid://'..Track
		self.StoredAnims[Section][Name] = self.Animator:LoadAnimation(Animation) 
		Animation:Destroy()
	end
	
	return self.StoredAnims[Section][Name]
end

function AnimHandler:LoadAnims(Section,Tracklist)
	for name, anim in pairs(Tracklist) do
		if type(anim) == 'number' then
			self:Load(name,anim,Section)
		elseif type(anim) == 'table' then
			self.LoadAnims(Section, anim)
		end
	end
end

function AnimHandler:CleanSection(Section)
	if self.StoredAnims[Section] then
		for _, track in pairs(self.StoredAnims[Section]) do
			track:Stop()
			track:Destroy()
		end
	end
end

function AnimHandler:CleanAllSections()
	for _, categoryTracks in pairs(self.StoredAnims) do
		for _, track in pairs(categoryTracks) do
			track:Stop()
			track:Destroy()
		end
	end
end

function AnimHandler:GetPlayingTrack(AnimationName: string)
	if not AnimationName then warn("[AnimationHandler]: Missing animation name") end

	for _, PlayingTrack in self.Animator:GetPlayingAnimationTracks() do
		if PlayingTrack.Name == AnimationName then
			return PlayingTrack
		end
	end
end

function AnimHandler:StopAll()
	for _, PlayingTrack in self.Animator:GetPlayingAnimationTracks() do
		PlayingTrack:Stop()
	end
end

function AnimHandler:Destroy()
	for _, categoryTracks in pairs(self.StoredAnims) do
		for _, track in pairs(categoryTracks) do
			track:Stop()
			track:Destroy()
		end
	end
	self.StoredAnims = {}
	self.Character = nil
	self.Animator = nil
end

return AnimHandler 
