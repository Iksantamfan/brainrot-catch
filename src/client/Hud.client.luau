-- Brainrot Catch — HUD (client).
-- The always-on interface: big money counter top-right, dash stamina bar
-- bottom-left, event notices under the top edge, popups in the centre, and a
-- minimap bottom-right. Nothing sits in the top-left corner, where Roblox
-- puts its own menu buttons.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- ---------------------------------------------------------------------------
-- Money counter, top-right.
-- ---------------------------------------------------------------------------
local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "MoneyFrame"
moneyFrame.AnchorPoint = Vector2.new(1, 0)
moneyFrame.Position = UDim2.new(1, -12, 0, 12)
moneyFrame.Size = UDim2.fromOffset(220, 64)
moneyFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
moneyFrame.BackgroundTransparency = 0.25
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = gui

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.new(1, -12, 0, 38)
moneyLabel.Position = UDim2.new(0, 6, 0, 2)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = Config.formatMoney(Config.START_CASH)
moneyLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
moneyLabel.TextSize = 30
moneyLabel.Font = Enum.Font.SourceSansBold
moneyLabel.TextXAlignment = Enum.TextXAlignment.Right
moneyLabel.Parent = moneyFrame

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(1, -12, 0, 20)
incomeLabel.Position = UDim2.new(0, 6, 0, 40)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+$0/s"
incomeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
incomeLabel.TextSize = 16
incomeLabel.Font = Enum.Font.SourceSans
incomeLabel.TextXAlignment = Enum.TextXAlignment.Right
incomeLabel.Parent = moneyFrame

remotes:WaitForChild("CashChanged").OnClientEvent:Connect(function(state)
	moneyLabel.Text = Config.formatMoney(state.cash)
	incomeLabel.Text = "+" .. Config.formatMoney(state.incomePerSecond) .. "/s"
end)

-- ---------------------------------------------------------------------------
-- Dash stamina bar, bottom-left. Shift dashes (server-validated).
-- ---------------------------------------------------------------------------
local dashFrame = Instance.new("Frame")
dashFrame.Name = "DashFrame"
dashFrame.AnchorPoint = Vector2.new(0, 1)
dashFrame.Position = UDim2.new(0, 12, 1, -12)
dashFrame.Size = UDim2.fromOffset(180, 44)
dashFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
dashFrame.BackgroundTransparency = 0.25
dashFrame.BorderSizePixel = 0
dashFrame.Parent = gui

local dashTitle = Instance.new("TextLabel")
dashTitle.Size = UDim2.new(1, 0, 0, 18)
dashTitle.BackgroundTransparency = 1
dashTitle.Text = "DASH  (Shift)"
dashTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
dashTitle.TextSize = 14
dashTitle.Font = Enum.Font.SourceSansBold
dashTitle.Parent = dashFrame

local dashBarBack = Instance.new("Frame")
dashBarBack.Size = UDim2.new(1, -12, 0, 14)
dashBarBack.Position = UDim2.new(0, 6, 0, 24)
dashBarBack.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
dashBarBack.BorderSizePixel = 0
dashBarBack.Parent = dashFrame

local dashBarFill = Instance.new("Frame")
dashBarFill.Name = "DashFill"
dashBarFill.Size = UDim2.new(1, 0, 1, 0)
dashBarFill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
dashBarFill.BorderSizePixel = 0
dashBarFill.Parent = dashBarBack

remotes:WaitForChild("DashState").OnClientEvent:Connect(function(state)
	dashBarFill.Size = UDim2.new(math.clamp((state.stamina or 100) / 100, 0, 1), 0, 1, 0)
end)

ContextActionService:BindAction("BrainrotDash", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		remotes:WaitForChild("DashRequest"):FireServer()
	end
end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)

-- ---------------------------------------------------------------------------
-- Event notice bar, under the top edge (below the wave banner).
-- ---------------------------------------------------------------------------
local eventLabel = Instance.new("TextLabel")
eventLabel.Name = "EventLabel"
eventLabel.AnchorPoint = Vector2.new(0.5, 0)
eventLabel.Position = UDim2.new(0.5, 0, 0, 76)
eventLabel.Size = UDim2.fromOffset(520, 30)
eventLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
eventLabel.BackgroundTransparency = 0.25
eventLabel.Text = ""
eventLabel.TextColor3 = Color3.fromRGB(255, 215, 60)
eventLabel.TextSize = 18
eventLabel.Font = Enum.Font.SourceSansBold
eventLabel.Visible = false
eventLabel.Parent = gui

local eventHideAt = 0
remotes:WaitForChild("EventNotice").OnClientEvent:Connect(function(notice)
	eventLabel.Text = notice.text
	eventLabel.Visible = true
	eventHideAt = os.clock() + math.max(3, notice.secondsLeft or 3)
end)

