local LowGFXService = {}

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local State = {
	enabled = false,
	originalSettings = {},
	disabledEffects = {},
	disabledLights = {},
	disabledTextures = {},
	disabledDecals = {},
	meshTextureIds = {},
	connections = {},
}

local function disableLightingEffects()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		State.disabledEffects.Atmosphere = { instance = atmosphere, Density = atmosphere.Density }
		atmosphere.Density = 0
	end

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		State.disabledEffects.Bloom = { instance = bloom, Enabled = bloom.Enabled }
		bloom.Enabled = false
	end

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sunRays then
		State.disabledEffects.SunRays = { instance = sunRays, Enabled = sunRays.Enabled }
		sunRays.Enabled = false
	end

	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		State.disabledEffects.DOF = { instance = dof, Enabled = dof.Enabled }
		dof.Enabled = false
	end

	local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if colorCorrection then
		State.disabledEffects.ColorCorrection = {
			instance = colorCorrection,
			Saturation = colorCorrection.Saturation,
			Contrast = colorCorrection.Contrast,
		}
		colorCorrection.Saturation = 0
		colorCorrection.Contrast = 0
	end

	for _, blur in ipairs(Lighting:GetChildren()) do
		if blur:IsA("BlurEffect") then
			State.disabledEffects[blur] = { instance = blur, Size = blur.Size }
			blur.Size = 0
		end
	end
end

local function restoreLightingEffects()
	for name, data in pairs(State.disabledEffects) do
		local instance = data.instance
		if instance and instance.Parent then
			if name == "Atmosphere" then
				instance.Density = data.Density
			elseif name == "ColorCorrection" then
				instance.Saturation = data.Saturation
				instance.Contrast = data.Contrast
			elseif data.Enabled ~= nil then
				instance.Enabled = data.Enabled
			elseif data.Size ~= nil then
				instance.Size = data.Size
			end
		end
	end
	State.disabledEffects = {}
end

local function disableWorldLights()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			if descendant.Enabled then
				State.disabledLights[descendant] = true
				descendant.Enabled = false
			end
		end
	end
end

local function restoreWorldLights()
	for light in pairs(State.disabledLights) do
		if light and light.Parent then
			light.Enabled = true
		end
	end
	State.disabledLights = {}
end

local function disableTextures()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Texture") then
			State.disabledTextures[descendant] = descendant.Transparency
			descendant.Transparency = 1
		elseif descendant:IsA("Decal") then
			State.disabledDecals[descendant] = descendant.Transparency
			descendant.Transparency = 1
		elseif descendant:IsA("MeshPart") then
			if descendant.TextureID ~= "" then
				State.meshTextureIds[descendant] = descendant.TextureID
				descendant.TextureID = ""
			end
		end
	end
end

local function restoreTextures()
	for texture, transparency in pairs(State.disabledTextures) do
		if texture and texture.Parent then
			texture.Transparency = transparency
		end
	end
	State.disabledTextures = {}

	for decal, transparency in pairs(State.disabledDecals) do
		if decal and decal.Parent then
			decal.Transparency = transparency
		end
	end
	State.disabledDecals = {}

	for meshPart, textureId in pairs(State.meshTextureIds) do
		if meshPart and meshPart.Parent then
			meshPart.TextureID = textureId
		end
	end
	State.meshTextureIds = {}
end

local function setupNewInstanceHandler()
	local conn = Workspace.DescendantAdded:Connect(function(descendant)
		if not State.enabled then return end

		if descendant:IsA("Texture") then
			State.disabledTextures[descendant] = descendant.Transparency
			descendant.Transparency = 1
		elseif descendant:IsA("Decal") then
			State.disabledDecals[descendant] = descendant.Transparency
			descendant.Transparency = 1
		elseif descendant:IsA("MeshPart") then
			if descendant.TextureID ~= "" then
				State.meshTextureIds[descendant] = descendant.TextureID
				descendant.TextureID = ""
			end
		elseif descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			if descendant.Enabled then
				State.disabledLights[descendant] = true
				descendant.Enabled = false
			end
		end
	end)
	table.insert(State.connections, conn)
end

local function applyLowSettings()
	State.originalSettings.GlobalShadows = Lighting.GlobalShadows
	State.originalSettings.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
	State.originalSettings.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale

	Lighting.GlobalShadows = false
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
end

local function restoreSettings()
	if State.originalSettings.GlobalShadows ~= nil then
		Lighting.GlobalShadows = State.originalSettings.GlobalShadows
	end
	if State.originalSettings.EnvironmentDiffuseScale ~= nil then
		Lighting.EnvironmentDiffuseScale = State.originalSettings.EnvironmentDiffuseScale
	end
	if State.originalSettings.EnvironmentSpecularScale ~= nil then
		Lighting.EnvironmentSpecularScale = State.originalSettings.EnvironmentSpecularScale
	end
	State.originalSettings = {}
end

function LowGFXService:Enable()
	if State.enabled then return end
	State.enabled = true
	applyLowSettings()
	disableLightingEffects()
	disableWorldLights()
	disableTextures()
	setupNewInstanceHandler()
end

function LowGFXService:Disable()
	if not State.enabled then return end
	State.enabled = false
	for _, conn in ipairs(State.connections) do
		conn:Disconnect()
	end
	State.connections = {}
	restoreSettings()
	restoreLightingEffects()
	restoreWorldLights()
	restoreTextures()
end

function LowGFXService:Toggle()
	if State.enabled then
		LowGFXService:Disable()
	else
		LowGFXService:Enable()
	end
end

function LowGFXService:IsEnabled()
	return State.enabled
end

return LowGFXService