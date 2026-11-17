-- Brainrot Catch — DataManager.
-- The ONE place player data is mutated. Every other server module reads a
-- profile through GetData and changes it only through the mutators here, so
-- two scripts can never race on the same player's cash, slots or characters.
--
-- Saves use plain DataStoreService with a manual session lock (no third-party
-- libraries): one data key per UserId plus one lock key per UserId. Income is
-- buffered in memory and saved in batches (autosave every few minutes plus on
-- PlayerRemoving); a failed save goes on a retry queue and is never wiped.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Parent.Shared.Config)

local DataManager = {}

local DATA_STORE_NAME = "BrainrotCatchData_v1"
local LOCK_STORE_NAME = "BrainrotCatchLocks_v1"
local AUTOSAVE_INTERVAL = 180
local LOCK_STALE_SECONDS = 120
local MAX_SAVE_RETRIES = 5

local dataStore = nil
local lockStore = nil
local dataStoresAvailable = false

do
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	if ok and store then
		dataStore = store
		dataStoresAvailable = true
	end
	local okLock, lock = pcall(function()
		return DataStoreService:GetDataStore(LOCK_STORE_NAME)
	end)
	if okLock and lock then
		lockStore = lock
	end
	if not dataStoresAvailable then
		warn("[BrainrotCatch] DataStore unavailable (Studio without API access?) — session-only data.")
	end
end

-- profile[player] = { data = {...}, dirty = bool, lastSave = number, lockOwner = string, sessionOnly = bool }
local profiles = {}
-- retryQueue: { userId = number, data = table, tries = number, nextTryAt = number }
local retryQueue = {}

local function defaultData()
	return {
		Cash = Config.START_CASH,
		Rebirths = 0,
		SlotsUnlocked = Config.START_SLOTS,
		Owned = {},
		Index = {},
		IndexCompleteRewarded = false,
		TotalEarned = 0,
		TotalCatches = 0,
	}
end

local function copyData(data)
	local copy = {
		Cash = data.Cash,
		Rebirths = data.Rebirths,
		SlotsUnlocked = data.SlotsUnlocked,
		Owned = {},
		Index = {},
		IndexCompleteRewarded = data.IndexCompleteRewarded,
		TotalEarned = data.TotalEarned,
		TotalCatches = data.TotalCatches,
	}
	for _, entry in ipairs(data.Owned) do
		table.insert(copy.Owned, {
			uid = entry.uid,
			charId = entry.charId,
			mutation = entry.mutation,
			slotIndex = entry.slotIndex,
		})
	end
	for charId, value in pairs(data.Index) do
		copy.Index[charId] = value
	end
	return copy
end

function DataManager.getProfile(player)
	return profiles[player]
end

-- Read-only view of a player's data (the table itself; mutate only through
-- the functions below).
function DataManager.getData(player)
	local profile = profiles[player]
	if profile then
		return profile.data
	end
	return nil
end

function DataManager.isSessionOnly(player)
	local profile = profiles[player]
	return profile and profile.sessionOnly or false
end

-- ---------------------------------------------------------------------------
-- Session lock. A lock key holds { server = jobId, at = unixTime }. A server
-- may take a lock that is missing, stale, or already its own. If another live
-- server holds it, this server plays session-only and never overwrites.
-- ---------------------------------------------------------------------------
local function tryAcquireLock(userId)
	if not lockStore then
		return false
	end
	local myServer = tostring(game.JobId)
	for _ = 1, 3 do
		local ok, taken = pcall(function()
			return lockStore:UpdateAsync("lock_" .. userId, function(old)
				if old == nil then
					return { server = myServer, at = os.time() }
				end
				if old.server == myServer then
					return { server = myServer, at = os.time() }
				end
				if os.time() - (old.at or 0) > LOCK_STALE_SECONDS then
					return { server = myServer, at = os.time() }
				end
				return old
			end)
		end)
		if ok and taken and taken.server == myServer then
			return true
		end
		task.wait(1)
	end
	return false
