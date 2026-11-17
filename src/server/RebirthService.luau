-- Brainrot Catch — RebirthService.
-- Handles rebirth requests. All validation lives on the server through
-- DataManager.applyRebirth: the player must hold $5,000,000 and be under the
-- 5-rebirth cap. A rebirth resets cash to the starting amount and clears the
-- base, and grants the next permanent income multiplier.

local BaseService = require(script.Parent.BaseService)
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local DataManager = require(script.Parent.DataManager)
local Remotes = require(script.Parent.Remotes)

local RebirthService = {}

function RebirthService.start()
	local requestRemote = Remotes.get("RebirthRequest")
	requestRemote.OnServerEvent:Connect(function(player)
		local resultRemote = Remotes.get("RebirthResult")
		local popup = Remotes.get("Popup")
		local data = DataManager.getData(player)
		if not data then
			return
		end
		if data.Rebirths >= Config.MAX_REBIRTHS then
			resultRemote:FireClient(player, { success = false, rebirths = data.Rebirths, reason = "max_rebirths" })
			return
		end
		if data.Cash < Config.REBIRTH_COST then
			resultRemote:FireClient(player, { success = false, rebirths = data.Rebirths, reason = "not_enough_cash" })
			if popup then
				popup:FireClient(player, {
					title = "Not yet!",
					text = "Rebirth costs " .. Config.formatMoney(Config.REBIRTH_COST) .. ". You have " .. Config.formatMoney(data.Cash) .. ".",
				})
			end
			return
		end
		local newCount = DataManager.applyRebirth(player)
		if newCount > 0 then
			BaseService.clearDisplays(player)
			BaseService.rebuildBase(player)
			resultRemote:FireClient(player, { success = true, rebirths = newCount, reason = nil })
			if popup then
				popup:FireClient(player, {
					title = "REBIRTH!",
					text = "Rebirth " .. newCount .. "! All income is now x" .. tostring(Config.rebirthMultiplier(newCount)) .. " forever.",
				})
			end
		else
			resultRemote:FireClient(player, { success = false, rebirths = data.Rebirths, reason = "failed" })
		end
	end)
end

return RebirthService
