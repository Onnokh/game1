---@class GameConstants
---Global game constants shared across all modules
---@field TILE_SIZE number
---@field PLAYER_WIDTH number
---@field PLAYER_HEIGHT number
---@field PLAYER_SPEED number
---@field CAMERA_SCALE number
local GameConstants = {}

-- Tile size (used for coordinate conversion)
GameConstants.TILE_SIZE = 32  -- Match Tiled map tile size

-- Player constants
GameConstants.PLAYER_WIDTH = 24
GameConstants.PLAYER_HEIGHT = 24
GameConstants.PLAYER_SPEED = 80 -- Match working implementation

-- Camera constants
GameConstants.CAMERA_SCALE = 5 -- Zoomed out to see more of the worldw

-- Feature toggles
GameConstants.ENABLE_KNOCKBACK = true

-- Oxygen system constants
GameConstants.OXYGEN_MAX = 100
GameConstants.OXYGEN_DECAY_RATE = 3 -- oxygen per second when outside safe zone
GameConstants.OXYGEN_RESTORE_RATE = 20 -- oxygen per second when inside safe zone during Siege
GameConstants.REACTOR_SAFE_RADIUS = 200 -- radius around reactor where oxygen doesn't decay

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
