-- Brainrot Catch — shared configuration.
-- One source of truth for the roster, economy, wave timing, mutations and map
-- layout. Required by both the server modules and the client scripts from
-- ReplicatedStorage, so the numbers the HUD shows are the numbers the server
-- enforces.

local Config = {}

Config.GAME_NAME = "Brainrot Catch"
Config.VERSION = "1.0.0"

-- Starting cash every new player gets.
Config.START_CASH = 50000

-- ---------------------------------------------------------------------------
-- Rarities. Tier order matters: it drives the catch channel, the carry speed
-- penalty and the spawn weights below.
-- ---------------------------------------------------------------------------
Config.RARITIES = {
	{ tier = 1, name = "Common", color = Color3.fromRGB(235, 235, 235), income = 1000, channelTime = 1, speedPenalty = 0.10, spawnWeight = 60 },
	{ tier = 2, name = "Rare", color = Color3.fromRGB(70, 140, 255), income = 3000, channelTime = 2, speedPenalty = 0.20, spawnWeight = 20 },
	{ tier = 3, name = "Epic", color = Color3.fromRGB(170, 80, 255), income = 8000, channelTime = 3, speedPenalty = 0.30, spawnWeight = 10 },
	{ tier = 4, name = "Legendary", color = Color3.fromRGB(255, 165, 0), income = 20000, channelTime = 5, speedPenalty = 0.40, spawnWeight = 6 },
	{ tier = 5, name = "Mythic", color = Color3.fromRGB(255, 70, 120), income = 50000, channelTime = 8, speedPenalty = 0.50, spawnWeight = 3 },
	{ tier = 6, name = "Brainrot God", color = Color3.fromRGB(255, 230, 0), income = 150000, channelTime = 12, speedPenalty = 0.60, spawnWeight = 0.9 },
	{ tier = 7, name = "Secret", color = Color3.fromRGB(20, 20, 20), income = 500000, channelTime = 20, speedPenalty = 0.70, spawnWeight = 0.1 },
}

function Config.getRarity(tier)
	for _, rarity in ipairs(Config.RARITIES) do
		if rarity.tier == tier then
			return rarity
		end
	end
	return Config.RARITIES[1]
end

-- Weighted rarity roll. Returns a tier number from 1 to 7.
function Config.rollRarity()
	local total = 0
	for _, rarity in ipairs(Config.RARITIES) do
		total += rarity.spawnWeight
	end
	local roll = math.random() * total
	local running = 0
	for _, rarity in ipairs(Config.RARITIES) do
		running += rarity.spawnWeight
		if roll <= running then
			return rarity.tier
		end
	end
	return 1
end

