---@class PlayerConfig
---Centralized player attributes and constants
local PlayerConfig = {}

-- Movement speeds (multipliers of base speed)
PlayerConfig.WALKING_SPEED = .8        -- Normal walking speed
PlayerConfig.RUNNING_SPEED = 1.5        -- Running speed multiplier (50% faster)
PlayerConfig.DASH_SPEED = 4           -- Dash speed multiplier (3x faster)

-- Extra burst multiplier applied only on dash start
PlayerConfig.DASH_BURST_MULTIPLIER = 2

-- Dash mechanics
PlayerConfig.DASH_DURATION = .25        -- How long dash lasts (seconds)
PlayerConfig.DASH_COOLDOWN = .1        -- Legacy cooldown (not used with charge system)
PlayerConfig.DASH_MAX_CHARGES = 3      -- Maximum number of dash charges
PlayerConfig.DASH_CHARGE_REGEN_TIME = 2.0  -- Time in seconds to regenerate one charge


-- Animation settings
-- PlayerConfig.IDLE_ANIMATION = {
--     sheet = "new",
--     frames = {1, 2, 3, 4},
--     fps = 4,
--     loop = true
-- }

PlayerConfig.WALKING_ANIMATION = {
  layers = {"player", "gun"},
  frames = {4, 5, 6, 7, 8, 9, 10, 11},
  fps = 12,
  loop = true
}

-- TODO: add check for if gun is equipped
-- if equipped, use gun_idle animation
-- if not equipped, use idle animation

PlayerConfig.IDLE_ANIMATION = {
  layers = {"player", "gun"},
  frames = {12, 13, 14, 15},
  fps = 8,
  loop = true
}

PlayerConfig.RUNNING_ANIMATION = {
  layers = {"player", "gun"},
  frames = {4, 5, 6, 7, 8, 9, 10, 11},
  fps = 12,
  loop = true
}

PlayerConfig.DASH_ANIMATION = {
  layers = {"player", "gun"},
  frames = {1, 2, 3},
  fps = 24,
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
-- Shooting position offset (relative to player position)
PlayerConfig.START_OFFSET = 20  -- Additional offset forward from gun position to account for gun sprite width
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

-- Dash shadow effects
PlayerConfig.DASH_SHADOW_DISTANCE = 45  -- Pixels between shadows
PlayerConfig.DASH_SHADOW_FADE_TIME = 0.2  -- How fast shadows fade after dash ends
PlayerConfig.DASH_SHADOW_OPACITY = 0.1  -- Initial opacity of shadows

return PlayerConfig
