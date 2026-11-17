-- Brainrot Catch — ModelBuilder.
-- Builds every character as a chunky part-built model: an animal body with a
-- head, eyes and legs, the fused object on top of it, a glowing neon rarity
-- aura underneath, and a floating name / rarity / money-per-second label.
-- No meshes, no unions, no decals — plain parts only, so the place publishes
-- cleanly through Open Cloud.

local Config = require(script.Parent.Parent.Shared.Config)

local ModelBuilder = {}

local function newPart(name, size, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.Parent = parent
	return part
end

-- The fused object, built from parts on top of the animal body. `top` is the
-- Y of the top of the head; `depth` is the body's front-back size.
local function buildObject(objectKind, accentColor, model, top, depth)
	if objectKind == "bucket" then
		local bucket = newPart("Bucket", Vector3.new(1.6, 1.2, 1.6), accentColor, Enum.Material.Metal, model)
		bucket.CFrame = CFrame.new(0, top + 0.6, 0)
		local rim = newPart("BucketRim", Vector3.new(1.8, 0.25, 1.8), Color3.fromRGB(90, 90, 95), Enum.Material.Metal, model)
		rim.CFrame = CFrame.new(0, top + 1.2, 0)
	elseif objectKind == "hose" then
		for i = 1, 3 do
			local coil = newPart("HoseCoil", Vector3.new(0.5, 0.5, 1.4), accentColor, Enum.Material.SmoothPlastic, model)
			coil.CFrame = CFrame.new(-0.6 + (i - 1) * 0.6, top + 0.25, -depth * 0.5)
		end
		local nozzle = newPart("HoseNozzle", Vector3.new(0.4, 0.4, 0.9), Color3.fromRGB(220, 220, 220), Enum.Material.Metal, model)
		nozzle.CFrame = CFrame.new(0.9, top + 0.3, depth * 0.5)
	elseif objectKind == "tupperware" then
		local box = newPart("Tupperware", Vector3.new(2.0, 0.9, 1.6), accentColor, Enum.Material.Glass, model)
		box.Transparency = 0.35
		box.CFrame = CFrame.new(0, top + 0.45, -0.3)
		local lid = newPart("TupperwareLid", Vector3.new(2.2, 0.25, 1.8), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, model)
		lid.CFrame = CFrame.new(0, top + 0.95, -0.3)
	elseif objectKind == "fridge" then
		local fridge = newPart("Fridge", Vector3.new(1.9, 2.6, 1.2), accentColor, Enum.Material.Metal, model)
		fridge.CFrame = CFrame.new(0, top - 0.4, -depth * 0.5 - 0.4)
		local handle = newPart("FridgeHandle", Vector3.new(0.25, 1.4, 0.25), Color3.fromRGB(60, 60, 65), Enum.Material.Metal, model)
		handle.CFrame = CFrame.new(0.7, top - 0.4, -depth * 0.5 + 0.35)
	elseif objectKind == "bathtub" then
		local tub = newPart("Bathtub", Vector3.new(3.0, 1.2, 2.2), accentColor, Enum.Material.SmoothPlastic, model)
		tub.CFrame = CFrame.new(0, 0.6, 0)
		local rim = newPart("TubRim", Vector3.new(3.2, 0.3, 2.4), Color3.fromRGB(200, 200, 205), Enum.Material.SmoothPlastic, model)
		rim.CFrame = CFrame.new(0, 1.25, 0)
	elseif objectKind == "microwave" then
		local micro = newPart("Microwave", Vector3.new(2.0, 1.4, 1.4), accentColor, Enum.Material.Metal, model)
		micro.CFrame = CFrame.new(0, top + 0.1, -0.2)
		local screen = newPart("MicrowaveScreen", Vector3.new(0.7, 0.7, 0.15), Color3.fromRGB(140, 255, 160), Enum.Material.Neon, model)
		screen.CFrame = CFrame.new(0.55, top + 0.1, 0.6)
	elseif objectKind == "toaster" then
		local toaster = newPart("Toaster", Vector3.new(1.8, 1.1, 1.3), accentColor, Enum.Material.Metal, model)
		toaster.CFrame = CFrame.new(0, top + 0.55, 0)
		for i = 1, 2 do
			local slot = newPart("ToasterSlot", Vector3.new(0.6, 0.15, 1.0), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, model)
			slot.CFrame = CFrame.new(-0.4 + (i - 1) * 0.8, top + 1.15, 0)
		end
	elseif objectKind == "lamp" then
		local neck = newPart("LampNeck", Vector3.new(0.35, 1.6, 0.35), Color3.fromRGB(50, 50, 55), Enum.Material.Metal, model)
		neck.CFrame = CFrame.new(0, top + 0.8, -0.3)
		local bulb = newPart("LampBulb", Vector3.new(1.0, 1.0, 1.0), accentColor, Enum.Material.Neon, model)
		bulb.Shape = Enum.PartType.Ball
		bulb.CFrame = CFrame.new(0, top + 1.9, -0.3)
	elseif objectKind == "fan" then
		local pole = newPart("FanPole", Vector3.new(0.3, 1.4, 0.3), Color3.fromRGB(70, 70, 75), Enum.Material.Metal, model)
		pole.CFrame = CFrame.new(0, top + 0.7, 0)
		for i = 1, 3 do
			local blade = newPart("FanBlade", Vector3.new(1.5, 0.12, 0.45), accentColor, Enum.Material.SmoothPlastic, model)
			local angle = (i - 1) * (math.pi * 2 / 3)
			blade.CFrame = CFrame.new(math.cos(angle) * 0.7, top + 1.5, math.sin(angle) * 0.7)
				* CFrame.Angles(0, -angle, 0)
		end
	elseif objectKind == "subwoofer" then
		local box = newPart("Subwoofer", Vector3.new(2.6, 2.6, 1.4), Color3.fromRGB(15, 15, 18), Enum.Material.Metal, model)
		box.CFrame = CFrame.new(0, top - 0.5, -depth * 0.5 - 0.5)
		for i = 1, 2 do
			local speaker = newPart("Speaker", Vector3.new(0.2, 1.1, 1.1), accentColor, Enum.Material.Neon, model)
			speaker.Shape = Enum.PartType.Cylinder
			speaker.CFrame = CFrame.new(-0.6 + (i - 1) * 1.2, top - 0.5, -depth * 0.5 + 0.25)
				* CFrame.Angles(0, math.pi / 2, 0)
		end
	elseif objectKind == "monolith" then
		local slab = newPart("Monolith", Vector3.new(0.5, 3.2, 1.6), accentColor, Enum.Material.SmoothPlastic, model)
		slab.CFrame = CFrame.new(0, top + 1.0, -0.4) * CFrame.Angles(0, 0, 0.12)
		local glyph = newPart("Glyph", Vector3.new(0.3, 1.6, 0.2), Color3.fromRGB(255, 210, 40), Enum.Material.Neon, model)
		glyph.CFrame = CFrame.new(0.1, top + 1.0, 0.45)
	end
end

-- Builds one character model at the origin, facing +Z. `scale` shrinks the
-- model for base-slot displays (1 = full size, about 4 studs tall).
function ModelBuilder.buildCharacterModel(charId, mutationName, uid, scale)
	local character = Config.getCharacter(charId)
	if not character then
		return nil
	end
	scale = scale or 1
	local rarity = Config.getRarity(character.tier)
	local mutation = Config.getMutation(mutationName or "None")

	local model = Instance.new("Model")
	model.Name = character.name
	model:SetAttribute("Uid", uid or "")
	model:SetAttribute("CharId", charId)
	model:SetAttribute("Mutation", mutation.name)

	local s = scale
	-- Body: the animal. About 4 studs tall in total at scale 1.
	local body = newPart("Body", Vector3.new(2.6 * s, 2.0 * s, 2.2 * s), character.bodyColor, Enum.Material.SmoothPlastic, model)
	body.CFrame = CFrame.new(0, 1.6 * s, 0)
	model.PrimaryPart = body

	local head = newPart("Head", Vector3.new(1.8 * s, 1.4 * s, 1.7 * s), character.bodyColor, Enum.Material.SmoothPlastic, model)
	head.CFrame = CFrame.new(0, 3.2 * s, 0.2 * s)

	-- Eyes on the front of the head.
	for i = 1, 2 do
		local eye = newPart("Eye", Vector3.new(0.35 * s, 0.45 * s, 0.15 * s), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, model)
		eye.CFrame = CFrame.new(-0.45 * s + (i - 1) * 0.9 * s, 3.3 * s, 1.1 * s)
		local pupil = newPart("Pupil", Vector3.new(0.18 * s, 0.25 * s, 0.1 * s), Color3.fromRGB(15, 15, 15), Enum.Material.SmoothPlastic, model)
		pupil.CFrame = CFrame.new(-0.45 * s + (i - 1) * 0.9 * s, 3.3 * s, 1.18 * s)
	end

	-- Stubby legs.
	for i = 1, 2 do
		local leg = newPart("Leg", Vector3.new(0.6 * s, 0.7 * s, 0.6 * s), Color3.fromRGB(40, 30, 25), Enum.Material.SmoothPlastic, model)
		leg.CFrame = CFrame.new(-0.7 * s + (i - 1) * 1.4 * s, 0.35 * s, 0.4 * s)
	end

	-- The fused object sits on / behind the animal.
	buildObject(character.object, character.accentColor, model, 3.9 * s, 2.2 * s)

	-- Rarity aura: a glowing neon disc under the character, plus a light.
	local aura = newPart("Aura", Vector3.new(0.15 * s, 3.4 * s, 3.4 * s), rarity.color, Enum.Material.Neon, model)
	aura.Shape = Enum.PartType.Cylinder
	aura.Transparency = 0.45
	aura.CFrame = CFrame.new(0, 0.1 * s, 0) * CFrame.Angles(0, 0, math.pi / 2)
	local light = Instance.new("PointLight")
	light.Color = rarity.color
	light.Range = 7 * s
	light.Brightness = 1
	light.Parent = aura

	-- Mutation tint: a small floating gem above the head when mutated.
	if mutation.name ~= "None" then
		local gem = newPart("MutationGem", Vector3.new(0.7 * s, 0.7 * s, 0.7 * s), mutation.color, Enum.Material.Neon, model)
		gem.Shape = Enum.PartType.Ball
		gem.CFrame = CFrame.new(1.4 * s, 4.6 * s, 0)
	end

	-- Floating label: name, rarity, money per second. Readable at a glance.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(220, 84)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5.6 * s, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = character.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.45, 0)
	rarityLabel.BackgroundTransparency = 1
	local rarityText = rarity.name
	if mutation.name ~= "None" then
		rarityText = mutation.name .. " " .. rarity.name
	end
	rarityLabel.Text = rarityText
	rarityLabel.TextColor3 = rarity.color
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.Parent = billboard

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, 0, 0.25, 0)
	incomeLabel.Position = UDim2.new(0, 0, 0.75, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = Config.formatMoney(Config.characterIncomePerSecond(character, mutation.name)) .. "/s"
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
	incomeLabel.TextStrokeTransparency = 0
	incomeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.SourceSansBold
	incomeLabel.Parent = billboard

	return model
end

return ModelBuilder