-- ---------------------------------------------------------------------------
-- Characters. Twelve original animal-plus-object hybrids. bodyColor is the
-- animal, accentColor is the object fused to it, objectKind tells the
-- ModelBuilder which object part to build on top of the animal body.
-- ---------------------------------------------------------------------------
Config.CHARACTERS = {
	{ id = "capybucket", name = "Wobble Capybucket", hybrid = "Capybara + Bucket", tier = 1,
		bodyColor = Color3.fromRGB(150, 105, 60), accentColor = Color3.fromRGB(120, 120, 125), object = "bucket",
		blurb = "A round capybara with a rusty bucket body. Water dribbles everywhere it wobbles." },
	{ id = "honkhose", name = "Honk Hose", hybrid = "Goose + Garden Hose", tier = 1,
		bodyColor = Color3.fromRGB(240, 240, 240), accentColor = Color3.fromRGB(40, 160, 70), object = "hose",
		blurb = "A goose whose neck is a kinked green garden hose. It honks water droplets." },
	{ id = "tupperdog", name = "Chonk Tupperdog", hybrid = "Dog + Tupperware", tier = 1,
		bodyColor = Color3.fromRGB(215, 165, 90), accentColor = Color3.fromRGB(70, 160, 230), object = "tupperware",
		blurb = "A chonky dog fused with a plastic food container. Still smells faintly of leftovers." },
	{ id = "fridgeferret", name = "Fridge Ferret", hybrid = "Ferret + Mini Fridge", tier = 2,
		bodyColor = Color3.fromRGB(120, 80, 50), accentColor = Color3.fromRGB(200, 215, 225), object = "fridge",
		blurb = "A long ferret wrapped around a mini fridge. Its door puffs cold air when it sleeps." },
	{ id = "bathtoad", name = "Boom Bathtoad", hybrid = "Toad + Bathtub", tier = 2,
		bodyColor = Color3.fromRGB(90, 170, 90), accentColor = Color3.fromRGB(235, 235, 240), object = "bathtub",
		blurb = "A toad sitting in a clawfoot bathtub that hops. Suds explode behind every hop." },
	{ id = "dingdingo", name = "Ding Dingo", hybrid = "Dingo + Microwave", tier = 3,
		bodyColor = Color3.fromRGB(190, 130, 60), accentColor = Color3.fromRGB(60, 60, 70), object = "microwave",
		blurb = "A dingo with a microwave torso that twitches and dings when it gets excited." },
	{ id = "toastertortoise", name = "Toaster Tortoise", hybrid = "Tortoise + Toaster", tier = 3,
		bodyColor = Color3.fromRGB(110, 150, 80), accentColor = Color3.fromRGB(205, 205, 210), object = "toaster",
		blurb = "A tortoise with a chrome toaster shell. Toast pops out when it retreats." },
	{ id = "fridgerex", name = "Fridge Rex", hybrid = "T-Rex + Refrigerator", tier = 4,
		bodyColor = Color3.fromRGB(210, 220, 228), accentColor = Color3.fromRGB(90, 140, 180), object = "fridge",
		blurb = "A T-Rex made of a stainless fridge. Frost breath, door jaw, zero chill." },
	{ id = "lamprey", name = "Lamprey Lamp", hybrid = "Lamprey + Desk Lamp", tier = 4,
		bodyColor = Color3.fromRGB(80, 60, 110), accentColor = Color3.fromRGB(255, 220, 90), object = "lamp",
		blurb = "A glowing lamprey dangling from a desk lamp neck. Its toothy mouth flickers like a bulb." },
	{ id = "slothspinner", name = "Spinach Sloth-Spinner", hybrid = "Sloth + Ceiling Fan", tier = 5,
		bodyColor = Color3.fromRGB(120, 150, 90), accentColor = Color3.fromRGB(180, 200, 200), object = "fan",
		blurb = "A sloth fused to a ceiling fan. It spins very, very slowly. Spinach not included." },
	{ id = "skunkwoofer", name = "Skibidi Skunk-Subwoofer", hybrid = "Skunk + Subwoofer", tier = 6,
		bodyColor = Color3.fromRGB(25, 25, 25), accentColor = Color3.fromRGB(255, 40, 90), object = "subwoofer",
		blurb = "A black-and-rainbow skunk fused to a bass subwoofer. It thumps. The whole map feels it." },
	{ id = "moosemonolith", name = "Mogging Moose-Monolith", hybrid = "Moose + Black Monolith", tier = 7,
		bodyColor = Color3.fromRGB(170, 175, 185), accentColor = Color3.fromRGB(10, 10, 12), object = "monolith",
		blurb = "A silver moose whose antlers form a black monolith. It emits glyphs. It mogs." },
}

function Config.getCharacter(charId)
	for _, character in ipairs(Config.CHARACTERS) do
		if character.id == charId then
			return character
		end
	end
	return nil
end

function Config.getCharactersOfTier(tier)
	local out = {}
	for _, character in ipairs(Config.CHARACTERS) do
		if character.tier == tier then
			table.insert(out, character)
		end
	end
	return out
end

-- ---------------------------------------------------------------------------
-- Mutations. Rolled on catch; they multiply the character's income.
-- ---------------------------------------------------------------------------
Config.MUTATIONS = {
	{ name = "None", multiplier = 1, color = Color3.fromRGB(255, 255, 255), rollChance = 0 },
	{ name = "Gold", multiplier = 2, color = Color3.fromRGB(255, 210, 40), rollChance = 0.08 },
	{ name = "Diamond", multiplier = 4, color = Color3.fromRGB(120, 220, 255), rollChance = 0.04 },
	{ name = "Rainbow", multiplier = 8, color = Color3.fromRGB(255, 100, 220), rollChance = 0.015 },
	{ name = "Lava", multiplier = 3, color = Color3.fromRGB(255, 90, 20), rollChance = 0.05 },
}

function Config.rollMutation()
	local roll = math.random()
	local running = 0
	for i = 2, #Config.MUTATIONS do
		running += Config.MUTATIONS[i].rollChance
		if roll <= running then
			return Config.MUTATIONS[i].name
		end
	end
	return "None"
end

function Config.getMutation(name)
	for _, mutation in ipairs(Config.MUTATIONS) do
		if mutation.name == name then
			return mutation
		end
	end
	return Config.MUTATIONS[1]
end

-- Income of one slotted character per second, before rebirth/event boosts.
function Config.characterIncomePerSecond(character, mutationName)
	local rarity = Config.getRarity(character.tier)
	local mutation = Config.getMutation(mutationName or "None")
	return rarity.income * mutation.multiplier
end

-- ---------------------------------------------------------------------------
-- Base slots and rebirths.
-- ---------------------------------------------------------------------------
Config.START_SLOTS = 2
Config.MAX_SLOTS = 20
Config.SLOT_BASE_COST = 250000
Config.SLOT_COST_PER_LEVEL = 50000

