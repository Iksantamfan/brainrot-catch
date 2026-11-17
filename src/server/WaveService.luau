-- Brainrot Catch — WaveService.
-- Owns the wave clock. The server is the only authority on wave timing: the
-- cycle is driven by workspace.DistributedGameTime on a server heartbeat,
-- never by client time. Every 180 seconds the wave warns for 30 seconds
-- (siren ping, sky darkening, countdown banner) and then a wall of water
-- sweeps the map from the sea side (-X) to the far side (+X). A player caught
-- carrying a character outside their base loses the character to the wild.
-- Players inside their own base are safe.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local BaseService = require(script.Parent.BaseService)
local CatchService = require(script.Parent.CatchService)
local Config = require(script.Parent.Parent.Shared.Config)
local Remotes = require(script.Parent.Remotes)

local WaveService = {}

local WARNING_SOUND = "rbxasset://sounds/electronicpingshort.wav"

local phase = "calm" -- "calm" | "warning" | "sweep"
local cycleStart = 0
local nextWaveAt = 0
local wall = nil
local wallX = 0
local normalBrightness = 2
local normalFogEnd = 100000

function WaveService.getState()
	local now = Workspace.DistributedGameTime
	local secondsLeft = nextWaveAt - now
	if phase == "sweep" then
		secondsLeft = 0
	end
	return { phase = phase, secondsLeft = math.max(0, math.floor(secondsLeft + 0.5)) }
end

local function broadcast()
	local remote = Remotes.get("WaveState")
	if remote then
		remote:FireAllClients(WaveService.getState())
	end
end

local function setStormSky(on)
	if on then
		normalBrightness = Lighting.Brightness
		Lighting.Brightness = 0.7
		Lighting.FogColor = Color3.fromRGB(40, 60, 90)
		Lighting.FogEnd = 260
		Lighting.ColorShift_Top = Color3.fromRGB(30, 40, 70)
	else
		Lighting.Brightness = normalBrightness
		Lighting.FogColor = Color3.fromRGB(190, 210, 230)
		Lighting.FogEnd = normalFogEnd
		Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
	end
end

local function playWarningPing()
	local sound = Instance.new("Sound")
	sound.SoundId = WARNING_SOUND
	sound.Volume = 0.7
	sound.Parent = Workspace
	sound:Play()
	task.delay(2, function()
		sound:Destroy()
	end)
end

local function sweepCarriers()
	-- Any carrier the wall has passed, who is not safe in their base, loses
	-- the character: it escapes back into the wild near them.
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if CatchService.isCarrying(player) then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and not BaseService.isPlayerInBase(player) then
				if wallX >= root.Position.X - 1 then
					local entry = CatchService.dropCarried(player, true)
					if entry then
						local remote = Remotes.get("Popup")
						if remote then
							remote:FireClient(player, {
								title = "Swept away!",
								text = "The wave caught you — " .. Config.getCharacter(entry.charId).name .. " escaped!",
							})
						end
					end
				end
			end
		end
	end
end

function WaveService.start()
	cycleStart = Workspace.DistributedGameTime
	nextWaveAt = cycleStart + Config.WAVE_INTERVAL
	normalBrightness = Lighting.Brightness
	normalFogEnd = Lighting.FogEnd
	broadcast()

	task.spawn(function()
		local lastBroadcast = 0
		while true do
			task.wait(0.5)
			local now = Workspace.DistributedGameTime
			local remaining = nextWaveAt - now

			if phase == "calm" and remaining <= Config.WAVE_WARNING then
				phase = "warning"
				setStormSky(true)
				playWarningPing()
				broadcast()
			elseif phase == "warning" and remaining <= 0 then
				phase = "sweep"
				-- The wall: a tall sheet of water crossing the whole map.
				wall = Instance.new("Part")
				wall.Name = "WaveWall"
				wall.Size = Vector3.new(4, 70, Config.MAP_HALF * 2 + 40)
				wall.Color = Color3.fromRGB(30, 170, 200)
				wall.Material = Enum.Material.Neon
				wall.Transparency = 0.35
				wall.Anchored = true
				wall.CanCollide = false
				wall.CanQuery = false
				wallX = -Config.MAP_HALF - 20
				wall.CFrame = CFrame.new(wallX, 30, 0)
				wall.Parent = Workspace
				broadcast()
			elseif phase == "sweep" then
				-- The wall crosses the map over WAVE_SWEEP_TIME seconds.
				local step = ((Config.MAP_HALF * 2 + 40) / Config.WAVE_SWEEP_TIME) * 0.5
				wallX += step
				if wall then
					wall.CFrame = CFrame.new(wallX, 30, 0)
				end
				sweepCarriers()
				if wallX >= Config.MAP_HALF + 20 then
					if wall then
						wall:Destroy()
						wall = nil
					end
					setStormSky(false)
					phase = "calm"
					nextWaveAt = Workspace.DistributedGameTime + Config.WAVE_INTERVAL
					broadcast()
				end
			end

			-- Keep the banner ticking every second of warning, and re-send the
			-- state every 5 seconds of calm so joining clients sync up.
			if phase == "warning" then
				broadcast()
			elseif os.clock() - lastBroadcast >= 5 then
				lastBroadcast = os.clock()
				broadcast()
			end
		end
	end)
end

return WaveService
