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
---@field CAMERA_FOLLOW_SPEED number
local GameConstants = {}

-- World dimensions
GameConstants.TILE_SIZE = 16
GameConstants.WORLD_WIDTH = 20  -- tiles
GameConstants.WORLD_HEIGHT = 48 -- tiles

-- Calculate pixel dimensions
GameConstants.WORLD_WIDTH_PIXELS = GameConstants.WORLD_WIDTH * GameConstants.TILE_SIZE
GameConstants.WORLD_HEIGHT_PIXELS = GameConstants.WORLD_HEIGHT * GameConstants.TILE_SIZE

-- Player constants
GameConstants.PLAYER_WIDTH = 16
GameConstants.PLAYER_HEIGHT = 24
GameConstants.PLAYER_SPEED = 100

-- Camera constants
GameConstants.CAMERA_SCALE = 4.0
GameConstants.CAMERA_FOLLOW_SPEED = 5

return GameConstants
