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
GameConstants.BRIDGE_TILE_HORIZONTAL = {493, nil} -- Middle tiles for horizontal (east-west) bridges [top, bottom]
GameConstants.BRIDGE_TILE_VERTICAL = 493         -- Middle tile for vertical (north-south) bridges

-- Attachment patterns
GameConstants.BRIDGE_ATTACH_NORTH = {nil, 493, nil} -- 1 row: left to right
GameConstants.BRIDGE_ATTACH_EAST = {nil, 493, nil}  -- 1 column: top to bottom
GameConstants.BRIDGE_ATTACH_SOUTH = {
    {nil, 493, nil},  -- Row 1: left to right
    {nil, 493, nil}   -- Row 2: left to right
}
GameConstants.BRIDGE_ATTACH_WEST = {nil, 493, nil}  -- 1 column: top to bottom

-- Blocked tile GIDs (walls, obstacles, etc.)
GameConstants.BLOCKED_TILE_GIDS = {699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713, 725, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738, 739}

-- Tile light configuration
-- Maps tile GIDs to light properties
GameConstants.TILE_LIGHTS = {
    -- Example: Add your tile GIDs and their light properties here
    -- [GID] = { radius = 200, r = 255, g = 200, b = 100, offsetX = 16, offsetY = 16, flicker = true }

    -- Example light tiles (uncomment` and modify as needed):
    [728] = { radius = 30, r = 255, g = 220, b = 150, offsetX = 24, offsetY = 14, flicker = true },
    [731] = { radius = 20, r = 150, g = 220, b = 255, offsetX = 10, offsetY = 6, flicker = true },
    [732] = { radius = 20, r = 150, g = 220, b = 255, offsetX = 24, offsetY = 6, flicker = true },
    [735] = { radius = 30, r = 255, g = 220, b = 150, offsetX = 8, offsetY = 14, flicker = true },
}

-- Player constants
GameConstants.PLAYER_WIDTH = 24
GameConstants.PLAYER_HEIGHT = 24
GameConstants.PLAYER_SPEED = 80 -- player speed in pixels per second

-- Camera constants
GameConstants.CAMERA_SCALE = 3 -- Zoomed out to see more of the worldw

-- Oxygen system constants
GameConstants.OXYGEN_MAX = 100
GameConstants.OXYGEN_DECAY_RATE = 3 -- oxygen per second when outside safe zone
GameConstants.OXYGEN_RESTORE_RATE = 20 -- oxygen per second when inside safe zone during Siege
GameConstants.REACTOR_SAFE_RADIUS = 220 -- radius around reactor where oxygen doesn't decay

return GameConstants
