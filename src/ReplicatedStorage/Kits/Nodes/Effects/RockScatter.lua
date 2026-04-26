local RockScatter = {}

local DB = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = ReplicatedStorage.Kits
local Nodes = Kits.Nodes

local Auxiliary = require(Nodes.Utility.Auxiliary)

function RockScatter.new(spawnCF: CFrame, rockCount: number?, blastForce: number?,	sizeTable: {number}?, color: Color3?, material: string?)
	sizeTable = sizeTable or {.3,.4,.5,.6,.7}
	rockCount = rockCount or math.random(5,8)
	local spreadAngle = 360/rockCount
	
	if not color or not material then
		local rayResult = workspace:Raycast(spawnCF.Position, Vector3.new(0,-7,0), Auxiliary.Shared.RayParams.Map)
		
		if rayResult then
			if not color then
				color = rayResult.Instance.Color 
			elseif not material then
				material = rayResult.Instance.Material
			end
		end
	end
	
	for i = 1, rockCount do
		local angle = i*spreadAngle
		local rock = Instance.new("Part")
		rock.Material = material or "Plastic"
		rock.Color = color or Color3.fromRGB(47, 44, 42)
		rock.Anchored = false
		rock.CanCollide = true
		rock.Size = Vector3.new(1,1,1) * sizeTable[math.random(#sizeTable)]
		rock.CFrame =  spawnCF * CFrame.Angles(math.rad(math.random(70)),math.rad(angle),0)
		rock.Parent = workspace.EffectsFolder
		rock.CollisionGroup = "Debris"
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1,1,1) * 999
		if blastForce then
			bv.Velocity = rock.CFrame.LookVector * blastForce
		else
			bv.Velocity = rock.CFrame.LookVector * 30
		end
		bv.Parent = rock
		DB:AddItem(bv, .3)
		DB:AddItem(rock, 3)
		
		task.delay(2.5,function()
			game.TweenService:Create(rock,TweenInfo.new(0.5,Enum.EasingStyle.Cubic),{Size = Vector3.new(0,0,0)}):Play()
		end)
	end
end


return RockScatter
