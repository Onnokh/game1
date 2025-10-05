---@class GameConstants
---Global game constants shared across all modules
---@field TILE_SIZE number
---@field WORLD_WIDTH number
---@field WORLD_HEIGHT number
---@field WORLD_WIDTH_PIXELS number
---@field WORLD_HEIGHT_PIXELS number
---@field PLAYER_WIDTH number
---@field PLAYER_HEIGHT number
---@field PLAYER_SPEED number
---@field CAMERA_SCALE number
local GameConstants = {}

-- World dimensions
GameConstants.TILE_SIZE = 16  -- Larger tiles
GameConstants.WORLD_WIDTH = 50
GameConstants.WORLD_HEIGHT = 50

-- Calculate pixel dimensions
GameConstants.WORLD_WIDTH_PIXELS = GameConstants.WORLD_WIDTH * GameConstants.TILE_SIZE
GameConstants.WORLD_HEIGHT_PIXELS = GameConstants.WORLD_HEIGHT * GameConstants.TILE_SIZE

-- Player constants
GameConstants.PLAYER_WIDTH = 24
GameConstants.PLAYER_HEIGHT = 24
GameConstants.PLAYER_SPEED = 80 -- Match working implementation

-- Camera constants
GameConstants.CAMERA_SCALE = 3 -- Zoomed out to see more of the world

-- Feature toggles
GameConstants.ENABLE_KNOCKBACK = true

-- Collision categories for Love2D physics
GameConstants.COLLISION_CATEGORIES = {
    PATHFINDING = 1,  -- PathfindingCollision components
    PHYSICS = 2       -- PhysicsCollision components
}

-- Collision masks (what each category can collide with)
GameConstants.COLLISION_MASKS = {
    PATHFINDING = 1 + 2,  -- PathfindingCollision collides with both PathfindingCollision and PhysicsCollision
    PHYSICS = 2           -- PhysicsCollision only collides with other PhysicsCollision
}

return GameConstants
