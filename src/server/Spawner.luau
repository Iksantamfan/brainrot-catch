-- Brainrot Catch — Spawner.
-- Keeps the wild roaming population stocked: picks a rarity by the spawn
-- weights, picks a character of that rarity, rolls its mutation, builds its
-- model and wanders it around the wild field on the server. All hybrid
-- movement is server-side with NetworkOwnership on the server, so the server
-- stays the authority on where every character is.

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Parent.Shared.Config)
local ModelBuilder = require(script.Parent.ModelBuilder)

local Spawner = {}

local WILD_TARGET_COUNT = 14
local WANDER_SPEED = 4 -- studs per second
local WANDER_PAUSE_MIN = 1
local WANDER_PAUSE_MAX = 3

-- River band (z 45..75) and base pads are not wander targets.
local RIVER_MIN_Z = 45
local RIVER_MAX_Z = 75

local wildFolder = nil
local wildCharacters = {} -- uid -> { uid, charId, mutation, model, target, nextMoveAt, bobPhase }
local uidCounter = 0
local goldenHourActive = false

function Spawner.setGoldenHourActive(active)
	goldenHourActive = active
end

local function randomWildPoint()
	for _ = 1, 10 do
		local x = (math.random() * 2 - 1) * Config.WILD_RADIUS
		local z = (math.random() * 2 - 1) * Config.WILD_RADIUS
		if z < RIVER_MIN_Z or z > RIVER_MAX_Z then
			local clear = true
			for _, base in ipairs(Config.BASES) do
				local dx = x - base.position.X
				local dz = z - base.position.Z
				if dx * dx + dz * dz < 24 * 24 then
					clear = false
					break
				end
			end
			if clear then
				return Vector3.new(x, 0, z)
			end
		end
	end
	return Vector3.new(0, 0, -40)
end

local function rollTier()
	local total = 0
	for _, rarity in ipairs(Config.RARITIES) do
		local weight = rarity.spawnWeight
		if goldenHourActive and rarity.tier >= 2 then
			weight *= Config.GOLDEN_HOUR_RARE_BOOST
		end
		total += weight
	end
	local roll = math.random() * total
	local running = 0
	for _, rarity in ipairs(Config.RARITIES) do
		local weight = rarity.spawnWeight
		if goldenHourActive and rarity.tier >= 2 then
			weight *= Config.GOLDEN_HOUR_RARE_BOOST
		end
		running += weight
		if roll <= running then
			return rarity.tier
		end
	end
	return 1
end

function Spawner.spawnCharacter(charId, mutation, position)
	local character = Config.getCharacter(charId)
	if not character then
		return nil
	end
	uidCounter += 1
	local uid = "wild_" .. tostring(uidCounter)
	local model = ModelBuilder.buildCharacterModel(charId, mutation or "None", uid, 1)
	if not model then
		return nil
	end
	model.Parent = wildFolder
	model:PivotTo(CFrame.new(position))
	wildCharacters[uid] = {
		uid = uid,
		charId = charId,
		mutation = mutation or "None",
		model = model,
		target = position,
		nextMoveAt = os.clock() + math.random() * 2,
		bobPhase = math.random() * math.pi * 2,
	}
	return wildCharacters[uid]
end

function Spawner.spawnRandom()
	local tier = rollTier()
	local pool = Config.getCharactersOfTier(tier)
	if #pool == 0 then
		return nil
	end
	local character = pool[math.random(#pool)]
	local mutation = Config.rollMutation()
	return Spawner.spawnCharacter(character.id, mutation, randomWildPoint())
end

function Spawner.getWildCharacter(uid)
	return wildCharacters[uid]
end

-- Removes a wild character without a trace (caught, or swept). Destroys the
-- model and nils the reference so nothing leaks.
function Spawner.removeWild(uid)
	local entry = wildCharacters[uid]
	if not entry then
		return
	end
	wildCharacters[uid] = nil
	if entry.model then
		entry.model:Destroy()
	end
end

-- The wave lets a carried character escape: it pops back into the wild near
-- the player instead of vanishing.
function Spawner.escapeToWild(charId, mutation, nearPosition)
	local point = nearPosition + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
	point = Vector3.new(
		math.clamp(point.X, -Config.WILD_RADIUS, Config.WILD_RADIUS),
		0,
		math.clamp(point.Z, -Config.WILD_RADIUS, Config.WILD_RADIUS)
	)
	return Spawner.spawnCharacter(charId, mutation, point)
end

function Spawner.getNearestWild(position, maxDistance)
	local best = nil
	local bestDist = maxDistance
	for _, entry in pairs(wildCharacters) do
		local modelPos = entry.model:GetPivot().Position
		local dist = (modelPos - position).Magnitude
		if dist < bestDist then
			bestDist = dist
			best = entry
		end
	end
	return best, bestDist
end

function Spawner.countWild()
	local count = 0
	for _ in pairs(wildCharacters) do
		count += 1
	end
	return count
end

function Spawner.start()
	wildFolder = Instance.new("Folder")
	wildFolder.Name = "WildCharacters"
	wildFolder.Parent = Workspace

	-- Seed the field so the first player sees a full map.
	for _ = 1, WILD_TARGET_COUNT do
		Spawner.spawnRandom()
	end

	-- Top-up loop: keep the population at target.
	task.spawn(function()
		while true do
			task.wait(2)
			if Spawner.countWild() < WILD_TARGET_COUNT then
				Spawner.spawnRandom()
			end
		end
	end)

	-- Wander loop: each character strolls to a nearby point, pauses, repeats.
	-- A gentle bob makes the field feel alive without any animation assets.
	task.spawn(function()
		while true do
			task.wait(0.1)
			local now = os.clock()
			for _, entry in pairs(wildCharacters) do
				local model = entry.model
				if model and model.Parent then
					local pivot = model:GetPivot()
					local current = pivot.Position
					local toTarget = entry.target - current
					toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
					local distance = toTarget.Magnitude
					if distance > 1 then
						local step = math.min(WANDER_SPEED * 0.1, distance)
						local direction = toTarget / distance
						local nextPos = current + direction * step
						local yaw = math.atan2(-direction.X, -direction.Z)
						local bob = math.sin(now * 3 + entry.bobPhase) * 0.25
						model:PivotTo(CFrame.new(nextPos.X, bob, nextPos.Z) * CFrame.Angles(0, yaw, 0))
					elseif now >= entry.nextMoveAt then
						entry.target = randomWildPoint()
						entry.nextMoveAt = now + math.random(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
					end
				end
			end
		end
	end)
end

return Spawner
