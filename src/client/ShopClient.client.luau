-- Brainrot Catch — ShopClient (client).
-- The shop panel: buy the next base slot, or rebirth for a permanent income
-- multiplier. Prices come from the shared Config; the server validates the
-- purchase and answers with SlotResult / RebirthResult.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.Name = "ShopButton"
openButton.Position = UDim2.new(0, 12, 0, 170)
openButton.Size = UDim2.fromOffset(110, 40)
openButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
openButton.Text = "SHOP"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 18
openButton.Font = Enum.Font.SourceSansBold
openButton.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.fromOffset(400, 300)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "SHOP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 24
title.Font = Enum.Font.SourceSansBold
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(36, 36)
closeButton.Position = UDim2.new(1, -40, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Parent = panel

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(1, -24, 0, 26)
cashLabel.Position = UDim2.new(0, 12, 0, 44)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "Cash: " .. Config.formatMoney(Config.START_CASH)
cashLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
cashLabel.TextSize = 18
cashLabel.Font = Enum.Font.SourceSansBold
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = panel

local slotsLabel = Instance.new("TextLabel")
slotsLabel.Size = UDim2.new(1, -24, 0, 24)
slotsLabel.Position = UDim2.new(0, 12, 0, 74)
slotsLabel.BackgroundTransparency = 1
slotsLabel.Text = "Base slots: " .. Config.START_SLOTS .. " / " .. Config.MAX_SLOTS
slotsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
slotsLabel.TextSize = 16
slotsLabel.Font = Enum.Font.SourceSans
slotsLabel.TextXAlignment = Enum.TextXAlignment.Left
slotsLabel.Parent = panel

local buySlotButton = Instance.new("TextButton")
buySlotButton.Size = UDim2.new(1, -24, 0, 52)
buySlotButton.Position = UDim2.new(0, 12, 0, 106)
buySlotButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
buySlotButton.Text = "BUY SLOT"
buySlotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
buySlotButton.TextSize = 20
buySlotButton.Font = Enum.Font.SourceSansBold
buySlotButton.Parent = panel

local rebirthLabel = Instance.new("TextLabel")
rebirthLabel.Size = UDim2.new(1, -24, 0, 24)
rebirthLabel.Position = UDim2.new(0, 12, 0, 170)
rebirthLabel.BackgroundTransparency = 1
rebirthLabel.Text = "Rebirths: 0  (income x1)"
rebirthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthLabel.TextSize = 16
rebirthLabel.Font = Enum.Font.SourceSans
rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
rebirthLabel.Parent = panel

local rebirthButton = Instance.new("TextButton")
rebirthButton.Size = UDim2.new(1, -24, 0, 52)
rebirthButton.Position = UDim2.new(0, 12, 0, 198)
rebirthButton.BackgroundColor3 = Color3.fromRGB(170, 80, 255)
rebirthButton.Text = "REBIRTH — " .. Config.formatMoney(Config.REBIRTH_COST)
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 20
rebirthButton.Font = Enum.Font.SourceSansBold
rebirthButton.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 24)
statusLabel.Position = UDim2.new(0, 12, 0, 258)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 215, 60)
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Parent = panel

local slotsUnlocked = Config.START_SLOTS
local rebirths = 0
local cash = Config.START_CASH

local function refresh()
	cashLabel.Text = "Cash: " .. Config.formatMoney(cash)
	slotsLabel.Text = "Base slots: " .. slotsUnlocked .. " / " .. Config.MAX_SLOTS
	if slotsUnlocked >= Config.MAX_SLOTS then
		buySlotButton.Text = "MAX SLOTS"
	else
		buySlotButton.Text = "BUY SLOT " .. (slotsUnlocked + 1) .. " — " .. Config.formatMoney(Config.slotUnlockCost(slotsUnlocked + 1))
	end
	rebirthLabel.Text = "Rebirths: " .. rebirths .. "  (income x" .. tostring(Config.rebirthMultiplier(rebirths)) .. ")"
	if rebirths >= Config.MAX_REBIRTHS then
		rebirthButton.Text = "MAX REBIRTHS"
	else
		rebirthButton.Text = "REBIRTH — " .. Config.formatMoney(Config.REBIRTH_COST)
	end
end

openButton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)
closeButton.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

buySlotButton.MouseButton1Click:Connect(function()
	remotes:WaitForChild("SlotRequest"):FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
	remotes:WaitForChild("RebirthRequest"):FireServer()
end)

remotes:WaitForChild("SlotResult").OnClientEvent:Connect(function(result)
	slotsUnlocked = result.slotsUnlocked
	if result.success then
		statusLabel.Text = "Slot " .. result.slotsUnlocked .. " unlocked!"
	else
		statusLabel.Text = result.reason == "max_slots" and "You already have every slot." or "Not enough cash for the next slot."
	end
	refresh()
end)

remotes:WaitForChild("RebirthResult").OnClientEvent:Connect(function(result)
	rebirths = result.rebirths
	if result.success then
		statusLabel.Text = "Rebirth " .. result.rebirths .. "! Income is now x" .. tostring(Config.rebirthMultiplier(result.rebirths)) .. "."
	else
		statusLabel.Text = result.reason == "max_rebirths" and "You are at max rebirths." or "You need " .. Config.formatMoney(Config.REBIRTH_COST) .. " to rebirth."
	end
	refresh()
end)

remotes:WaitForChild("CashChanged").OnClientEvent:Connect(function(state)
	cash = state.cash
	if panel.Visible then
		refresh()
	end
end)

refresh()
