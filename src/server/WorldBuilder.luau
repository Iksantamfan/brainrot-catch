-- Brainrot Catch — WorldBuilder.
-- Builds the whole 3D world from plain parts at server start: brown ground
-- with dirt paths, a teal river with Brainrot Bridge, the circular Chaos
-- Plaza hub, Meme Mountain with its giant thumbs-up statue, eight coloured
-- player bases around the edges, hills, trees, rocks and clouds. No unions,
-- no meshes, no SurfaceAppearance — plain parts only, so the place publishes
-- cleanly through Open Cloud and stays far under the instance cap.

local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

local GROUND_BROWN = Color3.fromRGB(139, 69, 19)
local PATH_BROWN = Color3.fromRGB(160, 100, 45)
local GRASS_GREEN = Color3.fromRGB(90, 180, 70)
local WATER_TEAL = Color3.fromRGB(32, 178, 170)
local WOOD_BROWN = Color3.fromRGB(120, 85, 50)
local ROCK_GREY = Color3.fromRGB(130, 130, 135)
local CLOUD_WHITE = Color3.fromRGB(245, 245, 250)

local worldFolder = nil

local function part(name, size, color, material, position, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = anchored ~= false
	p.CanCollide = true
	p.Position = position
	p.Parent = worldFolder
	return p
end

local function ball(name, size, color, material, position)
	local p = part(name, size, color, material, position)
	p.Shape = Enum.PartType.Ball
	return p
end

local function cylinder(name, size, color, material, position, rotation)
	local p = part(name, size, color, material, position)
	p.Shape = Enum.PartType.Cylinder
	if rotation then
		p.CFrame = CFrame.new(position) * rotation
	end
	return p
end

-- A dirt path from the plaza to one base.
local function buildPathToBase(baseDef)
	local from = Vector3.new(0, 0, 0)
	local to = baseDef.position
	local mid = (from + to) * 0.5
	local distance = (to - from).Magnitude
	local path = part("Path", Vector3.new(8, 0.2, distance), PATH_BROWN, Enum.Material.SmoothPlastic, Vector3.new(mid.X, 0.15, mid.Z))
	local yaw = math.atan2(to.X - from.X, to.Z - from.Z)
	path.CFrame = CFrame.new(mid.X, 0.15, mid.Z) * CFrame.Angles(0, yaw, 0)
end

local function buildBase(baseDef)
	local pos = baseDef.position
	-- Platform.
	part("BasePlatform", Vector3.new(36, 1, 36), baseDef.color, Enum.Material.SmoothPlastic, Vector3.new(pos.X, 0.5, pos.Z))
	-- Lighter floor pad.
	part("BaseFloor", Vector3.new(30, 0.3, 30), Color3.fromRGB(245, 240, 225), Enum.Material.SmoothPlastic, Vector3.new(pos.X, 1.1, pos.Z))
	-- Low walls on three sides; the gate side faces the plaza (map centre).
	local dx = -pos.X
	local dz = -pos.Z
	local dist = math.sqrt(dx * dx + dz * dz)
	dx /= dist
	dz /= dist
	local gateX = pos.X + dx * 18
	local gateZ = pos.Z + dz * 18
	-- Gate posts and beam.
	part("GatePost", Vector3.new(1.5, 7, 1.5), baseDef.color, Enum.Material.Neon, Vector3.new(gateX - dz * 5, 4.5, gateZ + dx * 5))
	part("GatePost", Vector3.new(1.5, 7, 1.5), baseDef.color, Enum.Material.Neon, Vector3.new(gateX + dz * 5, 4.5, gateZ - dx * 5))
	local beam = part("GateBeam", Vector3.new(12, 1.2, 1.5), baseDef.color, Enum.Material.Neon, Vector3.new(gateX, 8.2, gateZ))
	beam.CFrame = CFrame.new(gateX, 8.2, gateZ) * CFrame.Angles(0, math.atan2(dx, dz), 0)
	-- Back wall and side walls (low, so the base reads open from the plaza).
	local backX = pos.X - dx * 17
	local backZ = pos.Z - dz * 17
	local back = part("BaseWall", Vector3.new(36, 4, 1.5), baseDef.color, Enum.Material.SmoothPlastic, Vector3.new(backX, 3, backZ))
	back.CFrame = CFrame.new(backX, 3, backZ) * CFrame.Angles(0, math.atan2(dx, dz), 0)
	-- Money zone marker: a glowing disc where income ticks up.
	local disc = cylinder("MoneyZone", Vector3.new(1, 10, 10), Color3.fromRGB(255, 215, 60), Enum.Material.Neon, Vector3.new(pos.X, 1.4, pos.Z), CFrame.Angles(0, 0, math.pi / 2))
	disc.Transparency = 0.5
	disc.CanCollide = false
	-- Floating base name.
	local sign = part("BaseSign", Vector3.new(0.5, 0.5, 0.5), baseDef.color, Enum.Material.Neon, Vector3.new(pos.X, 12, pos.Z))
	sign.CanCollide = false
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 50)
	billboard.AlwaysOnTop = true
	billboard.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = baseDef.name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = billboard