-- Cost to unlock slot number n (n starts at 3, since 2 are free).
function Config.slotUnlockCost(slotNumber)
	return Config.SLOT_BASE_COST + (slotNumber * slotNumber) * Config.SLOT_COST_PER_LEVEL
end

Config.REBIRTH_COST = 5000000
Config.MAX_REBIRTHS = 5
Config.REBIRTH_MULTIPLIERS = { 1.5, 2.0, 2.5, 3.0, 3.5 }

function Config.rebirthMultiplier(rebirthCount)
	if rebirthCount <= 0 then
		return 1
	end
	if rebirthCount > #Config.REBIRTH_MULTIPLIERS then
		return Config.REBIRTH_MULTIPLIERS[#Config.REBIRTH_MULTIPLIERS]
	end
	return Config.REBIRTH_MULTIPLIERS[rebirthCount]
end

-- ---------------------------------------------------------------------------
-- Catch rules.
-- ---------------------------------------------------------------------------
-- The server rejects any catch whose player is further than this from the
-- target, in studs, and logs the rejection.
Config.CATCH_MAX_DISTANCE = 15
-- If the player walks this far from the target mid-channel, the channel breaks.
Config.CATCH_BREAK_DISTANCE = 20

-- ---------------------------------------------------------------------------
-- Wave / storm.
-- ---------------------------------------------------------------------------
Config.WAVE_INTERVAL = 180 -- seconds between wave starts
Config.WAVE_WARNING = 30 -- seconds of warning before the sweep
Config.WAVE_SWEEP_TIME = 20 -- seconds the wall takes to cross the map

-- ---------------------------------------------------------------------------
-- Events.
-- ---------------------------------------------------------------------------
Config.DOUBLE_MONEY_EVERY = 420 -- seconds between 2x income windows
Config.DOUBLE_MONEY_DURATION = 60
Config.GOLDEN_HOUR_EVERY = 1200 -- seconds between golden hours
Config.GOLDEN_HOUR_DURATION = 90
-- During golden hour, Rare-and-up spawn weights are multiplied by this.
Config.GOLDEN_HOUR_RARE_BOOST = 3

-- ---------------------------------------------------------------------------
-- Map layout. The wild field is a 400x400 square centred on the origin.
-- The sea sits on the -X side; the wave sweeps from -X towards +X.
-- ---------------------------------------------------------------------------
Config.MAP_HALF = 200
Config.WILD_RADIUS = 150
Config.PLAZA_CENTER = Vector3.new(0, 0, 0)
Config.MOUNTAIN_POSITION = Vector3.new(-150, 0, -140)
Config.BRIDGE_CENTER = Vector3.new(0, 0, 60)
Config.SEA_EDGE_X = -200
Config.SPAWN_POSITION = Vector3.new(0, 5, 0)

-- Eight individual bases around the map edge, one per player.
Config.BASES = {
	{ name = "Base 1", color = Color3.fromRGB(255, 70, 70), position = Vector3.new(-160, 0, 160) },
	{ name = "Base 2", color = Color3.fromRGB(70, 140, 255), position = Vector3.new(0, 0, 175) },
	{ name = "Base 3", color = Color3.fromRGB(70, 220, 110), position = Vector3.new(160, 0, 160) },
	{ name = "Base 4", color = Color3.fromRGB(255, 200, 40), position = Vector3.new(175, 0, 0) },
	{ name = "Base 5", color = Color3.fromRGB(190, 90, 255), position = Vector3.new(160, 0, -160) },
	{ name = "Base 6", color = Color3.fromRGB(255, 130, 40), position = Vector3.new(0, 0, -175) },
	{ name = "Base 7", color = Color3.fromRGB(40, 220, 220), position = Vector3.new(-160, 0, -160) },
	{ name = "Base 8", color = Color3.fromRGB(255, 90, 180), position = Vector3.new(-175, 0, 0) },
}
Config.BASE_SIZE = Vector3.new(36, 1, 36)
-- A player standing inside this radius of their base centre counts as home.
Config.BASE_SAFE_RADIUS = 24

-- Rarity aura colours for the glowing ring under each character.
Config.AURA_COLORS = {
	[1] = Color3.fromRGB(255, 255, 255),
	[2] = Color3.fromRGB(70, 140, 255),
	[3] = Color3.fromRGB(170, 80, 255),
	[4] = Color3.fromRGB(255, 165, 0),
	[5] = Color3.fromRGB(255, 70, 120),
	[6] = Color3.fromRGB(255, 230, 0),
	[7] = Color3.fromRGB(255, 210, 40),
}

-- "1,234,567" style money formatting for the HUD.
function Config.formatMoney(amount)
	local n = math.floor(amount + 0.5)
	local text = tostring(n)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

return Config
