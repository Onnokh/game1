---@class CragBoarConfig
---Centralized crag-boar enemy attributes and constants
local CragBoarConfig = {}

-- Movement speeds (multipliers of base speed)
CragBoarConfig.WALKING_SPEED = 0.2        -- Slower than player

-- Animation settings
CragBoarConfig.IDLE_ANIMATION = {
    layers = {"crag-boar"},
    frames = {1},
    fps = 12,
    loop = true
}

CragBoarConfig.WALKING_ANIMATION = {
    layers = {"crag-boar"},
    frames = {1},
    fps = 12,
    loop = true
}

CragBoarConfig.ATTACK_ANIMATION = {
    layers = {"crag-boar"},
    frames = {1},
    fps = 18,
    loop = false,
    hitFrame = 0  -- Frame when damage triggers (0-indexed, so 0 = first frame)
}

CragBoarConfig.DEATH_ANIMATION = {
    layers = {"crag-boar"},
    frames = {1},
    fps = 12,
    loop = false
}

-- Chase behavior
CragBoarConfig.ATTACK_RANGE_TILES = 1 -- stop within this many tiles of target

-- Attack settings
CragBoarConfig.ATTACK_COOLDOWN = 0.722 -- seconds (matches animation duration: 13 frames / 18 fps)
CragBoarConfig.ATTACK_DAMAGE = 2
CragBoarConfig.ATTACK_KNOCKBACK = 4

-- Hit area dimensions for attack collider
CragBoarConfig.ATTACK_HIT_WIDTH = 16   -- Width of the hit area
CragBoarConfig.ATTACK_HIT_HEIGHT = 24   -- Height of the hit area

-- Physics settings
CragBoarConfig.COLLIDER_WIDTH = 12
CragBoarConfig.COLLIDER_HEIGHT = 8
CragBoarConfig.COLLIDER_SHAPE = "circle" -- "rectangle" or "circle"
CragBoarConfig.COLLIDER_RESTITUTION = 0.1
CragBoarConfig.COLLIDER_FRICTION = 0.1
CragBoarConfig.COLLIDER_DAMPING = 0.1

-- Sprite settings
CragBoarConfig.SPRITE_WIDTH = 32
CragBoarConfig.SPRITE_HEIGHT = 24

CragBoarConfig.DRAW_WIDTH = 24
CragBoarConfig.DRAW_HEIGHT = 16

-- Pathfinding collision offset
CragBoarConfig.PATHFINDING_OFFSET_Y = CragBoarConfig.SPRITE_HEIGHT /2 - CragBoarConfig.COLLIDER_HEIGHT + 4

-- Combat settings
CragBoarConfig.HEALTH = 6
CragBoarConfig.MAX_HEALTH = 6

-- Outline settings
CragBoarConfig.OUTLINE_COLOR = {r = 0, g = 0, b = 0, a = .5} -- Light gray outline

return CragBoarConfig

