---@class TemplateConfig
---Template configuration for creating new monsters
---Copy this file and customize values for your monster type
local TemplateConfig = {}

-- Movement speeds (multipliers of base speed)
TemplateConfig.WALKING_SPEED = 0.4        -- Movement speed multiplier (0.4 = slower than player)

-- Animation settings
TemplateConfig.IDLE_ANIMATION = {
    sheet = "monster_sheet_name",        -- Name of sprite sheet
    frames = {1, 2, 3, 4},               -- Frame indices for animation
    fps = 6,                              -- Frames per second
    loop = true                           -- Whether animation loops
}

TemplateConfig.WALKING_ANIMATION = {
    sheet = "monster_sheet_name",
    frames = {5, 6, 7, 8},
    fps = 8,
    loop = true
}

-- Optional: Only needed if you have a custom attack animation
-- TemplateConfig.ATTACK_ANIMATION = {
--     sheet = "monster_sheet_name",
--     frames = {9, 10, 11, 12},
--     fps = 8,
--     loop = true
-- }

TemplateConfig.DYING_ANIMATION = {
    sheet = "monster_sheet_name",
    frames = {13, 14, 15, 16},
    fps = 8,
    loop = false                          -- Death animation should not loop
}

-- Chase behavior
TemplateConfig.ATTACK_RANGE_TILES = 0.8   -- Tiles - how close to get before attacking

-- Attack settings
TemplateConfig.ATTACK_COOLDOWN = 1.2      -- Seconds between attacks
TemplateConfig.ATTACK_DAMAGE = 32         -- Damage per attack
TemplateConfig.ATTACK_KNOCKBACK = 4       -- Knockback force


-- Physics settings (pathfinding collider)
TemplateConfig.COLLIDER_WIDTH = 12        -- Pixels
TemplateConfig.COLLIDER_HEIGHT = 8        -- Pixels
TemplateConfig.COLLIDER_SHAPE = "circle"  -- "rectangle" or "circle"
TemplateConfig.COLLIDER_RESTITUTION = 0.1 -- Bounciness (0-1)
TemplateConfig.COLLIDER_FRICTION = 0.1    -- Friction (0-1)
TemplateConfig.COLLIDER_DAMPING = 0.1     -- Linear damping (0-1)

-- Sprite settings
TemplateConfig.SPRITE_WIDTH = 32          -- Width of sprite frame in pixels
TemplateConfig.SPRITE_HEIGHT = 32         -- Height of sprite frame in pixels

-- Draw settings (physics interaction size)
TemplateConfig.DRAW_WIDTH = 12            -- Width for physics interaction
TemplateConfig.DRAW_HEIGHT = 22           -- Height for physics interaction

-- Combat settings
TemplateConfig.HEALTH = 50                -- Starting health
TemplateConfig.MAX_HEALTH = 50            -- Maximum health


return TemplateConfig

