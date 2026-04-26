local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")


local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(info)
	local self = setmetatable({}, Projectile)

	self.Radius = info.Radius or 1
	self.Gravity = info.Gravity or 1
	self.Wind = info.Wind or Vector3.new(0, 0, 0)
	self.DespawnTime = info.DespawnTime or 3
	self.Visualize = info.Visualize or false
	self.MaxBounces = info.MaxBounces or 0
	self.Decay = info.Decay or 1
	self.Threshold = info.Threshold or 3
	self.ClientEffect = info.ClientEffect or nil --optional
	self.Active = true
	self.TargetObject = info.TargetObject or nil -- optional
	self.OnBounce = info.OnBounce  or nil

	self.Params = RaycastParams.new()
	self.Params.FilterType = Enum.RaycastFilterType.Include
	self.Params.FilterDescendantsInstances = info.Whitelist or {}

	return self
end

function Projectile:Cast(start, dest, force)
	
	local object = self.TargetObject
	if object and object:IsA("Model") then
		object = object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChildWhichIsA("BasePart")
	end
	
	local conversion = 196.2 / 9.8
	local velocity = (dest - start).Unit * force * conversion

	local a = Vector3.new(self.Wind.X, self.Wind.Y - self.Gravity * 9.8, self.Wind.Z) * conversion

	local t = 0
	local totalTime = 0
	local bounces = 0
	local currentVelocity = velocity
	local currentPos = start
	local rayResult = nil
	local sphereResult = nil
	local found = false

	local index = tick()
	if self.ClientEffect then
		self.ClientEffect.EntityVFX:Fire({
			Module = self.ClientEffect.Module,
			SubModule = self.ClientEffect.SubModule,
		}, self.ClientEffect.FuncName, { index = index })
	end

	while not found and self.Active do
		local dt = task.wait()
		if not self.Active then
			break
		end
		if not found then
			t += dt
			totalTime += dt

			currentVelocity = velocity + a * t
			local projPos = Vector3.new(
				start.X + velocity.X * t + 0.5 * a.X * t * t,
				start.Y + velocity.Y * t + 0.5 * a.Y * t * t,
				start.Z + velocity.Z * t + 0.5 * a.Z * t * t
			)
			
			if self.TargetObject and not object then
				found = true
				break
			end

			if object then
				if not object.Parent then found = true break end
				if object.Parent:GetAttribute("Dragged") then
					found = true
					break
				end
				

				object.CFrame = CFrame.new(projPos)
			end

			rayResult = workspace:Raycast(currentPos, projPos - currentPos, self.Params)
			sphereResult = workspace:Spherecast(currentPos, self.Radius, projPos - currentPos, self.Params)

			if rayResult and sphereResult then
				local rayDist = (rayResult.Position - currentPos).Magnitude
				local sphereDist = (sphereResult.Position - currentPos).Magnitude
				if sphereDist < rayDist then
					rayResult = sphereResult
				end
			elseif sphereResult then
				rayResult = sphereResult
			end
			
			if self.ClientEffect then
				self.ClientEffect.EntityVFX:FireUDP({
					Module = self.ClientEffect.Module,
					SubModule = self.ClientEffect.SubModule,
				}, "Update", { index = index, currentPos = currentPos, projPos = projPos })
			end

			currentPos = projPos

			if self.Visualize then
				local Part = Instance.new("Part")
				Part.Size = Vector3.new(0.5, 0.5, 0.5)
				Part.Position = projPos
				Part.Anchored = true
				Part.CanCollide = false
				Part.Material = Enum.Material.Neon
				Part.Color = Color3.fromRGB(0, 255, 0)
				Part.Shape = Enum.PartType.Ball
				Part.Parent = workspace.EffectsFolder

				Debris:AddItem(Part, 0.5)
			end

			if rayResult then
				bounces += 1
				t = 0
				
				if self.OnBounce then
					self.OnBounce({
						Position = rayResult.Position,
						Normal = rayResult.Normal,
						BounceIndex = bounces,
						Velocity = currentVelocity,
						Object = self.TargetObject
					})
				end
				
				if bounces < self.MaxBounces then
					velocity = self.Decay * (currentVelocity - 2 * currentVelocity:Dot(rayResult.Normal) * rayResult.Normal)
					
					if velocity.Magnitude < self.Threshold then
						print("THRREESH")
						found = true
					end
					
					start = rayResult.Position + rayResult.Normal + Vector3.new(0,self.Radius/1.25,0) * 0.05
					currentPos = start
				else
					found = true
				end
			end

			if totalTime > self.DespawnTime then
				found = true
			end
		end
	end

	if rayResult then
		
		if self.TargetObject then
			local size = self.TargetObject:IsA("Model") and self.TargetObject:GetExtentsSize() or self.TargetObject.Size
			local offset = rayResult.Normal * (size.Y / 2 + 0.05)
			local finalPos = rayResult.Position + offset
			if self.TargetObject:IsA("Model") then
				self.TargetObject:PivotTo(CFrame.new(finalPos))
			else
				self.TargetObject.Position = finalPos
			end
		end
		
		if self.ClientEffect then
			self.ClientEffect.EntityVFX:FireUDP({
				Module = self.ClientEffect.Module,
				SubModule = self.ClientEffect.SubModule,
			}, "Delete", { index = index, endPos = rayResult })
		end

		if self.Visualize then
			local Part = Instance.new("Part")
			Part.Size = Vector3.new(1, 1, 1)
			Part.Position = rayResult.Position
			Part.Anchored = true
			Part.CanCollide = false
			Part.Material = Enum.Material.Neon
			Part.Color = Color3.fromRGB(131, 30, 255)
			Part.Shape = Enum.PartType.Ball
			Part.Parent = workspace.EffectsFolder

			Debris:AddItem(Part, 1.5)
		end
	else
		if self.ClientEffect then
			self.ClientEffect.EntityVFX:Fire({
				Module = self.ClientEffect.Module,
				SubModule = self.ClientEffect.SubModule,
			}, "Delete", { index = index, endPos = nil })
		end
	end
end

function Projectile:End()
	self.Active = false
	
	if self.ClientEffect then
		self.ClientEffect.EntityVFX:Fire({
			Module = self.ClientEffect.Module,
			SubModule = self.ClientEffect.SubModule,
		}, "Delete", { index = self._Index })
	end
end

return Projectile
