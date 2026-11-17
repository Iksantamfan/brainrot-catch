-- Brainrot Catch — DashService.
-- A short speed burst (Shift) with a stamina meter. Stamina lives on the
-- server: a dash costs 30, regenerates 10 per second, and the burst lasts
-- 0.6 seconds at WalkSpeed 26 (or the carrying speed when loaded). The
-- server sets the speed, so a client cannot grant itself a permanent boost.

local Players = game:GetService("Players")

local Config = require(script.Parent.Parent.Shared.Config)
local Remotes = require(script.Parent.Remotes)

local DashService = {}

local DASH_COST = 30
local DASH_REGEN_PER_SECOND = 10
local DASH_DURATION = 0.6
local DASH_SPEED = 26

-- stamina[player] = 0..100
local stamina = {}
-- dashing[player] = true while a burst is active
local dashing = {}

function DashService.start()
	local requestRemote = Remotes.get("DashRequest")
	local stateRemote = Remotes.get("DashState")

	requestRemote.OnServerEvent:Connect(function(player)
		local current = stamina[player] or 100
		if current < DASH_COST or dashing[player] then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		stamina[player] = current - DASH_COST
		dashing[player] = true
		local wasCarrying = false
		-- Remember the pre-dash speed so a carrier returns to their penalty.
		local restoreTo = humanoid.WalkSpeed
		humanoid.WalkSpeed = DASH_SPEED
		task.delay(DASH_DURATION, function()
			dashing[player] = nil
			local fresh = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if fresh and fresh.Health > 0 then
				-- Take the lower of the pre-dash speed and the current speed:
				-- if the player caught a character mid-dash, the carry
				-- penalty (already applied by CatchService) must survive.
				fresh.WalkSpeed = math.min(restoreTo, fresh.WalkSpeed)
			end
		end)
		if stateRemote then
			stateRemote:FireClient(player, { stamina = stamina[player] })
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		stamina[player] = nil
		dashing[player] = nil
	end)

	-- Stamina regen + periodic state sync.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local current = stamina[player] or 100
				if current < 100 then
					stamina[player] = math.min(100, current + DASH_REGEN_PER_SECOND)
				else
					stamina[player] = 100
				end
				if stateRemote then
					stateRemote:FireClient(player, { stamina = stamina[player] })
				end
			end
		end
	end)
end

return DashService
