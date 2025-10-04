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

return CoordinateUtils