-- ---------------------------------------------------------------------------
-- Centre popup (catches, slots, rebirths, wave losses).
-- ---------------------------------------------------------------------------
local popupFrame = Instance.new("Frame")
popupFrame.Name = "PopupFrame"
popupFrame.AnchorPoint = Vector2.new(0.5, 0.5)
popupFrame.Position = UDim2.new(0.5, 0, 0.38, 0)
popupFrame.Size = UDim2.fromOffset(380, 84)
popupFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
popupFrame.BackgroundTransparency = 0.15
popupFrame.BorderSizePixel = 0
popupFrame.Visible = false
popupFrame.Parent = gui

local popupTitle = Instance.new("TextLabel")
popupTitle.Name = "PopupTitle"
popupTitle.Size = UDim2.new(1, -16, 0, 34)
popupTitle.Position = UDim2.new(0, 8, 0, 6)
popupTitle.BackgroundTransparency = 1
popupTitle.Text = ""
popupTitle.TextColor3 = Color3.fromRGB(255, 215, 60)
popupTitle.TextSize = 26
popupTitle.Font = Enum.Font.SourceSansBold
popupTitle.Parent = popupFrame

local popupText = Instance.new("TextLabel")
popupText.Name = "PopupText"
popupText.Size = UDim2.new(1, -16, 0, 36)
popupText.Position = UDim2.new(0, 8, 0, 42)
popupText.BackgroundTransparency = 1
popupText.Text = ""
popupText.TextColor3 = Color3.fromRGB(255, 255, 255)
popupText.TextSize = 16
popupText.Font = Enum.Font.SourceSans
popupText.TextWrapped = true
popupText.Parent = popupFrame

local popupHideAt = 0
remotes:WaitForChild("Popup").OnClientEvent:Connect(function(popup)
	popupTitle.Text = popup.title
	popupText.Text = popup.text
	popupFrame.Visible = true
	popupHideAt = os.clock() + 4
end)

-- ---------------------------------------------------------------------------
-- Minimap, bottom-right: wild characters as dots, bases as squares, the
-- player fixed in the centre.
-- ---------------------------------------------------------------------------
local mapFrame = Instance.new("Frame")
mapFrame.Name = "Minimap"
mapFrame.AnchorPoint = Vector2.new(1, 1)
mapFrame.Position = UDim2.new(1, -12, 1, -12)
mapFrame.Size = UDim2.fromOffset(150, 150)
mapFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mapFrame.BackgroundTransparency = 0.3
mapFrame.BorderSizePixel = 0
mapFrame.Parent = gui

local mapTitle = Instance.new("TextLabel")
mapTitle.Size = UDim2.new(1, 0, 0, 16)
mapTitle.BackgroundTransparency = 1
mapTitle.Text = "MAP"
mapTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
mapTitle.TextSize = 12
mapTitle.Font = Enum.Font.SourceSansBold
mapTitle.Parent = mapFrame

local baseDots = {}
for _, baseDef in ipairs(Config.BASES) do
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(8, 8)
	dot.BackgroundColor3 = baseDef.color
	dot.BorderSizePixel = 0
	dot.Position = UDim2.new(0.5 + (baseDef.position.X / (Config.MAP_HALF * 2)) * 0.9 - 0.027, 0, 0.5 + (baseDef.position.Z / (Config.MAP_HALF * 2)) * 0.9 - 0.027, 0)
	dot.Parent = mapFrame
	table.insert(baseDots, dot)
end

local playerDot = Instance.new("Frame")
playerDot.Size = UDim2.fromOffset(10, 10)
playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
playerDot.BorderSizePixel = 0
playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
playerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
playerDot.Parent = mapFrame

local wildDots = {}
local function toMap(position)
	return UDim2.new(
		0.5 + (position.X / (Config.MAP_HALF * 2)) * 0.9,
		0,
		0.5 + (position.Z / (Config.MAP_HALF * 2)) * 0.9,
		0
	)
end

local lastMapUpdate = 0
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	if now - eventHideAt > 0 and eventLabel.Visible and now > eventHideAt then
		eventLabel.Visible = false
	end
	if popupFrame.Visible and now > popupHideAt then
		popupFrame.Visible = false
	end
	if now - lastMapUpdate < 0.25 then
		return
	end
	lastMapUpdate = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		playerDot.Position = toMap(root.Position)
	end
	local wildFolder = Workspace:FindFirstChild("WildCharacters")
	if wildFolder then
		for _, dot in pairs(wildDots) do
			dot:Destroy()
		end
		wildDots = {}
		for _, model in ipairs(wildFolder:GetChildren()) do
			if model:IsA("Model") and model.PrimaryPart then
				local charId = model:GetAttribute("CharId")
				local characterDef = charId and Config.getCharacter(charId)
				local dot = Instance.new("Frame")
				dot.Size = UDim2.fromOffset(6, 6)
				dot.BackgroundColor3 = characterDef and Config.getRarity(characterDef.tier).color or Color3.fromRGB(255, 255, 255)
				dot.BorderSizePixel = 0
				dot.AnchorPoint = Vector2.new(0.5, 0.5)
				dot.Position = toMap(model:GetPivot().Position)
				dot.Parent = mapFrame
				table.insert(wildDots, dot)
			end
		end
	end
end)