end

local function buildPlaza()
	-- Circular platform.
	local platform = cylinder("PlazaPlatform", Vector3.new(2, 60, 60), Color3.fromRGB(220, 220, 225), Enum.Material.SmoothPlastic, Vector3.new(0, 1, 0), CFrame.Angles(0, 0, math.pi / 2))
	platform.CanCollide = true
	-- Glowing ring markers around the edge.
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi * 2 / 8)
		local marker = part("PlazaMarker", Vector3.new(2, 2, 2), Color3.fromRGB(255, 215, 60), Enum.Material.Neon, Vector3.new(math.cos(angle) * 29, 2.5, math.sin(angle) * 29))
		marker.CanCollide = false
	end
	-- Central pole with a glowing orb: the hub you navigate by.
	cylinder("PlazaPole", Vector3.new(16, 1.5, 1.5), Color3.fromRGB(80, 80, 90), Enum.Material.Metal, Vector3.new(0, 9, 0), CFrame.Angles(0, 0, math.pi / 2))
	local orb = ball("PlazaOrb", Vector3.new(5, 5, 5), Color3.fromRGB(255, 215, 60), Enum.Material.Neon, Vector3.new(0, 19, 0))
	orb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 215, 60)
	light.Range = 40
	light.Brightness = 1.5
	light.Parent = orb
end

local function buildMountain()
	local pos = Config.MOUNTAIN_POSITION
	-- Stacked cone: three shrinking cylinders.
	cylinder("MountainBase", Vector3.new(10, 70, 70), Color3.fromRGB(120, 95, 70), Enum.Material.SmoothPlastic, Vector3.new(pos.X, 5, pos.Z), CFrame.Angles(0, 0, math.pi / 2))
	cylinder("MountainMid", Vector3.new(12, 45, 45), Color3.fromRGB(105, 85, 65), Enum.Material.SmoothPlastic, Vector3.new(pos.X, 15, pos.Z), CFrame.Angles(0, 0, math.pi / 2))
	cylinder("MountainTop", Vector3.new(10, 22, 22), Color3.fromRGB(90, 75, 60), Enum.Material.SmoothPlastic, Vector3.new(pos.X, 24, pos.Z), CFrame.Angles(0, 0, math.pi / 2))
	-- Giant thumbs-up statue: wrist + fist + thumb, bright yellow.
	cylinder("ThumbWrist", Vector3.new(8, 3, 3), Color3.fromRGB(255, 210, 40), Enum.Material.SmoothPlastic, Vector3.new(pos.X, 33, pos.Z), CFrame.Angles(0, 0, math.pi / 2))
	local fist = part("ThumbFist", Vector3.new(5, 4, 4), Color3.fromRGB(255, 210, 40), Enum.Material.SmoothPlastic, Vector3.new(pos.X, 38, pos.Z))
	fist.CanCollide = false
	local thumb = part("ThumbUp", Vector3.new(2, 5, 2), Color3.fromRGB(255, 210, 40), Enum.Material.SmoothPlastic, Vector3.new(pos.X + 1.2, 42, pos.Z))
	thumb.CanCollide = false
end

local function buildBridge()
	local center = Config.BRIDGE_CENTER
	-- Deck over the river (river runs z 45..75).
	part("BridgeDeck", Vector3.new(14, 1, 40), WOOD_BROWN, Enum.Material.WoodPlanks, Vector3.new(center.X, 1.5, center.Z))
	-- Rails on both sides.
	part("BridgeRail", Vector3.new(1, 2.5, 40), Color3.fromRGB(90, 60, 35), Enum.Material.Wood, Vector3.new(center.X - 6.5, 3.2, center.Z))
	part("BridgeRail", Vector3.new(1, 2.5, 40), Color3.fromRGB(90, 60, 35), Enum.Material.Wood, Vector3.new(center.X + 6.5, 3.2, center.Z))
	-- Ramps on both ends.
	local rampNorth = Instance.new("WedgePart")
	rampNorth.Name = "BridgeRamp"
	rampNorth.Size = Vector3.new(14, 1.5, 8)
	rampNorth.Color = WOOD_BROWN
	rampNorth.Material = Enum.Material.WoodPlanks
	rampNorth.Anchored = true
	rampNorth.CFrame = CFrame.new(center.X, 0.8, center.Z - 24) * CFrame.Angles(0, math.pi, 0)
	rampNorth.Parent = worldFolder
	local rampSouth = Instance.new("WedgePart")
	rampSouth.Name = "BridgeRamp"
	rampSouth.Size = Vector3.new(14, 1.5, 8)
	rampSouth.Color = WOOD_BROWN
	rampSouth.Material = Enum.Material.WoodPlanks
	rampSouth.Anchored = true
	rampSouth.CFrame = CFrame.new(center.X, 0.8, center.Z + 24)
	rampSouth.Parent = worldFolder
