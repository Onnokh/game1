---@class WarhogConfig
---Centralized warhog enemy attributes and constants
local WarhogConfig = {}

-- Movement speeds (multipliers of base speed)
WarhogConfig.WALKING_SPEED = 0.2        -- Slower than player

-- Animation settings
WarhogConfig.IDLE_ANIMATION = {
    layers = {"Skull Boy"},
    frames = {1, 2, 3, 4, 5, 6, 7, 8},
    fps = 12,
    loop = true
}

WarhogConfig.WALKING_ANIMATION = {
    layers = {"Skull Boy"},
    frames = {15, 16, 17, 18, 19, 20, 21, 22},
    fps = 12,
    loop = true
}

WarhogConfig.ATTACK_ANIMATION = {
    layers = {"Skull Boy"},
    frames = {29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41},
    fps = 18,
    loop = false,
    hitFrame = 6  -- Frame 35 (index 6 in the 13-frame sequence) is when damage triggers
}

WarhogConfig.DEATH_ANIMATION = {
    layers = {"Skull Boy"},
    frames = {57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70},
    fps = 12,
    loop = false
}

-- Chase behavior
WarhogConfig.ATTACK_RANGE_TILES = 1 -- stop within this many tiles of target

-- Attack settings
WarhogConfig.ATTACK_COOLDOWN = 0.722 -- seconds (matches animation duration: 13 frames / 18 fps)
WarhogConfig.ATTACK_DAMAGE = 2
WarhogConfig.ATTACK_KNOCKBACK = 4

-- Hit area dimensions for attack collider
WarhogConfig.ATTACK_HIT_WIDTH = 16   -- Width of the hit area
WarhogConfig.ATTACK_HIT_HEIGHT = 24   -- Height of the hit area

-- Physics settings
WarhogConfig.COLLIDER_WIDTH = 12
WarhogConfig.COLLIDER_HEIGHT = 8
WarhogConfig.COLLIDER_SHAPE = "circle" -- "rectangle" or "circle"
WarhogConfig.COLLIDER_RESTITUTION = 0.1
WarhogConfig.COLLIDER_FRICTION = 0.1
WarhogConfig.COLLIDER_DAMPING = 0.1

-- Sprite settings
WarhogConfig.SPRITE_WIDTH = 192
WarhogConfig.SPRITE_HEIGHT = 192

WarhogConfig.DRAW_WIDTH = 34
WarhogConfig.DRAW_HEIGHT = 16

-- Pathfinding collision offset
WarhogConfig.PATHFINDING_OFFSET_Y = WarhogConfig.SPRITE_HEIGHT /2 - WarhogConfig.COLLIDER_HEIGHT + 18

-- Combat settings
WarhogConfig.HEALTH = 6
WarhogConfig.MAX_HEALTH = 6

return WarhogConfig

