-- Coin Rush Obby: shared tuning. One place to change how the game feels.
-- The server reads these values; the client never needs them.

local Config = {
	-- How long a collected coin stays hidden before it spins back in.
	COIN_RESPAWN_TIME = 5,
	-- Grace time after a lava hit before lava can hurt the same player again.
	LAVA_RESPAWN_DELAY = 0.5,
	-- How fast coins spin, in radians per second.
	COIN_SPIN_SPEED = 2,
	-- Any character that falls below this height is rescued to its checkpoint.
	FALL_LIMIT_Y = -20,
	-- How high above a checkpoint pad a player respawns.
	RESPAWN_HEIGHT = 3,
}

return Config
