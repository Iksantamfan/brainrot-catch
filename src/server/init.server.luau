-- Brainrot Catch — server init.
-- Wires every module together: builds the world, starts the services, loads
-- profiles on join and saves them on leave. One script, one job: startup.

local Players = game:GetService("Players")

local BaseService = require(script.BaseService)
local CatchService = require(script.CatchService)
local DashService = require(script.DashService)
local DataManager = require(script.DataManager)
local EventService = require(script.EventService)
local IncomeService = require(script.IncomeService)
local IndexService = require(script.IndexService)
local RebirthService = require(script.RebirthService)
local Remotes = require(script.Remotes)
local Spawner = require(script.Spawner)
local WaveService = require(script.WaveService)
local WorldBuilder = require(script.WorldBuilder)

-- RemoteEvents must exist before any other module (or client) asks for them.
Remotes.getAll()

WorldBuilder.buildWorld()

DataManager.startRetryLoop()
DataManager.startAutosaveLoop()

Spawner.start()
CatchService.start()
DashService.start()
WaveService.start()
IncomeService.start()
BaseService.start()
RebirthService.start()
IndexService.start()
EventService.start()

local function onPlayerAdded(player)
	DataManager.loadProfile(player)
	BaseService.assignBase(player)
	BaseService.rebuildBase(player)
end

local function onPlayerRemoving(player)
	CatchService.cancelChannel(player, "left")
	CatchService.dropCarried(player, false)
	BaseService.unassignBase(player)
	DataManager.saveProfile(player, true)
	DataManager.removeProfile(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- On shutdown (Studio stop, server close), save every dirty profile once.
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataManager.saveProfile(player, true)
	end
end)

print("[BrainrotCatch] Server ready — Brainrot Catch is live.")
