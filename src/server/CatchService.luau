-- Brainrot Catch — CatchService.
-- Owns the whole catch flow. The client only asks; the server validates,
-- runs the channel and hands out the character. A catch is rejected (and the
-- rejection logged) when the player is further than 15 studs from the target
-- at request time, when the target is gone, or when the player already
-- carries a character. The channel breaks if the player walks away.

local Players = game:GetService("Players")

local Config = require(script.Parent.Parent.Shared.Config)
local DataManager = require(script.Parent.DataManager)
local IndexService = require(script.Parent.IndexService)
local ModelBuilder = require(script.Parent.ModelBuilder)
local Remotes = require(script.Parent.Remotes)
local Spawner = require(script.Parent.Spawner)

local CatchService = {}

-- carried[player] = { uid, charId, mutation, model, weld }
local carried = {}
-- channels[player] = { uid, charId, mutation, endsAt }
local channels = {}

local BASE_WALK_SPEED = 16

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function CatchService.isCarrying(player)
	return carried[player] ~= nil
end

function CatchService.getCarried(player)
	return carried[player]
end

local function sendResult(player, state, charId, mutation, reason)
	local remote = Remotes.get("CatchResult")
	if remote then
		remote:FireClient(player, {
			state = state,
			charId = charId,
			mutation = mutation,
			reason = reason,
		})
	end
end

local function sendPopup(player, title, text)
	local remote = Remotes.get("Popup")
	if remote then
		remote:FireClient(player, { title = title, text = text })
	end
end

-- Called when a catch channel finishes: the character leaves the wild and
-- is welded to the player's back. Carrying slows the player by the rarity's
-- speed penalty.
local function completeCatch(player, channel)
	local entry = Spawner.getWildCharacter(channel.uid)
	if not entry then
		sendResult(player, "cancelled", channel.charId, channel.mutation, "target_gone")
		return
	end
	local root = getRootPart(player)
	local humanoid = getHumanoid(player)
	if not root or not humanoid then
		sendResult(player, "cancelled", channel.charId, channel.mutation, "no_character")
		return
	end

	local character = Config.getCharacter(channel.charId)
	local rarity = Config.getRarity(character.tier)
	-- Keep the mutation the wild character was showing: the label promised
	-- it, so the caught character must be the same one.
	local mutation = channel.mutation

	Spawner.removeWild(channel.uid)
	local model = ModelBuilder.buildCharacterModel(channel.charId, mutation, channel.uid, 0.85)
	model.Parent = player.Character
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end
	model:PivotTo(root.CFrame * CFrame.new(0, 1.2, 1.6))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart

	humanoid.WalkSpeed = BASE_WALK_SPEED * (1 - rarity.speedPenalty)

	carried[player] = {
		uid = channel.uid,
		charId = channel.charId,
		mutation = mutation,
		model = model,
		weld = weld,
	}

	DataManager.markDiscovered(player, channel.charId)
	IndexService.checkCompletionReward(player)
	sendResult(player, "caught", channel.charId, mutation, nil)
	sendPopup(player, "Caught!", character.name .. " — dash home to your base before the wave!")
end

-- Detaches and destroys the carried model and restores walk speed. Used by
-- the base (slot), the wave (escape), death and leaving.
function CatchService.dropCarried(player, respawnWild)
	local entry = carried[player]
	if not entry then
		return nil
	end
	carried[player] = nil
	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid.WalkSpeed = BASE_WALK_SPEED
	end
	local root = getRootPart(player)
	local charId = entry.charId
	local mutation = entry.mutation
	if entry.model then
		entry.model:Destroy()
	end
	if respawnWild and root then
		Spawner.escapeToWild(charId, mutation, root.Position)
	end
	return entry
end

function CatchService.cancelChannel(player, reason)
	if channels[player] then
		local channel = channels[player]
		channels[player] = nil
		sendResult(player, "cancelled", channel.charId, channel.mutation, reason)
	end
end

function CatchService.start()
	local requestRemote = Remotes.get("CatchRequest")
	local dropRemote = Remotes.get("DropCarried")

	requestRemote.OnServerEvent:Connect(function(player, uid)
		if type(uid) ~= "string" then
			return
		end
		if carried[player] then
			sendResult(player, "rejected", nil, nil, "already_carrying")
			return
		end
		if channels[player] then
			sendResult(player, "rejected", nil, nil, "already_channelling")
			return
		end
		local entry = Spawner.getWildCharacter(uid)
		if not entry then
			sendResult(player, "rejected", nil, nil, "target_gone")
			return
		end
		local root = getRootPart(player)
		if not root then
			sendResult(player, "rejected", nil, nil, "no_character")
			return
		end
		local distance = (entry.model:GetPivot().Position - root.Position).Magnitude
		if distance > Config.CATCH_MAX_DISTANCE then
			warn("[BrainrotCatch] Catch rejected for " .. player.Name .. ": too far (" .. string.format("%.1f", distance) .. " studs, max " .. Config.CATCH_MAX_DISTANCE .. ").")
			sendResult(player, "rejected", nil, nil, "too_far")
			return
		end
		local character = Config.getCharacter(entry.charId)
		local rarity = Config.getRarity(character.tier)
		channels[player] = {
			uid = uid,
			charId = entry.charId,
			mutation = entry.mutation,
			endsAt = os.clock() + rarity.channelTime,
		}
		sendResult(player, "started", entry.charId, entry.mutation, nil)
	end)

	dropRemote.OnServerEvent:Connect(function(player)
		CatchService.cancelChannel(player, "dropped")
		local entry = CatchService.dropCarried(player, true)
		if entry then
			sendPopup(player, "Dropped", Config.getCharacter(entry.charId).name .. " ran back into the wild.")
		end
	end)

	-- Channel ticker: completes channels whose time is up, cancels ones whose
	-- player walked away or whose target vanished.
	task.spawn(function()
		while true do
			task.wait(0.1)
			for player, channel in pairs(channels) do
				local done = false
				local entry = Spawner.getWildCharacter(channel.uid)
				local root = getRootPart(player)
				if not entry or not root then
					CatchService.cancelChannel(player, "target_gone")
					done = true
				elseif (entry.model:GetPivot().Position - root.Position).Magnitude > Config.CATCH_BREAK_DISTANCE then
					CatchService.cancelChannel(player, "walked_away")
					done = true
				elseif os.clock() >= channel.endsAt then
					channels[player] = nil
					completeCatch(player, channel)
					done = true
				end
				if done then
					-- channel entry already cleared above where needed
				end
			end
		end
	end)

	-- Death drops the carried character back into the wild.
	local function watchDeaths(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Died:Connect(function()
				CatchService.cancelChannel(player, "died")
				CatchService.dropCarried(player, true)
			end)
		end)
	end
	Players.PlayerAdded:Connect(watchDeaths)
	for _, player in ipairs(Players:GetPlayers()) do
		watchDeaths(player)
	end
end

return CatchService
