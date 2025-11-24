-- level1.lua
-- Entry-level composition file
-- Defines the simple 600x600 world for level 1

local level1 = {
    -- Unique level identifier
    id = "level_1",
    name = "Starting Sector",

    -- World dimensions
    worldWidth = 600,
    worldHeight = 600,

    -- Spawn coordinates (in world pixels)
    spawns = {
        player = { x = 300, y = 300 },  -- Center of world
        -- Add other entity spawns here as needed
        -- shop = { x = 100, y = 100 },
        -- crystal = { x = 500, y = 500 },
    },

    -- Optional: Environment settings for this level
    environment = {
        backgroundColor = { 204/255, 216/255, 219/255 },  -- #ccd8db
        ambientLight = 0.3,                       -- Global light level (0-1)
        music = "resources/music/level1.mp3",     -- Background music (if available)
    },

    -- Optional: Gameplay parameters
    gameplay = {
        difficulty = 1,
        enemySpawnMultiplier = 1.0,
        resourceMultiplier = 1.0
    }
}

return level1