end

local function buildTreesAndHills()
	local rng = Random.new(1337)
	-- Hills: big squashed spheres in the wild field.
	for i = 1, 10 do
		local x = rng:NextNumber(-160, 160)
		local z = rng:NextNumber(-160, 160)
		if (z < 40 or z > 80) and math.abs(x) > 35 and math.abs(z) > 35 then
			local hill = ball("Hill", Vector3.new(rng:NextNumber(18, 30), rng:NextNumber(5, 9), rng:NextNumber(18, 30)), GRASS_GREEN, Enum.Material.SmoothPlastic, Vector3.new(x, 1, z))
			hill.CanCollide = false
		end
	end
	-- Trees: trunk + leafy ball.
	for i = 1, 24 do
		local x = rng:NextNumber(-170, 170)
		local z = rng:NextNumber(-170, 170)
		if (z < 40 or z > 80) and math.abs(x) > 32 and math.abs(z) > 32 then
			local clear = true
			for _, base in ipairs(Config.BASES) do
				local dx = x - base.position.X
				local dz = z - base.position.Z
				if dx * dx + dz * dz < 26 * 26 then
					clear = false
					break
				end
			end
			if clear then
				cylinder("TreeTrunk", Vector3.new(5, 1.6, 1.6), Color3.fromRGB(110, 75, 40), Enum.Material.Wood, Vector3.new(x, 2.5, z), CFrame.Angles(0, 0, math.pi / 2))
				local leaves = ball("TreeLeaves", Vector3.new(7, 7, 7), GRASS_GREEN, Enum.Material.SmoothPlastic, Vector3.new(x, 8, z))
				leaves.CanCollide = false
			end
		end
	end
	-- Rocks.
	for i = 1, 12 do
		local x = rng:NextNumber(-170, 170)
		local z = rng:NextNumber(-170, 170)
		if (z < 40 or z > 80) then
			local rock = ball("Rock", Vector3.new(rng:NextNumber(2, 5), rng:NextNumber(2, 4), rng:NextNumber(2, 5)), ROCK_GREY, Enum.Material.Slate, Vector3.new(x, 1, z))
			rock.CanCollide = false
		end
	end
	-- Clouds drifting high above.
	for i = 1, 8 do
		local x = rng:NextNumber(-180, 180)
		local z = rng:NextNumber(-180, 180)
		local cloud = ball("Cloud", Vector3.new(16, 5, 10), CLOUD_WHITE, Enum.Material.SmoothPlastic, Vector3.new(x, rng:NextNumber(45, 65), z))
		cloud.CanCollide = false
		cloud.Anchored = true
	end
	-- Grass tufts: small flat green discs scattered on the ground.
	for i = 1, 20 do
		local x = rng:NextNumber(-180, 180)
		local z = rng:NextNumber(-180, 180)
		if (z < 42 or z > 78) then
			local tuft = cylinder("GrassTuft", Vector3.new(0.3, rng:NextNumber(4, 8), rng:NextNumber(4, 8)), GRASS_GREEN, Enum.Material.Grass, Vector3.new(x, 0.2, z), CFrame.Angles(0, 0, math.pi / 2))
			tuft.CanCollide = false
		end
	end
end

function WorldBuilder.buildWorld()
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "BrainrotWorld"
	worldFolder.Parent = Workspace

	-- Ground comes from the Rojo project's baseplate (default.project.json),
	-- top at y = 0, so the world builder does not lay a second slab.
	-- Teal river across the middle (z 45..75). A visual sheet over the ground.
	local river = part("River", Vector3.new(420, 0.4, 30), WATER_TEAL, Enum.Material.SmoothPlastic, Vector3.new(0, 0.25, 60))
	river.Transparency = 0.25
	river.CanCollide = false

	for _, baseDef in ipairs(Config.BASES) do
		buildPathToBase(baseDef)
		buildBase(baseDef)
	end
	buildPlaza()
	buildMountain()
	buildBridge()
	buildTreesAndHills()

	return worldFolder
end

return WorldBuilder
