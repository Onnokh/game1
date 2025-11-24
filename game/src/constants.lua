---@class GameConstants
---Global game constants shared across all modules
---@field TILE_SIZE number
---@field PLAYER_WIDTH number
---@field PLAYER_HEIGHT number
---@field PLAYER_SPEED number
---@field CAMERA_SCALE number
---@field ZOOM_SCALE number
local GameConstants = {}

-- Tile size (used for coordinate conversion)
GameConstants.TILE_SIZE = 32  -- Match Tiled map tile size

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

-- Camera scale (controls how much the game world is scaled up)
-- 1 = 1:1 pixel size, 2 = 2x pixel size (double), etc.
GameConstants.CAMERA_SCALE = 3




return GameConstants
