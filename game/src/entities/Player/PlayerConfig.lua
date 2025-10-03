---@class PlayerConfig
---Centralized player attributes and constants
local PlayerConfig = {}

-- Movement speeds (multipliers of base speed)
PlayerConfig.WALKING_SPEED = .8        -- Normal walking speed
PlayerConfig.RUNNING_SPEED = 1.5        -- Running speed multiplier (50% faster)
PlayerConfig.DASH_SPEED = 2.5           -- Dash speed multiplier (3x faster)

-- Dash mechanics
PlayerConfig.DASH_DURATION = .8        -- How long dash lasts (seconds)
PlayerConfig.DASH_COOLDOWN = 3        -- Cooldown between dashes (seconds)

-- Animation settings
PlayerConfig.IDLE_ANIMATION = {
    frames = {1, 2},
    fps = 4,
    loop = true
}

PlayerConfig.WALKING_ANIMATION = {
    frames = {9, 10, 11, 12},
    fps = 8,
    loop = true
}

PlayerConfig.RUNNING_ANIMATION = {
    frames = {13, 14, 15, 16},
    fps = 8,
    loop = true
}

PlayerConfig.DASH_ANIMATION = {
    frames = {41, 42},
    fps = 12,
    loop = false
}

-- Physics settings
PlayerConfig.COLLIDER_WIDTH = 12
PlayerConfig.COLLIDER_HEIGHT = 12
PlayerConfig.COLLIDER_RESTITUTION = 0.1
PlayerConfig.COLLIDER_FRICTION = 0.3
PlayerConfig.COLLIDER_DAMPING = 0

-- Sprite settings
PlayerConfig.SPRITE_WIDTH = 24
PlayerConfig.SPRITE_HEIGHT = 24

-- Future expansion - you can add more attributes here:
-- PlayerConfig.HEALTH = 100
-- PlayerConfig.MAX_HEALTH = 100
-- PlayerConfig.JUMP_FORCE = 300
-- PlayerConfig.JUMP_DURATION = 0.2
-- PlayerConfig.ATTACK_DAMAGE = 10
-- PlayerConfig.ATTACK_RANGE = 32

return PlayerConfig
