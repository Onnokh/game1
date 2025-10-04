---@class CoordinateUtils
local CoordinateUtils = {}

---Convert world coordinates to grid coordinates
---@param worldX number World X coordinate
---@param worldY number World Y coordinate
---@param tileSize number Size of each tile
---@return number gridX
---@return number gridY
function CoordinateUtils.worldToGrid(worldX, worldY, tileSize)
    local gridX = math.floor(worldX / tileSize) + 1
    local gridY = math.floor(worldY / tileSize) + 1
    return gridX, gridY
end

---Convert grid coordinates to world coordinates
---@param gridX number Grid X coordinate
---@param gridY number Grid Y coordinate
---@param tileSize number Size of each tile
---@return number worldX
---@return number worldY
function CoordinateUtils.gridToWorld(gridX, gridY, tileSize)
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

return CoordinateUtils
