-- Brainrot Catch — CatchClient (client).
-- The catch interaction: E (or the big CATCH button) asks the server to
-- start a channel on the nearest wild character. The button always shows the
-- nearest catchable character's name, and the progress bar fills over the
-- channel time the rarity demands. The server validates everything; this
-- script only asks and displays.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local gui = Instance.new("ScreenGui")
gui.Name = "CatchGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Big CATCH button, bottom-centre.
local catchButton = Instance.new("TextButton")
catchButton.Name = "CatchButton"
catchButton.AnchorPoint = Vector2.new(0.5, 1)
catchButton.Position = UDim2.new(0.5, 0, 1, -16)
catchButton.Size = UDim2.fromOffset(170, 64)
catchButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
catchButton.Text = "CATCH  (E)"
catchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
catchButton.TextSize = 24
catchButton.Font = Enum.Font.SourceSansBold
catchButton.Parent = gui

-- Channel progress bar above the button.
local channelBack = Instance.new("Frame")
channelBack.Name = "ChannelBack"
channelBack.AnchorPoint = Vector2.new(0.5, 1)
channelBack.Position = UDim2.new(0.5, 0, 1, -92)
channelBack.Size = UDim2.fromOffset(220, 20)
channelBack.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
channelBack.BackgroundTransparency = 0.25
channelBack.BorderSizePixel = 0
channelBack.Visible = false
channelBack.Parent = gui

local channelFill = Instance.new("Frame")
channelFill.Name = "ChannelFill"
channelFill.Size = UDim2.new(0, 0, 1, 0)
channelFill.BackgroundColor3 = Color3.fromRGB(255, 215, 60)
channelFill.BorderSizePixel = 0
channelFill.Parent = channelBack

local channelLabel = Instance.new("TextLabel")
channelLabel.Name = "ChannelLabel"
channelLabel.AnchorPoint = Vector2.new(0.5, 1)
channelLabel.Position = UDim2.new(0.5, 0, 1, -116)
channelLabel.Size = UDim2.fromOffset(300, 22)
channelLabel.BackgroundTransparency = 1
channelLabel.Text = ""
channelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
channelLabel.TextSize = 16
channelLabel.Font = Enum.Font.SourceSansBold
channelLabel.Visible = false
channelLabel.Parent = gui

local channel = nil -- { charId, channelTime, startedAt }
local nearestUid = nil
local nearestName = nil

local function findNearestWild()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, nil, nil
	end
	local wildFolder = Workspace:FindFirstChild("WildCharacters")
	if not wildFolder then
		return nil, nil, nil
	end
	local best = nil
	local bestDist = Config.CATCH_MAX_DISTANCE
	local bestName = nil
	for _, model in ipairs(wildFolder:GetChildren()) do
		if model:IsA("Model") and model.PrimaryPart then
			local dist = (model:GetPivot().Position - root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = model
				bestName = model.Name
			end
		end
	end
	if best then
		return best:GetAttribute("Uid"), bestName, bestDist
	end
	return nil, nil, nil
end

local function tryCatch()
	if channel then
		return
	end
	local uid = nearestUid
	if not uid then
		return
	end
	remotes:WaitForChild("CatchRequest"):FireServer(uid)
end

catchButton.MouseButton1Click:Connect(tryCatch)
ContextActionService:BindAction("BrainrotCatch", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		tryCatch()
	end
end, false, Enum.KeyCode.E)

remotes:WaitForChild("CatchResult").OnClientEvent:Connect(function(result)
	if result.state == "started" then
		local characterDef = Config.getCharacter(result.charId)
		local rarity = characterDef and Config.getRarity(characterDef.tier)
		channel = {
			charId = result.charId,
			channelTime = rarity and rarity.channelTime or 1,
			startedAt = os.clock(),
		}
		channelBack.Visible = true
		channelLabel.Visible = true
		channelLabel.Text = "Catching " .. (characterDef and characterDef.name or "?") .. "..."
	elseif result.state == "caught" then
		channel = nil
		channelBack.Visible = false
		channelLabel.Visible = false
	elseif result.state == "cancelled" or result.state == "rejected" then
		channel = nil
		channelBack.Visible = false
		if result.reason == "too_far" then
			channelLabel.Text = "Too far away!"
			channelLabel.Visible = true
			task.delay(2, function()
				if not channel then
					channelLabel.Visible = false
				end
			end)
		elseif result.reason == "already_carrying" then
			channelLabel.Text = "You already carry one — take it home first!"
			channelLabel.Visible = true
			task.delay(2, function()
				if not channel then
					channelLabel.Visible = false
				end
			end)
		else
			channelLabel.Visible = false
		end
	end
end)

-- Nearest-target scan + channel fill, throttled to 10 Hz.
local lastScan = 0
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	if channel then
		local progress = math.clamp((now - channel.startedAt) / channel.channelTime, 0, 1)
		channelFill.Size = UDim2.new(progress, 0, 1, 0)
		return
	end
	if now - lastScan < 0.1 then
		return
	end
	lastScan = now
	nearestUid, nearestName = findNearestWild()
	if nearestUid then
		catchButton.Text = "CATCH " .. string.upper(nearestName) .. "  (E)"
		catchButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
	else
		catchButton.Text = "CATCH  (E)"
		catchButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
	end
end)
