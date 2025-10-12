---@class GameConstants
---Global game constants shared across all modules
---@field TILE_SIZE number
---@field MAX_BRIDGE_DISTANCE_TILES number
---@field ISLAND_ADJACENCY_DISTANCE_TILES number
---@field BRIDGE_SELECTION_POOL_RATIO number
---@field PLAYER_WIDTH number
---@field PLAYER_HEIGHT number
---@field PLAYER_SPEED number
---@field CAMERA_SCALE number
---@field OXYGEN_MAX number
---@field OXYGEN_DECAY_RATE number
---@field OXYGEN_RESTORE_RATE number
---@field REACTOR_SAFE_RADIUS number
local GameConstants = {}

-- Tile size (used for coordinate conversion)
GameConstants.TILE_SIZE = 32  -- Match Tiled map tile size

-- Bridge generation constants
GameConstants.MAX_BRIDGE_DISTANCE_TILES = 10 -- Maximum distance between islands for bridge generation
GameConstants.ISLAND_ADJACENCY_DISTANCE_TILES = 7 -- Distance to consider islands "adjacent"
GameConstants.BRIDGE_SELECTION_POOL_RATIO = 0.5 -- Pick from shortest 50% of valid bridge positions (0.0-1.0)

-- Player constants
GameConstants.PLAYER_WIDTH = 24
GameConstants.PLAYER_HEIGHT = 24
GameConstants.PLAYER_SPEED = 80 -- Match working implementation

-- Camera constants
GameConstants.CAMERA_SCALE = .5 -- Zoomed out to see more of the worldw

-- Oxygen system constants
GameConstants.OXYGEN_MAX = 100
GameConstants.OXYGEN_DECAY_RATE = 3 -- oxygen per second when outside safe zone
GameConstants.OXYGEN_RESTORE_RATE = 20 -- oxygen per second when inside safe zone during Siege
GameConstants.REACTOR_SAFE_RADIUS = 220 -- radius around reactor where oxygen doesn't decay

return GameConstants
