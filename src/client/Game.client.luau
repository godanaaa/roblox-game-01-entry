-- Coin Rush Obby: client screens and HUD.
-- A start screen with the title and the rules, a heads-up display with the
-- coin count and the running timer while you play, and a win screen with the
-- final time and a Play Again button. The server owns every rule; this file
-- only draws what the server reports. The HUD sits top-right and top-centre,
-- clear of Roblox's own menu buttons in the top-left corner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local CoinCollected = ReplicatedStorage:WaitForChild("CoinCollected")
local GameWon = ReplicatedStorage:WaitForChild("GameWon")
local StartRun = ReplicatedStorage:WaitForChild("StartRun")
local RestartRun = ReplicatedStorage:WaitForChild("RestartRun")

local TOTAL_COINS = 10

local runStartTime = nil
local bestTime = player:GetAttribute("BestTime")

local function formatTime(seconds)
	if not seconds then
		return "--:--.-"
	end
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	return string.format("%d:%04.1f", minutes, rest)
end

local gui = Instance.new("ScreenGui")
gui.Name = "CoinRushGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10

-- Start screen: the title, how to play, and the Play button.
local startFrame = Instance.new("Frame")
startFrame.Name = "StartScreen"
startFrame.Size = UDim2.fromScale(1, 1)
startFrame.BackgroundColor3 = Color3.fromRGB(18, 32, 66)
startFrame.BackgroundTransparency = 0.15
startFrame.BorderSizePixel = 0
startFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0.14, 0)
title.Size = UDim2.new(0.8, 0, 0.14, 0)
title.BackgroundTransparency = 1
title.Text = "COIN RUSH OBBY"
title.TextColor3 = Color3.fromRGB(255, 214, 64)
title.TextSize = 64
title.Font = Enum.Font.GothamBold
title.Parent = startFrame

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Position = UDim2.new(0.5, 0, 0.3, 0)
subtitle.Size = UDim2.new(0.7, 0, 0.22, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Sprint across the floating platforms, grab every spinning coin, ride the moving platforms, and reach the golden finish pad.\n\nTouch lava and you go back to your last checkpoint. Blue pads save your progress."
subtitle.TextColor3 = Color3.fromRGB(240, 240, 240)
subtitle.TextSize = 22
subtitle.Font = Enum.Font.Gotham
subtitle.TextWrapped = true
subtitle.Parent = startFrame

local bestLabel = Instance.new("TextLabel")
bestLabel.Name = "BestLabel"
bestLabel.AnchorPoint = Vector2.new(0.5, 0)
bestLabel.Position = UDim2.new(0.5, 0, 0.52, 0)
bestLabel.Size = UDim2.new(0.7, 0, 0.05, 0)
bestLabel.BackgroundTransparency = 1
bestLabel.Text = bestTime and ("Best time: " .. formatTime(bestTime)) or ""
bestLabel.TextColor3 = Color3.fromRGB(255, 214, 64)
bestLabel.TextSize = 20
bestLabel.Font = Enum.Font.GothamBold
bestLabel.Parent = startFrame

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.AnchorPoint = Vector2.new(0.5, 0)
playButton.Position = UDim2.new(0.5, 0, 0.58, 0)
playButton.Size = UDim2.new(0.3, 0, 0.11, 0)
playButton.BackgroundColor3 = Color3.fromRGB(56, 199, 94)
playButton.BorderSizePixel = 0
playButton.Text = "PLAY"
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.TextSize = 36
playButton.Font = Enum.Font.GothamBold
playButton.Parent = startFrame

local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 12)
playCorner.Parent = playButton

-- HUD: coins top-right, timer top-centre.
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUD"
hudFrame.Size = UDim2.fromScale(1, 1)
hudFrame.BackgroundTransparency = 1
hudFrame.Visible = false
hudFrame.Parent = gui

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.AnchorPoint = Vector2.new(1, 0)
coinsLabel.Position = UDim2.new(1, -16, 0, 16)
coinsLabel.Size = UDim2.new(0, 220, 0, 44)
coinsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
coinsLabel.BackgroundTransparency = 0.4
coinsLabel.Text = "Coins: 0 / " .. tostring(TOTAL_COINS)
coinsLabel.TextColor3 = Color3.fromRGB(255, 214, 64)
coinsLabel.TextSize = 24
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = hudFrame

