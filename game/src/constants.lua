---@class GameConstants
---Global game constants shared across all modules
---@field TILE_SIZE number
---@field MAX_BRIDGE_DISTANCE_TILES number
---@field PLAYER_WIDTH number
---@field PLAYER_HEIGHT number
---@field PLAYER_SPEED number
---@field ZOOM_SCALE number
local GameConstants = {}

-- Tile size (used for coordinate conversion)
GameConstants.TILE_SIZE = 32  -- Match Tiled map tile size

-- Bridge generation constants
GameConstants.MAX_BRIDGE_DISTANCE_TILES = 10 -- Maximum distance between islands for bridge generation

-- Bridge tile GIDs
GameConstants.BRIDGE_TILE_HORIZONTAL = {334, 360} -- Middle tiles for horizontal (east-west) bridges [top, bottom]
GameConstants.BRIDGE_TILE_VERTICAL = 233         -- Middle tile for vertical (north-south) bridges

-- Attachment patterns
GameConstants.BRIDGE_ATTACH_NORTH = {nil, 259, nil}  -- Row 1: left to right
GameConstants.BRIDGE_ATTACH_EAST = {536, 333, 358}  -- 1 column: top to bottom
GameConstants.BRIDGE_ATTACH_SOUTH = {
    {nil, 231, nil},  -- Row 1: left to right
    {nil, 257, nil}   -- Row 2: left to right
}
GameConstants.BRIDGE_ATTACH_WEST = {311, 337, 363}  -- 1 column: top to bottom

-- Maps tile GIDs to light properties
GameConstants.TILE_LIGHTS = {
    [499] = { radius = 30, r = 255, g = 220, b = 150, offsetX = 24, offsetY = 14, flicker = true },
    [502] = { radius = 20, r = 150, g = 220, b = 255, offsetX = 10, offsetY = 6, flicker = true },
    [503] = { radius = 20, r = 150, g = 220, b = 255, offsetX = 24, offsetY = 6, flicker = true },
    [506] = { radius = 30, r = 255, g = 220, b = 150, offsetX = 8, offsetY = 14, flicker = true },
}

-- Player constants
GameConstants.PLAYER_WIDTH = 24
GameConstants.PLAYER_HEIGHT = 24
GameConstants.PLAYER_SPEED = 80 -- player speed in pixels per second

-- Zoom constants (controls render resolution multiplier)
-- 1 = 160×90 (most pixelated)
-- 2 = 320×180 (balanced)
-- 3 = 480×270 (more detail)
-- 4 = 640×360 (most detail, largest view)
GameConstants.ZOOM_SCALE = 4 -- Default to 3x (480×270)


return GameConstants
