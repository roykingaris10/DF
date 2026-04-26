local FishFlip = script.Parent

-- Settings
local FRAME_RATE = 12 -- frames per second (adjust for speed)
local LOOP = true -- set to false if you want it to play once

-- Collect frames in order
local frames = {}
for i = 1, 8 do
	local frame = FishFlip:FindFirstChild(tostring(i))
	if frame then
		frame.Visible = false
		table.insert(frames, frame)
	end
end

if #frames == 0 then
	warn("[FishFlip] No frames found")
	return
end

-- Animation variables
local currentFrame = 1
local isPlaying = true

-- Hide all frames
local function hideAll()
	for _, frame in ipairs(frames) do
		frame.Visible = false
	end
end

-- Show specific frame
local function showFrame(index)
	hideAll()
	if frames[index] then
		frames[index].Visible = true
	end
end

-- Main animation loop
local function playAnimation()
	while isPlaying do
		showFrame(currentFrame)

		currentFrame = currentFrame + 1
		if currentFrame > #frames then
			if LOOP then
				currentFrame = 1
			else
				isPlaying = false
				break
			end
		end

		task.wait(1 / FRAME_RATE)
	end
end

-- Start the animation
showFrame(1)
task.spawn(playAnimation)

-- Optional: Control functions if you need them elsewhere
local FlipbookController = {}

function FlipbookController:Play()
	if not isPlaying then
		isPlaying = true
		currentFrame = 1
		task.spawn(playAnimation)
	end
end

function FlipbookController:Stop()
	isPlaying = false
	hideAll()
end

function FlipbookController:Pause()
	isPlaying = false
end

function FlipbookController:SetFrameRate(fps)
	FRAME_RATE = fps
end

return FlipbookController