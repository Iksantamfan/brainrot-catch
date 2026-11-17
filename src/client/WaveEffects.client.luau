-- Brainrot Catch — WaveEffects (client).
-- The wave banner at the top-centre and the warning tint. The server sends
-- the wave state; this script ticks the countdown down locally between
-- updates so the number never looks frozen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local gui = Instance.new("ScreenGui")
gui.Name = "WaveGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Full-screen warning tint, normally invisible.
local tint = Instance.new("Frame")
tint.Name = "WarningTint"
tint.Size = UDim2.fromScale(1, 1)
tint.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
tint.BackgroundTransparency = 1
tint.BorderSizePixel = 0
tint.Parent = gui

-- Wave banner, top-centre.
local banner = Instance.new("TextLabel")
banner.Name = "WaveBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 12)
banner.Size = UDim2.fromOffset(420, 46)
banner.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
banner.BackgroundTransparency = 0.25
banner.Text = "BRAINROT CATCH"
banner.TextColor3 = Color3.fromRGB(140, 200, 255)
banner.TextSize = 24
banner.Font = Enum.Font.SourceSansBold
banner.Parent = gui

local lastState = { phase = "calm", secondsLeft = 0 }
local lastReceivedAt = os.clock()
local lastPhase = "calm"

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", minutes, secs)
end

remotes:WaitForChild("WaveState").OnClientEvent:Connect(function(state)
	if state.phase == "warning" and lastPhase ~= "warning" then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.5
		sound.Parent = Workspace
		sound:Play()
		task.delay(2, function()
			sound:Destroy()
		end)
	end
	lastPhase = state.phase
	lastState = state
	lastReceivedAt = os.clock()
end)

RunService.RenderStepped:Connect(function()
	local elapsed = os.clock() - lastReceivedAt
	local secondsLeft = math.max(0, (lastState.secondsLeft or 0) - elapsed)
	if lastState.phase == "calm" then
		banner.Text = "NEXT WAVE  " .. formatTime(secondsLeft)
		banner.TextColor3 = Color3.fromRGB(140, 200, 255)
		tint.BackgroundTransparency = 1
	elseif lastState.phase == "warning" then
		banner.Text = "WAVE INCOMING  " .. formatTime(secondsLeft)
		banner.TextColor3 = Color3.fromRGB(255, 70, 70)
		-- Pulsing red tint while the warning runs.
		tint.BackgroundTransparency = 0.88 + math.sin(os.clock() * 5) * 0.05
	elseif lastState.phase == "sweep" then
		banner.Text = "WAVE SWEEPING — GET HOME!"
		banner.TextColor3 = Color3.fromRGB(255, 70, 70)
		tint.BackgroundTransparency = 0.92
	end
end)
