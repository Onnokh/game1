---@class GameConstants
---Global game constants shared across all modules
---@field TILE_SIZE number
---@field MAX_BRIDGE_DISTANCE_TILES number
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

-- Bridge tile GIDs
GameConstants.BRIDGE_TILE_HORIZONTAL = {147, 162} -- Middle tiles for horizontal (east-west) bridges [top, bottom]
GameConstants.BRIDGE_TILE_VERTICAL = 186         -- Middle tile for vertical (north-south) bridges

-- Attachment patterns
GameConstants.BRIDGE_ATTACH_NORTH = {125, 126, 127} -- 1 row: left to right
GameConstants.BRIDGE_ATTACH_EAST = {nil, 146, 161}  -- 1 column: top to bottom
GameConstants.BRIDGE_ATTACH_SOUTH = {
    {nil, 141, nil},  -- Row 1: left to right
    {170, 171, 172}   -- Row 2: left to right
}
GameConstants.BRIDGE_ATTACH_WEST = {nil, 148, 139}  -- 1 column: top to bottom

-- Player constants
GameConstants.PLAYER_WIDTH = 24
GameConstants.PLAYER_HEIGHT = 24
GameConstants.PLAYER_SPEED = 80 -- player speed in pixels per second

-- Camera constants
GameConstants.CAMERA_SCALE = 2 -- Zoomed out to see more of the worldw

-- Oxygen system constants
GameConstants.OXYGEN_MAX = 100
GameConstants.OXYGEN_DECAY_RATE = 3 -- oxygen per second when outside safe zone
GameConstants.OXYGEN_RESTORE_RATE = 20 -- oxygen per second when inside safe zone during Siege
GameConstants.REACTOR_SAFE_RADIUS = 220 -- radius around reactor where oxygen doesn't decay

return GameConstants
