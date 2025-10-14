-- level1.lua
-- Entry-level composition file
-- Defines the base island and generation parameters for level 1

local level1 = {
    -- Unique level identifier
    id = "level_1",
    name = "Starting Sector",

    -- Base/starting island configuration
    baseIsland = {
        id = "base_island",
        name = "Home Base",
        mapPath = "resources/tiled/maps/islands/base_island.lua",
        theme = "tech",
        properties = {
            hasReactor = true,
            enemySpawns = false,
            safe = true,
        }
    },

    -- Random island generation parameters
    generation = {
        seed = nil,              -- nil = random seed, or set specific number for deterministic generation
        islandCount = {          -- How many random islands to generate
            min = 8,
            max = 12
        },

        -- Distance constraints for island placement (in pixels or tiles)
        spacing = {
            min = 640,           -- Distance from base island edge (about base island height)
            max = 1280           -- Maximum distance from base island edge
        },

        -- Available island types and their weights (higher = more likely)
        islandPool = {
            {
                id = "forest_island",
                name = "Forest Outpost",
                mapPath = "resources/tiled/maps/islands/forest_island.lua",
                theme = "forest",
                weight = 100,
                properties = {
                    hasReactor = false,
                    enemySpawns = true,
                    safe = false,
                    enemyTypes = { "warhog" }
                },
                loot = {
                    coinMultiplier = 1.2,
                    rareLootChance = 0.1,
                    chestCount = { min = 1, max = 3 }
                }
            },
            {
              id = "empty_island",
              name = "Empty Island",
              mapPath = "resources/tiled/maps/islands/empty_island.lua",
              theme = "forest",
              weight = 100,
              properties = {
                  hasReactor = false,
                  enemySpawns = true,
                  safe = false,
                  enemyTypes = { "slime", "skeleton" }
              },
              loot = {
                  coinMultiplier = 1.2,
                  rareLootChance = 0.1,
                  chestCount = { min = 1, max = 3 }
              }
          },
          {
            id = "shop_island",
            name = "Shop Island",
            mapPath = "resources/tiled/maps/islands/shop_island.lua",
            theme = "forest",
            weight = 100,
            properties = {
                hasReactor = false,
                enemySpawns = false,
                safe = false,
                enemyTypes = {}
            },
            loot = {
                coinMultiplier = 1.2,
                rareLootChance = 0.1,
                chestCount = { min = 1, max = 3 }
            }
        },
            -- Add more island types here as you create them
            -- {
            --     id = "desert_island",
            --     name = "Desert Ruins",
            --     mapPath = "resources/tiled/maps/islands/desert_island.lua",
            --     theme = "desert",
            --     weight = 40,
            --     properties = { ... }
            -- },
        },

        -- Placement preferences
        placement = {
            allowOverlap = false,        -- Whether islands can overlap
            preferCardinalDirections = true,  -- Favor N, S, E, W placement
            distributionMode = "scattered"     -- "scattered", "clustered", or "ring"
        }
    },

    -- Optional: Environment settings for this level
    environment = {
        backgroundColor = { 0.05, 0.05, 0.15 },  -- Dark space background
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
