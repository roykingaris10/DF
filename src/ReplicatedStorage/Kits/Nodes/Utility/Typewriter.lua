local Typewriter = {}
Typewriter.__index = Typewriter

-- Default settings
local DEFAULT_SETTINGS = {
	writeSpeed = 0.05, -- Time between characters (in seconds)
	errorChance = 0.1, -- 10% chance of error per word
	errorDelay = 0.5, -- Time to wait before correcting error (in seconds)
	errorSound = nil, -- Optional SoundId for error sound
	correctSound = nil, -- Optional SoundId for correction sound
	typeSound = nil, -- Optional SoundId for typing sound
	maxErrorsPerWord = 1 -- Maximum errors allowed per word
}

-- Create a new Typewriter instance
function Typewriter.new(textLabel, settings)
	local self = setmetatable({}, Typewriter)

	self.textLabel = textLabel
	self.settings = setmetatable(settings or {}, {__index = DEFAULT_SETTINGS})
	self.running = false
	self.currentTask = nil

	return self
end

-- Internal function to split text into words
local function splitWords(text)
	local words = {}
	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end
	return words
end

-- Internal function to play sound if configured
local function playSound(soundId, parent)
	if soundId and parent then
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Parent = parent
		sound:Play()
		game:GetService("Debris"):AddItem(sound, sound.TimeLength + 0.1)
	end
end

-- Internal function to get a random wrong character
local function getWrongChar(correctChar)
	-- If correct character is a letter, return a different letter
	if correctChar:match("%a") then
		local wrongChar
		repeat
			wrongChar = string.char(math.random(97, 122)) -- Random lowercase letter
		until wrongChar ~= correctChar:lower()
		return wrongChar
	end
	-- For non-letters, just return a random letter
	return string.char(math.random(97, 122))
end

-- Type out text with typewriter effect
function Typewriter:writeText(text)
	if self.running then
		self:Stop()
	end

	self.running = true
	self.textLabel.Text = ""

	local words = splitWords(text)
	local currentText = ""
	local wordIndex = 1
	local errorsMadeInCurrentWord = 0

	local function processNextWord()
		if not self.running or wordIndex > #words then
			self.running = false
			return
		end

		local word = words[wordIndex]
		local charIndex = 1
		errorsMadeInCurrentWord = 0

		local function processNextCharacter()
			if not self.running or charIndex > #word then
				-- Move to next word
				wordIndex = wordIndex + 1
				errorsMadeInCurrentWord = 0

				-- Add space unless it's the last word
				if wordIndex <= #words then
					currentText = currentText .. " "
					self.textLabel.Text = currentText
				end

				-- Process next word after a small delay
				task.delay(self.settings.writeSpeed, processNextWord)
				return
			end

			local currentChar = word:sub(charIndex, charIndex)

			-- Decide if we should make an error for this character
			if errorsMadeInCurrentWord < self.settings.maxErrorsPerWord and 
				math.random() < self.settings.errorChance then

				errorsMadeInCurrentWord = errorsMadeInCurrentWord + 1

				-- Type wrong character
				local wrongChar = getWrongChar(currentChar)
				currentText = currentText .. wrongChar
				self.textLabel.Text = currentText

				-- Play error sound
				playSound(self.settings.errorSound, self.textLabel)

				-- Wait then backspace and type correct character
				task.delay(self.settings.errorDelay, function()
					if not self.running then return end

					-- Backspace
					currentText = currentText:sub(1, -2)
					self.textLabel.Text = currentText

					-- Play correction sound
					playSound(self.settings.correctSound, self.textLabel)

					-- Add correct character
					task.delay(self.settings.writeSpeed, function()
						if not self.running then return end

						currentText = currentText .. currentChar
						self.textLabel.Text = currentText
						playSound(self.settings.typeSound, self.textLabel)

						charIndex = charIndex + 1
						self.currentTask = task.delay(self.settings.writeSpeed, processNextCharacter)
					end)
				end)
			else
				-- No error, just process normally
				currentText = currentText .. currentChar
				self.textLabel.Text = currentText
				playSound(self.settings.typeSound, self.textLabel)

				charIndex = charIndex + 1
				self.currentTask = task.delay(self.settings.writeSpeed, processNextCharacter)
			end
		end

		-- Start processing this word
		processNextCharacter()
	end

	-- Start processing
	processNextWord()
end

-- Stop the current typewriter animation
function Typewriter:Stop()
	self.running = false
	if self.currentTask then
		task.cancel(self.currentTask)
		self.currentTask = nil
	end
end

-- Check if typewriter is currently running
function Typewriter:isRunning()
	return self.running
end

return Typewriter