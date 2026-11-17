-- Brainrot Catch — BaseService.
-- Owns the eight individual bases: one per player, each with its own accent
-- colour. It assigns a base on join, tracks which slot pads are free, shows
-- slotted characters on their pads, and auto-slots a carried character the
-- moment its owner walks home. It also sells the next slot (validated
-- against the player's cash by DataManager) and answers "is this player home"
-- for the wave.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CatchService = require(script.Parent.CatchService)
local Config = require(script.Parent.Parent.Shared.Config)
local DataManager = require(script.Parent.DataManager)
local ModelBuilder = require(script.Parent.ModelBuilder)
local Remotes = require(script.Parent.Remotes)

local BaseService = {}

-- assigned[player] = baseDef (one of Config.BASES)
local assigned = {}
-- displays[player] = { [uid] = model }
local displays = {}
local basesFolder = nil

local function padPosition(baseDef, slotIndex)
	-- 5 columns x 4 rows inside the 36x36 platform, skipping the gate lane.
	local col = (slotIndex - 1) % 5
	local row = math.floor((slotIndex - 1) / 5)
	return Vector3.new(
		baseDef.position.X - 12 + col * 6,
		1.2,
		baseDef.position.Z - 9 + row * 6
	)
end

function BaseService.getAssignedBase(player)
	return assigned[player]
end

function BaseService.isPlayerInBase(player)
	local baseDef = assigned[player]
	if not baseDef then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local dx = root.Position.X - baseDef.position.X
	local dz = root.Position.Z - baseDef.position.Z
	return (dx * dx + dz * dz) <= Config.BASE_SAFE_RADIUS * Config.BASE_SAFE_RADIUS
end

function BaseService.showCharacter(player, entry)
	local baseDef = assigned[player]
	if not baseDef then
		return
	end
	local model = ModelBuilder.buildCharacterModel(entry.charId, entry.mutation, entry.uid, 0.8)
	if not model then
		return
	end
	model.Parent = basesFolder
	model:PivotTo(CFrame.new(padPosition(baseDef, entry.slotIndex)))
	displays[player] = displays[player] or {}
	displays[player][entry.uid] = model
end

function BaseService.hideCharacter(player, uid)
	if displays[player] and displays[player][uid] then
		displays[player][uid]:Destroy()
		displays[player][uid] = nil
	end
end

function BaseService.clearDisplays(player)
	if displays[player] then
		for _, model in pairs(displays[player]) do
			model:Destroy()
		end
		displays[player] = {}
	end
end

-- Rebuilds every slotted display from the profile (used on join, after a
-- load, and after a rebirth clears the base).
function BaseService.rebuildBase(player)
	BaseService.clearDisplays(player)
	local data = DataManager.getData(player)
	if not data then
		return
	end
	for _, entry in ipairs(data.Owned) do
		BaseService.showCharacter(player, entry)
	end
end

function BaseService.assignBase(player)
	for _, baseDef in ipairs(Config.BASES) do
		local taken = false
		for _, other in pairs(assigned) do
			if other == baseDef then
				taken = true
				break
			end
		end
		if not taken then
			assigned[player] = baseDef
			return baseDef
		end
	end
	-- More players than bases: share the first base (its pads are per-player).
	assigned[player] = Config.BASES[1]
	return Config.BASES[1]
end

function BaseService.unassignBase(player)
	assigned[player] = nil
	BaseService.clearDisplays(player)
end

function BaseService.start()
	basesFolder = Instance.new("Folder")
	basesFolder.Name = "BaseDisplays"
	basesFolder.Parent = Workspace

	local slotRemote = Remotes.get("SlotRequest")
	slotRemote.OnServerEvent:Connect(function(player)
		local resultRemote = Remotes.get("SlotResult")
		local data = DataManager.getData(player)
		if not data then
			return
		end
		if data.SlotsUnlocked >= Config.MAX_SLOTS then
			resultRemote:FireClient(player, { success = false, slotsUnlocked = data.SlotsUnlocked, reason = "max_slots" })
			return
		end
		local nextSlot = data.SlotsUnlocked + 1
		local cost = Config.slotUnlockCost(nextSlot)
		if DataManager.unlockSlot(player) then
			resultRemote:FireClient(player, { success = true, slotsUnlocked = nextSlot, reason = nil })
			local popup = Remotes.get("Popup")
			if popup then
				popup:FireClient(player, { title = "Slot unlocked!", text = "Slot " .. nextSlot .. " is yours for " .. Config.formatMoney(cost) .. "." })
			end
		else
			resultRemote:FireClient(player, { success = false, slotsUnlocked = data.SlotsUnlocked, reason = "not_enough_cash" })
		end
	end)

	-- Homecoming check: a carrying player who steps into their base slots the
	-- character automatically. If the base is full, they keep carrying.
	local lastFullWarning = {}
	task.spawn(function()
		while true do
			task.wait(0.2)
			for _, player in ipairs(Players:GetPlayers()) do
				if CatchService.isCarrying(player) and BaseService.isPlayerInBase(player) then
					local carriedEntry = CatchService.getCarried(player)
					local slotIndex = DataManager.grantCharacter(player, carriedEntry.charId, carriedEntry.mutation)
					if slotIndex then
						local owned = DataManager.getData(player).Owned
						local granted = nil
						for _, entry in ipairs(owned) do
							if entry.slotIndex == slotIndex then
								granted = entry
								break
							end
						end
						CatchService.dropCarried(player, false)
						if granted then
							BaseService.showCharacter(player, granted)
							local character = Config.getCharacter(granted.charId)
							local popup = Remotes.get("Popup")
							if popup then
								popup:FireClient(player, {
									title = "Homed!",
									text = character.name .. " is earning " .. Config.formatMoney(Config.characterIncomePerSecond(character, granted.mutation)) .. "/s in slot " .. slotIndex .. ".",
								})
							end
						end
					else
						local now = os.clock()
						if not lastFullWarning[player] or now - lastFullWarning[player] > 5 then
							lastFullWarning[player] = now
							local popup = Remotes.get("Popup")
							if popup then
								popup:FireClient(player, { title = "Base full!", text = "Buy another slot from the Shop to home this character." })
							end
						end
					end
				end
			end
		end
	end)
end

return BaseService
