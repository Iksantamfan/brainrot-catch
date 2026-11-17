-- Brainrot Catch — IncomeService.
-- The server's money loop. Once a second it adds up every slotted
-- character's income (rarity x mutation x rebirth multiplier x event
-- multiplier) and credits it through DataManager — the client never sends
-- money, so there is no "AddMoney" event to spoof. The client is told its
-- new cash and per-second rate so the HUD can tick.

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local DataManager = require(script.Parent.DataManager)
local EventService = require(script.Parent.EventService)
local Remotes = require(script.Parent.Remotes)

local IncomeService = {}

function IncomeService.incomePerSecond(player)
	local data = DataManager.getData(player)
	if not data then
		return 0
	end
	local rebirthBoost = Config.rebirthMultiplier(data.Rebirths)
	local eventBoost = EventService.getIncomeMultiplier()
	local total = 0
	for _, entry in ipairs(data.Owned) do
		local character = Config.getCharacter(entry.charId)
		if character then
			total += Config.characterIncomePerSecond(character, entry.mutation)
		end
	end
	return math.floor(total * rebirthBoost * eventBoost + 0.5)
end

function IncomeService.start()
	task.spawn(function()
		while true do
			task.wait(1)
			local cashRemote = Remotes.get("CashChanged")
			for _, player in ipairs(Players:GetPlayers()) do
				local income = IncomeService.incomePerSecond(player)
				if income > 0 then
					DataManager.addCash(player, income)
				end
				local data = DataManager.getData(player)
				if data and cashRemote then
					cashRemote:FireClient(player, {
						cash = data.Cash,
						incomePerSecond = income,
					})
				end
			end
		end
	end)
end

return IncomeService
