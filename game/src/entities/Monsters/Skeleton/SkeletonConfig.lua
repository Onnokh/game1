---@class SkeletonConfig
---Centralized skeleton enemy attributes and constants
local SkeletonConfig = {}

-- Movement speeds (multipliers of base speed)
SkeletonConfig.WALKING_SPEED = 0.4        -- Slower than player

-- Animation settings
SkeletonConfig.IDLE_ANIMATION = {
    layers = {"skeleton"},
    frames = {1, 2, 3, 4, 5, 6},
    fps = 3,
    loop = true
}

SkeletonConfig.WALKING_ANIMATION = {
    layers = {"skeleton"},
    frames = {25, 26, 27, 28, 29, 30}, -- Row 5 (0-indexed as 4), columns 1-6 (0-indexed: 4*6+0 = 24)
    fps = 6,
    loop = true
}

-- Chase behavior
SkeletonConfig.ATTACK_RANGE_TILES = 4 -- Ranged attack - can attack from distance
SkeletonConfig.PREFERRED_CHASE_RANGE_TILES = 3 -- Maintains 3 tiles distance (inside attack range)

-- Projectile settings
SkeletonConfig.PROJECTILE_SPEED = 200
SkeletonConfig.PROJECTILE_LIFETIME = 2.0

-- Attack settings
SkeletonConfig.ATTACK_COOLDOWN = 3 -- seconds
SkeletonConfig.ATTACK_DAMAGE = 4
SkeletonConfig.ATTACK_KNOCKBACK = 4

-- Hit area dimensions for attack collider
SkeletonConfig.ATTACK_HIT_WIDTH = 16   -- Width of the hit area
SkeletonConfig.ATTACK_HIT_HEIGHT = 8   -- Height of the hit area

SkeletonConfig.DYING_ANIMATION = {
    layers = {"skeleton"},
    frames = {37, 38, 39, 40}, -- Row 7 (0-indexed as 6), columns 1-4 (6*6+1 = 37)
    fps = 8, -- 8 frames per second - 4 frames - 0.5 seconds
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

-- Pathfinding collision offset
SkeletonConfig.PATHFINDING_OFFSET_Y = SkeletonConfig.SPRITE_HEIGHT - SkeletonConfig.COLLIDER_HEIGHT - 8

-- Combat settings
SkeletonConfig.HEALTH = 10
SkeletonConfig.MAX_HEALTH = 10

-- Outline settings
SkeletonConfig.OUTLINE_COLOR = {r = 0, g = 0, b = 0, a = .5} -- Light gray outline

return SkeletonConfig
