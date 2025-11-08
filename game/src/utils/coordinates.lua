local GameConstants = require("src.constants")
local tileSize = GameConstants.TILE_SIZE

---@class CoordinateUtils
local CoordinateUtils = {}

---Convert world coordinates to grid coordinates
---@param worldX number World X coordinate
---@param worldY number World Y coordinate
---@return number gridX
---@return number gridY
function CoordinateUtils.worldToGrid(worldX, worldY)
    local gridX = math.floor(worldX / tileSize) + 1
    local gridY = math.floor(worldY / tileSize) + 1
    return gridX, gridY
end

---Convert grid coordinates to world coordinates
---@param gridX number Grid X coordinate
---@param gridY number Grid Y coordinate
---@return number worldX
---@return number worldY
function CoordinateUtils.gridToWorld(gridX, gridY)
    local worldX = (gridX - 1) * tileSize + tileSize / 2
    local worldY = (gridY - 1) * tileSize + tileSize / 2
    return worldX, worldY
end

---Calculate distance between two positions
---@param pos1 Position First position
---@param pos2 Position Second position
---@return number Distance between positions
function CoordinateUtils.calculateDistance(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    return math.sqrt(dx * dx + dy * dy)
end

---Calculate distance between two points
---@param x1 number First X coordinate
---@param y1 number First Y coordinate
---@param x2 number Second X coordinate
---@param y2 number Second Y coordinate
---@return number Distance between points
function CoordinateUtils.calculateDistanceBetweenPoints(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

---Check if a world position is within the world bounds
---@param worldX number World X coordinate
---@param worldY number World Y coordinate
---@param grid table|nil Optional grid object for additional bounds checking
---@return boolean
function CoordinateUtils.isWithinWorldBounds(worldX, worldY, grid)
    local GameState = require("src.core.GameState")
    local GameConstants = require("src.constants")
    local worldWidthPixels, worldHeightPixels = GameState.getWorldBounds()

    -- Check world pixel bounds first (more efficient)
    if worldX < 0 or worldX >= worldWidthPixels or worldY < 0 or worldY >= worldHeightPixels then
        return false
    end

    -- Additional grid bounds check for safety if grid is provided
    if grid and grid.getBounds then
        local gridX, gridY = CoordinateUtils.worldToGrid(worldX, worldY)
        local minX, minY, maxX, maxY = grid:getBounds()
        return gridX >= minX and gridX <= maxX and gridY >= minY and gridY <= maxY
    end

    return true
end

---Clamp world coordinates to world bounds
---@param worldX number World X coordinate
---@param worldY number World Y coordinate
---@return number clampedX
---@return number clampedY
function CoordinateUtils.clampToWorldBounds(worldX, worldY)
    local GameState = require("src.core.GameState")
    local worldWidthPixels, worldHeightPixels = GameState.getWorldBounds()

    -- Clamp to world pixel bounds (0 to worldSize-1)
    local clampedX = math.max(0, math.min(worldX, worldWidthPixels - 1))
    local clampedY = math.max(0, math.min(worldY, worldHeightPixels - 1))

    return clampedX, clampedY
end

---Clamp grid coordinates to grid bounds
---@param gridX number Grid X coordinate
---@param gridY number Grid Y coordinate
---@param grid table Grid object with getBounds method
---@return number clampedGridX
---@return number clampedGridY
function CoordinateUtils.clampToGridBounds(gridX, gridY, grid)
    if not grid or not grid.getBounds then
        return gridX, gridY
    end

    local minX, minY, maxX, maxY = grid:getBounds()
    local clampedGridX = math.max(minX, math.min(gridX, maxX))
    local clampedGridY = math.max(minY, math.min(gridY, maxY))

    return clampedGridX, clampedGridY
end

---Convert world coordinates to screen coordinates
---@param worldX number World X coordinate
---@param worldY number World Y coordinate
---@param camera table Gamera camera instance
---@return number screenX, number screenY
function CoordinateUtils.worldToScreen(worldX, worldY, camera)
    if not camera or not camera.toScreen then
        return worldX, worldY
    end

    return camera:toScreen(worldX, worldY)
end

---Convert screen coordinates to world coordinates
---@param screenX number Screen X coordinate
---@param screenY number Screen Y coordinate
---@param camera table Gamera camera instance
---@return number worldX, number worldY
function CoordinateUtils.screenToWorld(screenX, screenY, camera)
    if not camera or not camera.toWorld then
        return screenX, screenY
    end

    return camera:toWorld(screenX, screenY)
end

return CoordinateUtils