end

local function releaseLock(userId)
	if not lockStore then
		return
	end
	pcall(function()
		lockStore:UpdateAsync("lock_" .. userId, function(old)
			if old and old.server == tostring(game.JobId) then
				return nil
			end
			return old
		end)
	end)
end

-- ---------------------------------------------------------------------------
-- Loading.
-- ---------------------------------------------------------------------------
function DataManager.loadProfile(player)
	local userId = player.UserId
	local data = defaultData()
	local sessionOnly = false

	if dataStoresAvailable and dataStore then
		local ok, saved = pcall(function()
			return dataStore:GetAsync("player_" .. userId)
		end)
		if ok and type(saved) == "table" then
			-- Merge over the template so old saves missing new fields stay valid.
			for key, value in pairs(defaultData()) do
				if saved[key] == nil then
					saved[key] = value
				end
			end
			data = saved
		elseif not ok then
			warn("[BrainrotCatch] Load failed for " .. player.Name .. "; starting fresh in-session.")
		end

		if not tryAcquireLock(userId) then
			sessionOnly = true
			warn("[BrainrotCatch] " .. player.Name .. " is locked by another server; session-only data.")
		end
	else
		sessionOnly = true
	end

	profiles[player] = {
		data = data,
		dirty = false,
		lastSave = os.time(),
		sessionOnly = sessionOnly,
	}
	return profiles[player]
end

-- ---------------------------------------------------------------------------
-- Saving. saveNow writes once; queueSave retries on failure. Nothing here
-- ever wipes session data on a failed save.
-- ---------------------------------------------------------------------------
local function writeData(userId, data)
	if not dataStoresAvailable or not dataStore then
		return false
	end
	local ok = pcall(function()
		dataStore:SetAsync("player_" .. userId, copyData(data))
	end)
	return ok
end

function DataManager.saveProfile(player, isLeaving)
	local profile = profiles[player]
	if not profile or profile.sessionOnly then
		return false
	end
	local ok = writeData(player.UserId, profile.data)
	if ok then
		profile.dirty = false
		profile.lastSave = os.time()
	else
		retryQueue[player.UserId] = {
			userId = player.UserId,
			data = copyData(profile.data),
			tries = 1,
			nextTryAt = os.time() + 5,
		}
		warn("[BrainrotCatch] Save failed for " .. player.Name .. "; queued retry 1/" .. MAX_SAVE_RETRIES .. ".")
	end
	if isLeaving then
		releaseLock(player.UserId)
	end
	return ok
end

function DataManager.removeProfile(player)
	profiles[player] = nil
end

-- Retry loop: runs forever on the server, draining the queue with backoff.
function DataManager.startRetryLoop()
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.time()
			for userId, entry in pairs(retryQueue) do
				if now >= entry.nextTryAt then
					local ok = writeData(userId, entry.data)
					if ok then
						retryQueue[userId] = nil
					else
						entry.tries += 1
						if entry.tries > MAX_SAVE_RETRIES then
							retryQueue[userId] = nil
							warn("[BrainrotCatch] Save permanently failed for userId " .. userId .. " after " .. MAX_SAVE_RETRIES .. " tries; data kept in memory only.")
						else
							entry.nextTryAt = now + (5 * entry.tries)
						end
					end
				end
			end
		end
	end)
end

-- Autosave loop: every few minutes, save every dirty profile.
function DataManager.startAutosaveLoop()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player, profile in pairs(profiles) do
				if profile.dirty and not profile.sessionOnly then
					DataManager.saveProfile(player, false)
				end
			end
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Mutators. The only sanctioned ways to change a profile.
-- ---------------------------------------------------------------------------
function DataManager.addCash(player, amount)
	local profile = profiles[player]
	if not profile or amount == 0 then
		return 0
	end
	profile.data.Cash += amount
	if amount > 0 then
		profile.data.TotalEarned += amount
	end
	profile.dirty = true
	return profile.data.Cash
