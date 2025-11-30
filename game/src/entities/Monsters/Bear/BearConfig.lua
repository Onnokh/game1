---@class BearConfig
---Centralized bear enemy attributes and constants
local BearConfig = {}

-- Movement speeds (multipliers of base speed)
BearConfig.WALKING_SPEED = 0.2        -- Slower than player

-- Animation settings
BearConfig.IDLE_ANIMATION = {
    layers = {"bear"},
    frames = {1},
    fps = 12,
    loop = true
}

BearConfig.WALKING_ANIMATION = {
    layers = {"bear"},
    frames = {1},
    fps = 12,
    loop = true
}

BearConfig.ATTACK_ANIMATION = {
    layers = {"bear"},
    frames = {1},
    fps = 18,
    loop = false,
    hitFrame = 0  -- Frame when damage triggers (0-indexed, so 0 = first frame)
}

BearConfig.DEATH_ANIMATION = {
    layers = {"bear"},
    frames = {1},
    fps = 12,
    loop = false
}

-- Chase behavior
BearConfig.ATTACK_RANGE_TILES = 1 -- stop within this many tiles of target

-- Attack settings
BearConfig.ATTACK_COOLDOWN = 0.722 -- seconds (matches animation duration: 13 frames / 18 fps)
BearConfig.ATTACK_DAMAGE = 2
BearConfig.ATTACK_KNOCKBACK = 4

-- Hit area dimensions for attack collider
BearConfig.ATTACK_HIT_WIDTH = 16   -- Width of the hit area
BearConfig.ATTACK_HIT_HEIGHT = 24   -- Height of the hit area

-- Physics settings
BearConfig.COLLIDER_WIDTH = 12
BearConfig.COLLIDER_HEIGHT = 8
BearConfig.COLLIDER_SHAPE = "circle" -- "rectangle" or "circle"
BearConfig.COLLIDER_RESTITUTION = 0.1
BearConfig.COLLIDER_FRICTION = 0.1
BearConfig.COLLIDER_DAMPING = 0.1

-- Sprite settings
BearConfig.SPRITE_WIDTH = 56
BearConfig.SPRITE_HEIGHT = 28

BearConfig.DRAW_WIDTH = 24
BearConfig.DRAW_HEIGHT = 16

-- Pathfinding collision offset
BearConfig.PATHFINDING_OFFSET_Y = BearConfig.SPRITE_HEIGHT /2 - BearConfig.COLLIDER_HEIGHT + 4

-- Combat settings
BearConfig.HEALTH = 6
BearConfig.MAX_HEALTH = 6

-- Outline settings
BearConfig.OUTLINE_COLOR = {r = 0, g = 0, b = 0, a = .5} -- Light gray outline

return BearConfig

