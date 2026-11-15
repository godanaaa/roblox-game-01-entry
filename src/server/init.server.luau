-- Coin Rush Obby: server game logic.
-- Coins spin, get collected and come back. Moving platforms slide and carry
-- anyone standing on them. Lava and falls send a player back to the last
-- checkpoint they touched. The finish pad ends the run and records the best
-- time. The client only draws the screens and the HUD; every rule lives here.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CoinCollected = ReplicatedStorage:WaitForChild("CoinCollected")
local GameWon = ReplicatedStorage:WaitForChild("GameWon")
local StartRun = ReplicatedStorage:WaitForChild("StartRun")
local RestartRun = ReplicatedStorage:WaitForChild("RestartRun")

local SPAWN_POSITION = Vector3.new(0, 3, 0)

-- The course parts are named for what they are (Coin1, Checkpoint1, Lava,
-- FinishPad, MovingPlatform1), so the server finds them by name.
local function partsNamed(prefix)
	local found = {}
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") and string.sub(descendant.Name, 1, #prefix) == prefix then
			table.insert(found, descendant)
		end
	end
	table.sort(found, function(a, b)
		return a.Name < b.Name
	end)
	return found
end

-- One state table per player. checkpoint is where lava and falls send them.
local playerState = {}

-- Coins: each keeps its home CFrame so it can spin in place.
local coins = {}
for _, part in ipairs(partsNamed("Coin")) do
	table.insert(coins, { part = part, baseCFrame = part.CFrame, taken = false })
end

-- Moving platforms: they slide along one axis on a sine wave, and anyone
-- standing on one is carried along by the same delta.
local movingPlatforms = {}
for _, part in ipairs(partsNamed("MovingPlatform")) do
	table.insert(movingPlatforms, {
		part = part,
		baseCFrame = part.CFrame,
		axis = part:GetAttribute("MoveAxis") or "X",
		distance = part:GetAttribute("MoveDistance") or 6,
		speed = part:GetAttribute("MoveSpeed") or 1.2,
		phase = part:GetAttribute("MovePhase") or 0,
		lastCFrame = part.CFrame,
	})
end

local function resetCoins()
	for _, coin in ipairs(coins) do
		coin.taken = false
		coin.part.Transparency = 0
		coin.part.CanTouch = true
	end
end

local function teleportToCheckpoint(player)
	local state = playerState[player]
	local character = player.Character
	if not state or not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(state.checkpoint)
	end
end

local function respawnPlayer(player)
	teleportToCheckpoint(player)
end

local function startRunFor(player)
	local state = playerState[player]
	if not state then
		return
	end
	state.coins = 0
	state.collected = {}
	state.won = false
	state.startTime = tick()
	state.checkpointIndex = 0
	state.checkpoint = SPAWN_POSITION
	resetCoins()
	teleportToCheckpoint(player)
end

local function initPlayer(player)
	playerState[player] = {
		coins = 0,
		collected = {},
		startTime = nil,
		checkpoint = SPAWN_POSITION,
		checkpointIndex = 0,
		won = false,
		lavaDebounce = false,
	}
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local root = character:WaitForChild("HumanoidRootPart")
		root.CFrame = CFrame.new(playerState[player].checkpoint)
	end)
end

Players.PlayerAdded:Connect(initPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	initPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
end)

StartRun.OnServerEvent:Connect(startRunFor)
RestartRun.OnServerEvent:Connect(startRunFor)

-- Coins: touch one to collect it. It hides, then spins back in, but it only
-- counts once per run for each player, so nobody can farm the same coin.
for _, coin in ipairs(coins) do
	coin.part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or coin.taken then
			return
		end
		local state = playerState[player]
		if not state or state.collected[coin.part] then
			return
		end
		state.collected[coin.part] = true
		state.coins += 1
		coin.taken = true
		coin.part.Transparency = 1
		coin.part.CanTouch = false
		CoinCollected:FireClient(player, state.coins, #coins)
		task.delay(Config.COIN_RESPAWN_TIME, function()
			coin.taken = false
			coin.part.Transparency = 0
			coin.part.CanTouch = true
		end)
	end)
end

-- Lava: one touch sends the player back to their last checkpoint.
for _, lava in ipairs(partsNamed("Lava")) do
	lava.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local state = playerState[player]
		if not state or state.lavaDebounce then
			return
		end
		state.lavaDebounce = true
		respawnPlayer(player)
		task.delay(Config.LAVA_RESPAWN_DELAY, function()
			state.lavaDebounce = false
		end)
	end)
end

-- Checkpoints: touching a pad further along the course moves the respawn
-- point there, and the pad flashes white to say it registered.
for _, pad in ipairs(partsNamed("Checkpoint")) do
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local state = playerState[player]
		if not state then
			return
		end
		local index = pad:GetAttribute("CheckpointIndex") or 0
		if index <= state.checkpointIndex then
			return
		end
		state.checkpointIndex = index
		state.checkpoint = pad.Position + Vector3.new(0, Config.RESPAWN_HEIGHT, 0)
		local oldColor = pad.Color
		pad.Color = Color3.fromRGB(255, 255, 255)
		task.delay(0.4, function()
			pad.Color = oldColor
		end)
	end)
end

-- Finish: the run ends, the time is measured, and the best time is kept on
-- the player for the HUD to show next run.
for _, pad in ipairs(partsNamed("Finish")) do
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		local state = playerState[player]
		if not state or state.won or not state.startTime then
			return
		end
		state.won = true
		local finishTime = tick() - state.startTime
		local best = player:GetAttribute("BestTime")
		if not best or finishTime < best then
			player:SetAttribute("BestTime", finishTime)
			best = finishTime
		end
		GameWon:FireClient(player, finishTime, state.coins, best)
	end)
end

-- Every frame: spin the coins, slide the moving platforms (carrying their
-- riders), and rescue anyone who fell past the lava.
RunService.Heartbeat:Connect(function()
	local now = tick()
	for _, coin in ipairs(coins) do
		if not coin.taken then
			coin.part.CFrame = coin.baseCFrame * CFrame.Angles(0, now * Config.COIN_SPIN_SPEED, 0)
		end
	end
	for _, platform in ipairs(movingPlatforms) do
		local offset = math.sin(now * platform.speed + platform.phase) * platform.distance
		local base = platform.baseCFrame
		local nextCFrame
		if platform.axis == "X" then
			nextCFrame = CFrame.new(base.Position + Vector3.new(offset, 0, 0)) * base.Rotation
		else
			nextCFrame = CFrame.new(base.Position + Vector3.new(0, 0, offset)) * base.Rotation
		end
		local delta = nextCFrame.Position - platform.lastCFrame.Position
		platform.part.CFrame = nextCFrame
		platform.lastCFrame = nextCFrame
		if delta.Magnitude > 0 then
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 then
					local rel = platform.part.CFrame:PointToObjectSpace(root.Position)
					local size = platform.part.Size
					if math.abs(rel.X) <= size.X / 2 + 0.5 and math.abs(rel.Z) <= size.Z / 2 + 0.5 and rel.Y >= 0 and rel.Y <= 4 then
						root.CFrame += delta
					end
				end
			end
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < Config.FALL_LIMIT_Y then
			respawnPlayer(player)
		end
	end
end)