end

-- Returns true when the player could afford it (cash deducted), false otherwise.
function DataManager.spendCash(player, amount)
	local profile = profiles[player]
	if not profile or amount <= 0 then
		return false
	end
	if profile.data.Cash < amount then
		return false
	end
	profile.data.Cash -= amount
	profile.dirty = true
	return true
end

-- Grants a character into the lowest free slot. Returns the slot index, or
-- nil when every unlocked slot is full.
function DataManager.grantCharacter(player, charId, mutation)
	local profile = profiles[player]
	if not profile then
		return nil
	end
	local taken = {}
	for _, entry in ipairs(profile.data.Owned) do
		taken[entry.slotIndex] = true
	end
	local freeSlot = nil
	for slot = 1, profile.data.SlotsUnlocked do
		if not taken[slot] then
			freeSlot = slot
			break
		end
	end
	if not freeSlot then
		return nil
	end
	table.insert(profile.data.Owned, {
		uid = tostring(player.UserId) .. "_" .. tostring(os.time()) .. "_" .. tostring(#profile.data.Owned + 1),
		charId = charId,
		mutation = mutation or "None",
		slotIndex = freeSlot,
	})
	profile.data.TotalCatches += 1
	profile.dirty = true
	return freeSlot
end

-- Removes one owned character by uid. Returns the removed entry or nil.
function DataManager.removeCharacter(player, uid)
	local profile = profiles[player]
	if not profile then
		return nil
	end
	for i, entry in ipairs(profile.data.Owned) do
		if entry.uid == uid then
			table.remove(profile.data.Owned, i)
			profile.dirty = true
			return entry
		end
	end
	return nil
end

function DataManager.findOwned(player, uid)
	local profile = profiles[player]
	if not profile then
		return nil
	end
	for _, entry in ipairs(profile.data.Owned) do
		if entry.uid == uid then
			return entry
		end
	end
	return nil
end

-- Buys the next slot. Returns true on success.
function DataManager.unlockSlot(player)
	local profile = profiles[player]
	if not profile then
		return false
	end
	if profile.data.SlotsUnlocked >= Config.MAX_SLOTS then
		return false
	end
	local nextSlot = profile.data.SlotsUnlocked + 1
	local cost = Config.slotUnlockCost(nextSlot)
	if not DataManager.spendCash(player, cost) then
		return false
	end
	profile.data.SlotsUnlocked = nextSlot
	profile.dirty = true
	return true
end

-- Rebirth: resets cash and owned characters, grants the next multiplier.
-- Returns the new rebirth count, or 0 when validation fails.
function DataManager.applyRebirth(player)
	local profile = profiles[player]
	if not profile then
		return 0
	end
	if profile.data.Rebirths >= Config.MAX_REBIRTHS then
		return 0
	end
	if profile.data.Cash < Config.REBIRTH_COST then
		return 0
	end
	profile.data.Cash = Config.START_CASH
	profile.data.Owned = {}
	profile.data.SlotsUnlocked = Config.START_SLOTS
	profile.data.Rebirths += 1
	profile.dirty = true
	return profile.data.Rebirths
end

-- Marks a character discovered in the index book. Returns true on first discovery.
function DataManager.markDiscovered(player, charId)
	local profile = profiles[player]
	if not profile then
		return false
	end
	if profile.data.Index[charId] then
		return false
	end
	profile.data.Index[charId] = true
	profile.dirty = true
	return true
end

function DataManager.isIndexComplete(player)
	local profile = profiles[player]
	if not profile then
		return false
	end
	local count = 0
	for _ in pairs(profile.data.Index) do
		count += 1
	end
	return count >= #Config.CHARACTERS
end

function DataManager.setIndexCompleteRewarded(player, value)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.data.IndexCompleteRewarded = value
	profile.dirty = true
end

return DataManager
