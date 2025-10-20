---@class WarhogConfig
---Centralized warhog enemy attributes and constants
local WarhogConfig = {}

-- Movement speeds (multipliers of base speed)
WarhogConfig.WALKING_SPEED = 0.2        -- Slower than player
WarhogConfig.WANDER_RADIUS = 8 -- 1 tile wander radius

-- Animation settings
WarhogConfig.IDLE_ANIMATION = {
    sheet = "Warhog_Idle",
    frames = {5, 6, 7, 8},
    fps = 8,
    loop = true
}

WarhogConfig.WALKING_ANIMATION = {
    sheet = "Warhog_Walk",
    frames = {9, 10, 11, 12},
    fps = 8,
    loop = true
}

WarhogConfig.ATTACK_ANIMATION = {
    sheet = "Warhog_Attack",
    frames = {9, 10, 11, 12},
    fps = 4,
    loop = true
}

WarhogConfig.DEATH_ANIMATION = {
    sheet = "Warhog_Death",
    frames = {9, 10, 11, 12},
    fps = 8,
    loop = false
}

-- Chase behavior
WarhogConfig.CHASE_RANGE = 5 -- tiles
WarhogConfig.ATTACK_RANGE_TILES = .2 -- stop within this many tiles of target

-- Attack settings
WarhogConfig.ATTACK_COOLDOWN = 3 -- seconds
WarhogConfig.ATTACK_DAMAGE = 2
WarhogConfig.ATTACK_KNOCKBACK = 4

-- Physics settings
WarhogConfig.COLLIDER_WIDTH = 12
WarhogConfig.COLLIDER_HEIGHT = 8
WarhogConfig.COLLIDER_SHAPE = "circle" -- "rectangle" or "circle"
WarhogConfig.COLLIDER_RESTITUTION = 0.1
WarhogConfig.COLLIDER_FRICTION = 0.1
WarhogConfig.COLLIDER_DAMPING = 0.1

-- Sprite settings
WarhogConfig.SPRITE_WIDTH = 64
WarhogConfig.SPRITE_HEIGHT = 64

WarhogConfig.DRAW_WIDTH = 34
WarhogConfig.DRAW_HEIGHT = 16

-- Pathfinding collision offset
WarhogConfig.PATHFINDING_OFFSET_Y = WarhogConfig.SPRITE_HEIGHT - WarhogConfig.COLLIDER_HEIGHT - 18

-- Combat settings
WarhogConfig.HEALTH = 6
WarhogConfig.MAX_HEALTH = 6

return WarhogConfig