local coinsCorner = Instance.new("UICorner")
coinsCorner.CornerRadius = UDim.new(0, 8)
coinsCorner.Parent = coinsLabel

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.AnchorPoint = Vector2.new(0.5, 0)
timerLabel.Position = UDim2.new(0.5, 0, 0, 16)
timerLabel.Size = UDim2.new(0, 180, 0, 44)
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.BackgroundTransparency = 0.4
timerLabel.Text = "Time: 0:00.0"
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextSize = 24
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = hudFrame

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 8)
timerCorner.Parent = timerLabel

-- Win screen: final time, coins, best time, and Play Again.
local winFrame = Instance.new("Frame")
winFrame.Name = "WinScreen"
winFrame.Size = UDim2.fromScale(1, 1)
winFrame.BackgroundColor3 = Color3.fromRGB(18, 32, 66)
winFrame.BackgroundTransparency = 0.15
winFrame.BorderSizePixel = 0
winFrame.Visible = false
winFrame.Parent = gui

local winTitle = Instance.new("TextLabel")
winTitle.Name = "WinTitle"
winTitle.AnchorPoint = Vector2.new(0.5, 0)
winTitle.Position = UDim2.new(0.5, 0, 0.18, 0)
winTitle.Size = UDim2.new(0.8, 0, 0.14, 0)
winTitle.BackgroundTransparency = 1
winTitle.Text = "YOU WIN!"
winTitle.TextColor3 = Color3.fromRGB(255, 214, 64)
winTitle.TextSize = 64
winTitle.Font = Enum.Font.GothamBold
winTitle.Parent = winFrame

local winStats = Instance.new("TextLabel")
winStats.Name = "WinStats"
winStats.AnchorPoint = Vector2.new(0.5, 0)
winStats.Position = UDim2.new(0.5, 0, 0.36, 0)
winStats.Size = UDim2.new(0.7, 0, 0.2, 0)
winStats.BackgroundTransparency = 1
winStats.Text = ""
winStats.TextColor3 = Color3.fromRGB(240, 240, 240)
winStats.TextSize = 26
winStats.Font = Enum.Font.Gotham
winStats.TextWrapped = true
winStats.Parent = winFrame

local playAgainButton = Instance.new("TextButton")
playAgainButton.Name = "PlayAgainButton"
playAgainButton.AnchorPoint = Vector2.new(0.5, 0)
playAgainButton.Position = UDim2.new(0.5, 0, 0.6, 0)
playAgainButton.Size = UDim2.new(0.3, 0, 0.11, 0)
playAgainButton.BackgroundColor3 = Color3.fromRGB(56, 199, 94)
playAgainButton.BorderSizePixel = 0
playAgainButton.Text = "PLAY AGAIN"
playAgainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playAgainButton.TextSize = 32
playAgainButton.Font = Enum.Font.GothamBold
playAgainButton.Parent = winFrame

local againCorner = Instance.new("UICorner")
againCorner.CornerRadius = UDim.new(0, 12)
againCorner.Parent = playAgainButton

gui.Parent = player:WaitForChild("PlayerGui")

local function beginRun()
	coinsLabel.Text = "Coins: 0 / " .. tostring(TOTAL_COINS)
	runStartTime = os.clock()
	startFrame.Visible = false
	winFrame.Visible = false
	hudFrame.Visible = true
end

playButton.MouseButton1Click:Connect(function()
	StartRun:FireServer()
	beginRun()
end)

playAgainButton.MouseButton1Click:Connect(function()
	RestartRun:FireServer()
	beginRun()
end)

CoinCollected.OnClientEvent:Connect(function(count, total)
	coinsLabel.Text = "Coins: " .. tostring(count) .. " / " .. tostring(total)
end)

GameWon.OnClientEvent:Connect(function(finishTime, coins, best)
	runStartTime = nil
	bestTime = best
	bestLabel.Text = "Best time: " .. formatTime(best)
	hudFrame.Visible = false
	winStats.Text = "Time: " .. formatTime(finishTime) .. "\nCoins: " .. tostring(coins) .. " / " .. tostring(TOTAL_COINS) .. "\nBest time: " .. formatTime(best)
	winFrame.Visible = true
end)

-- The timer ticks on the client from the moment Play is pressed; the win
-- screen shows the server's own measured time, which is the one that counts.
RunService.RenderStepped:Connect(function()
	if runStartTime then
		timerLabel.Text = "Time: " .. formatTime(os.clock() - runStartTime)
	end
end)
