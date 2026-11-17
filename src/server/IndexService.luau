-- Brainrot Catch — IndexService.
-- The collection book: every character a player has ever caught is marked
-- discovered. Completing all twelve pays a one-time $1,000,000 bonus. The
-- client asks for its index data and gets the discovered set back.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local DataManager = require(script.Parent.DataManager)
local Remotes = require(script.Parent.Remotes)

local IndexService = {}

local COMPLETION_REWARD = 1000000

-- Called after a catch. Pays the completion bonus once, the first time the
-- book fills up.
function IndexService.checkCompletionReward(player)
	local data = DataManager.getData(player)
	if not data then
		return
	end
	if data.IndexCompleteRewarded then
		return
	end
	if not DataManager.isIndexComplete(player) then
		return
	end
	DataManager.addCash(player, COMPLETION_REWARD)
	DataManager.setIndexCompleteRewarded(player, true)
	local popup = Remotes.get("Popup")
	if popup then
		popup:FireClient(player, {
			title = "INDEX COMPLETE!",
			text = "You discovered all " .. #Config.CHARACTERS .. " brainrots! Bonus: " .. Config.formatMoney(COMPLETION_REWARD) .. ".",
		})
	end
end

function IndexService.start()
	local requestRemote = Remotes.get("IndexRequest")
	requestRemote.OnServerEvent:Connect(function(player)
		local data = DataManager.getData(player)
		local response = Remotes.get("IndexData")
		if data and response then
			response:FireClient(player, {
				discovered = data.Index,
				complete = DataManager.isIndexComplete(player),
			})
		end
	end)
end

return IndexService
