---@class SlimeConfig
---Centralized slime enemy attributes and constants
local SlimeConfig = {}

-- Movement speeds
SlimeConfig.WALKING_SPEED = 0.35        -- Walking speed multiplier (for MonsterFactory compatibility)
SlimeConfig.JUMP_SPEED = 60             -- Jump speed in pixels/second (absolute value)
SlimeConfig.MIN_JUMP_DISTANCE = 1       -- Minimum jump distance in tiles
SlimeConfig.MAX_JUMP_DISTANCE = 2       -- Maximum jump distance in tiles

-- Animation settings (3 rows x 8 cols: 512px by 192px)
-- Row 1: Idle (frames 1-4)
-- Row 2: Walking (frames 9-16)
-- Row 3: Death (frames 17-24)
SlimeConfig.IDLE_ANIMATION = {
    layers = {"slime"},
    frames = {1, 2, 3, 4},
    fps = 4,
    loop = true
}

SlimeConfig.WALKING_ANIMATION = {
    layers = {"slime"},
    frames = {9, 10, 11, 12, 13, 14, 15, 16}, -- Row 2, all 8 frames
    fps = 6,
    loop = true
}

-- Chase behavior
SlimeConfig.ATTACK_RANGE_TILES = 3.0 -- Ranged attack - can attack from distance
SlimeConfig.ATTACK_RANGE_HYSTERESIS = 0.3 -- Buffer to prevent rapid state switching
SlimeConfig.PREFERRED_CHASE_RANGE_TILES = SlimeConfig.ATTACK_RANGE_TILES - 0.5

-- Projectile settings
SlimeConfig.PROJECTILE_SPEED = 180 -- Slower projectiles than skeleton
SlimeConfig.PROJECTILE_LIFETIME = 2.5

-- Attack settings
SlimeConfig.ATTACK_COOLDOWN = 1.5 -- seconds - slower attack rate
SlimeConfig.ATTACK_DAMAGE = 6
SlimeConfig.ATTACK_KNOCKBACK = 3

-- Hit area dimensions for attack collider
SlimeConfig.ATTACK_HIT_WIDTH = 24   -- Width of the hit area
SlimeConfig.ATTACK_HIT_HEIGHT = 12  -- Height of the hit area

SlimeConfig.DYING_ANIMATION = {
    layers = {"slime"},
    frames = {17, 18, 19, 20, 21, 22, 23, 24}, -- Row 3, all 8 frames
    fps = 8,
    loop = false
}

-- Physics settings
SlimeConfig.COLLIDER_WIDTH = 16
SlimeConfig.COLLIDER_HEIGHT = 10
SlimeConfig.COLLIDER_SHAPE = "circle" -- "rectangle" or "circle"
SlimeConfig.COLLIDER_RESTITUTION = 0.1
SlimeConfig.COLLIDER_FRICTION = 0.1
SlimeConfig.COLLIDER_DAMPING = 0.1

-- Sprite settings
SlimeConfig.SPRITE_WIDTH = 64
SlimeConfig.SPRITE_HEIGHT = 64

SlimeConfig.DRAW_WIDTH = 16
SlimeConfig.DRAW_HEIGHT = 16

-- Pathfinding collision offset
SlimeConfig.PATHFINDING_OFFSET_Y = SlimeConfig.SPRITE_HEIGHT - SlimeConfig.COLLIDER_HEIGHT - 24

-- Combat settings
SlimeConfig.HEALTH = 8
SlimeConfig.MAX_HEALTH = 8

-- Outline settings
SlimeConfig.OUTLINE_COLOR = {r = 0, g = 0, b = 0, a = .5} -- Light gray outline

return SlimeConfig

