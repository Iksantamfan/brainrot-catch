-- Brainrot Catch — EventService.
-- Timed server events, announced to every client:
--   * 2x income: every 7 minutes, income doubles for 60 seconds.
--   * Golden hour: every 20 minutes, Rare-and-up spawn weights triple for
--     90 seconds (the Spawner reads the flag through setGoldenHourActive).
-- The clock lives on the server; clients only display what they are told.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(script.Parent.Remotes)
local Spawner = require(script.Parent.Spawner)

local EventService = {}

local incomeMultiplier = 1
local doubleMoneyUntil = 0
local goldenHourUntil = 0
local nextDoubleMoneyAt = 0
local nextGoldenHourAt = 0

function EventService.getIncomeMultiplier()
	return incomeMultiplier
end

local function announce(kind, text, secondsLeft)
	local remote = Remotes.get("EventNotice")
	if remote then
		remote:FireAllClients({ kind = kind, text = text, secondsLeft = secondsLeft })
	end
end

function EventService.start()
	nextDoubleMoneyAt = os.clock() + Config.DOUBLE_MONEY_EVERY
	nextGoldenHourAt = os.clock() + Config.GOLDEN_HOUR_EVERY

	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()

			if incomeMultiplier == 1 and now >= nextDoubleMoneyAt then
				incomeMultiplier = 2
				doubleMoneyUntil = now + Config.DOUBLE_MONEY_DURATION
				announce("double", "DOUBLE MONEY! All income x2 for 60 seconds!", Config.DOUBLE_MONEY_DURATION)
			elseif incomeMultiplier == 2 and now >= doubleMoneyUntil then
				incomeMultiplier = 1
				nextDoubleMoneyAt = now + Config.DOUBLE_MONEY_EVERY
				announce("double_end", "Double money has ended.", 0)
			end

			if now >= nextGoldenHourAt and now < goldenHourUntil then
				-- golden hour already running; nothing to do
			elseif now >= nextGoldenHourAt then
				goldenHourUntil = now + Config.GOLDEN_HOUR_DURATION
				nextGoldenHourAt = now + Config.GOLDEN_HOUR_EVERY
				Spawner.setGoldenHourActive(true)
				announce("golden", "GOLDEN HOUR! Rare brainrots spawn 3x more often for 90 seconds!", Config.GOLDEN_HOUR_DURATION)
			end
			if goldenHourUntil > 0 and now >= goldenHourUntil and Spawner then
				Spawner.setGoldenHourActive(false)
				goldenHourUntil = 0
				announce("golden_end", "Golden hour has ended.", 0)
			end
		end
	end)
end

return EventService
