---@class SkeletonConfig
---Centralized skeleton enemy attributes and constants
local SkeletonConfig = {}

-- Movement speeds (multipliers of base speed)
SkeletonConfig.WALKING_SPEED = 0.4        -- Slower than player
SkeletonConfig.WANDER_RADIUS = 8 -- 1 tile wander radius

-- Animation settings
SkeletonConfig.IDLE_ANIMATION = {
    frames = {1, 2, 3, 4, 5, 6},
    fps = 3,
    loop = true
}

SkeletonConfig.WALKING_ANIMATION = {
    frames = {25, 26, 27, 28, 29, 30}, -- Row 5 (0-indexed as 4), columns 1-6 (0-indexed: 4*6+0 = 24)
    fps = 6,
    loop = true
}

-- Chase behavior
SkeletonConfig.CHASE_RANGE = 10 -- tiles
SkeletonConfig.ATTACK_RANGE_TILES = 1.2 -- stop within this many tiles of target

-- Attack settings
SkeletonConfig.ATTACK_COOLDOWN = 1.2 -- seconds
SkeletonConfig.ATTACK_DAMAGE = 8
SkeletonConfig.ATTACK_KNOCKBACK = 4

SkeletonConfig.DYING_ANIMATION = {
    frames = {37, 38, 39, 40}, -- Row 7 (0-indexed as 6), columns 1-4 (6*6+1 = 37)
    fps = 2,
    loop = false
}

-- Physics settings
SkeletonConfig.COLLIDER_WIDTH = 8
SkeletonConfig.COLLIDER_HEIGHT = 8
SkeletonConfig.COLLIDER_SHAPE = "circle" -- "rectangle" or "circle"
SkeletonConfig.COLLIDER_RESTITUTION = 0.1
SkeletonConfig.COLLIDER_FRICTION = 0.1
SkeletonConfig.COLLIDER_DAMPING = 0.1

-- Sprite settings
SkeletonConfig.SPRITE_WIDTH = 32
SkeletonConfig.SPRITE_HEIGHT = 32

SkeletonConfig.DRAW_WIDTH = 12
SkeletonConfig.DRAW_HEIGHT = 22

-- Combat settings
SkeletonConfig.HEALTH = 45
SkeletonConfig.MAX_HEALTH = 50

return SkeletonConfig
