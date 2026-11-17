-- Brainrot Catch — IndexClient (client).
-- The collection book: a panel listing all twelve brainrots, coloured when
-- discovered, greyed out as "???" when not. The server owns the data; this
-- script only asks for it and draws it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local gui = Instance.new("ScreenGui")
gui.Name = "IndexGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.Name = "IndexButton"
openButton.Position = UDim2.new(0, 12, 0, 120)
openButton.Size = UDim2.fromOffset(110, 40)
openButton.BackgroundColor3 = Color3.fromRGB(170, 80, 255)
openButton.Text = "INDEX"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 18
openButton.Font = Enum.Font.SourceSansBold
openButton.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "IndexPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.fromOffset(460, 380)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "BRAINROT INDEX"
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

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 24)
subtitle.Position = UDim2.new(0, 0, 0, 40)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Catch them all — complete the book for $1,000,000!"
subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
subtitle.TextSize = 14
subtitle.Font = Enum.Font.SourceSans
subtitle.Parent = panel

local grid = Instance.new("Frame")
grid.Name = "IndexGrid"
grid.Position = UDim2.new(0, 12, 0, 70)
grid.Size = UDim2.new(1, -24, 1, -82)
grid.BackgroundTransparency = 1
grid.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(138, 92)
layout.CellPadding = UDim2.fromOffset(8, 8)
layout.Parent = grid

local slots = {}
for _, character in ipairs(Config.CHARACTERS) do
	local rarity = Config.getRarity(character.tier)
	local slot = Instance.new("Frame")
	slot.Name = character.id
	slot.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	slot.BorderSizePixel = 0
	slot.Parent = grid

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0, 30)
	nameLabel.Position = UDim2.new(0, 4, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "???"
	nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = slot

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -8, 0, 20)
	rarityLabel.Position = UDim2.new(0, 4, 0, 36)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = rarity.name
	rarityLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	rarityLabel.TextSize = 13
	rarityLabel.Font = Enum.Font.SourceSans
	rarityLabel.Parent = slot

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, -8, 0, 20)
	incomeLabel.Position = UDim2.new(0, 4, 0, 60)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = ""
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
	incomeLabel.TextSize = 13
	incomeLabel.Font = Enum.Font.SourceSans
	incomeLabel.Parent = slot

	slots[character.id] = { frame = slot, name = nameLabel, rarity = rarityLabel, income = incomeLabel }
end

local function refresh(discovered)
	for _, character in ipairs(Config.CHARACTERS) do
		local slot = slots[character.id]
		local rarity = Config.getRarity(character.tier)
		if discovered and discovered[character.id] then
			slot.name.Text = character.name
			slot.name.TextColor3 = Color3.fromRGB(255, 255, 255)
			slot.rarity.Text = rarity.name
			slot.rarity.TextColor3 = rarity.color
			slot.income.Text = Config.formatMoney(rarity.income) .. "/s"
			slot.frame.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
		else
			slot.name.Text = "???"
			slot.name.TextColor3 = Color3.fromRGB(150, 150, 150)
			slot.rarity.Text = rarity.name
			slot.rarity.TextColor3 = Color3.fromRGB(150, 150, 150)
			slot.income.Text = ""
			slot.frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		end
	end
end

openButton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		remotes:WaitForChild("IndexRequest"):FireServer()
	end
end)
closeButton.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

remotes:WaitForChild("IndexData").OnClientEvent:Connect(function(data)
	refresh(data.discovered)
end)
