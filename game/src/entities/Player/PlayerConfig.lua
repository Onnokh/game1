---@class PlayerConfig
---Centralized player attributes and constants
local PlayerConfig = {}

-- Movement speeds (multipliers of base speed)
PlayerConfig.WALKING_SPEED = .8        -- Normal walking speed
PlayerConfig.RUNNING_SPEED = 1.5        -- Running speed multiplier (50% faster)
PlayerConfig.DASH_SPEED = 2.5           -- Dash speed multiplier (3x faster)

-- Dash mechanics
PlayerConfig.DASH_DURATION = .4        -- How long dash lasts (seconds)
PlayerConfig.DASH_COOLDOWN = 3        -- Cooldown between dashes (seconds)

-- Animation settings
PlayerConfig.IDLE_ANIMATION = {
    sheet = "new",
    frames = {1, 2, 3, 4},
    fps = 4,
    loop = true
}

PlayerConfig.WALKING_ANIMATION = {
  sheet = "new_walk",
  frames = {1, 2, 3, 4, 5, 6},
  fps = 10,
  loop = true
}

PlayerConfig.RUNNING_ANIMATION = {
  sheet = "new_walk",
  frames = {1, 2, 3, 4, 5, 6},
  fps = 12,
  loop = true
}

PlayerConfig.DASH_ANIMATION = {
  sheet = "heu_slide",
  frames = {1, 2},
  fps = 8,
  loop = false
}

-- Physics settings
PlayerConfig.COLLIDER_WIDTH = 12
PlayerConfig.COLLIDER_HEIGHT = 12
PlayerConfig.COLLIDER_SHAPE = "circle"
PlayerConfig.COLLIDER_RESTITUTION = 0.1
PlayerConfig.COLLIDER_FRICTION = 0.3
PlayerConfig.COLLIDER_DAMPING = 0

-- Sprite settings
PlayerConfig.SPRITE_WIDTH = 32
PlayerConfig.SPRITE_HEIGHT = 32

-- Walking particle effects
PlayerConfig.WALKING_PARTICLES = {
    enabled = true,
    count = 1,              -- Number of particles per spawn
    life = .5,             -- How long particles live (seconds)
    size = 2,               -- Particle size
    color = {r = 0.8, g = 0.6, b = 0.4, a = 0.7}, -- Dust color
    velocity = {
        min = 20,           -- Minimum velocity
        max = 40,           -- Maximum velocity
        spread = 0         -- Degrees of spread
    },
    spawnRate = 0.15        -- How often to spawn particles (seconds)
}

return PlayerConfig
