---@class Minimap
---UI component for rendering the minimap
local Minimap = {}
local panel = require("src.ui.utils.panel")

-- Minimap configuration
local MINIMAP_SIZE = 400
local MINIMAP_PADDING = 20
local MINIMAP_VISIBLE_RADIUS = 1000 -- World pixels visible around player
local TILE_SAMPLE_RATE = 1 -- Sample every tile to ensure we don't miss 1-tile-wide bridges
local PANEL_PADDING = 8 -- Padding inside the panel for the minimap content

-- Colors
local WALKABLE_COLOR = {50/255, 50/255, 50/255, 1}
local BLOCKED_COLOR = {1/255, 1/255, 1/255, 1}

-- Terrain canvas
local terrainCanvas = nil

---Initialize the minimap (create canvas)
function Minimap.init()
    if not terrainCanvas then
        local success, result = pcall(love.graphics.newCanvas, MINIMAP_SIZE, MINIMAP_SIZE)
        if success then
            terrainCanvas = result
        else
            print("[Minimap] Warning: Failed to create terrain canvas:", result)
        end
    end
end

---Convert world coordinates to minimap pixel coordinates
---@param worldX number World X position
---@param worldY number World Y position
---@param playerX number Player world X position
---@param playerY number Player world Y position
---@return number, number Minimap X and Y coordinates (or nil if outside bounds)
function Minimap.worldToMinimap(worldX, worldY, playerX, playerY)
    -- Calculate offset from player
    local offsetX = worldX - playerX
    local offsetY = worldY - playerY

    -- Scale to minimap space
    local scale = MINIMAP_SIZE / (MINIMAP_VISIBLE_RADIUS * 2)
    local minimapX = (MINIMAP_SIZE / 2) + (offsetX * scale)
    local minimapY = (MINIMAP_SIZE / 2) + (offsetY * scale)

    return minimapX, minimapY
end

---Check if world coordinates are within minimap visible range
---@param worldX number World X position
---@param worldY number World Y position
---@param playerX number Player world X position
---@param playerY number Player world Y position
---@return boolean True if within visible range
function Minimap.isInVisibleRange(worldX, worldY, playerX, playerY)
    local dx = worldX - playerX
    local dy = worldY - playerY
    local distSq = dx * dx + dy * dy
    local radiusSq = MINIMAP_VISIBLE_RADIUS * MINIMAP_VISIBLE_RADIUS
    return distSq <= radiusSq
end

---Render terrain to canvas (updates every frame)
---@param collisionGrid table The collision grid from GameState
---@param gridWidth number Grid width in tiles
---@param gridHeight number Grid height in tiles
---@param tileSize number Size of each tile in world pixels
---@param playerX number Player world X position
---@param playerY number Player world Y position
function Minimap.renderTerrain(collisionGrid, gridWidth, gridHeight, tileSize, playerX, playerY)
    if not terrainCanvas then
        Minimap.init()
    end

    -- Render to canvas every frame
    love.graphics.setCanvas(terrainCanvas)
    love.graphics.clear(0, 0, 0, 0)

        -- Calculate visible grid bounds
        local GameConstants = require("src.constants")
        local CoordinateUtils = require("src.utils.coordinates")

        local minWorldX = playerX - MINIMAP_VISIBLE_RADIUS
        local maxWorldX = playerX + MINIMAP_VISIBLE_RADIUS
        local minWorldY = playerY - MINIMAP_VISIBLE_RADIUS
        local maxWorldY = playerY + MINIMAP_VISIBLE_RADIUS

        local minGridX, minGridY = CoordinateUtils.worldToGrid(minWorldX, minWorldY)
        local maxGridX, maxGridY = CoordinateUtils.worldToGrid(maxWorldX, maxWorldY)

        -- Expand by 2 tiles in each direction to avoid edge artifacts when moving
        minGridX = minGridX - 2
        minGridY = minGridY - 2
        maxGridX = maxGridX + 2
        maxGridY = maxGridY + 2

        -- Clamp to grid bounds
        minGridX = math.max(1, minGridX)
        minGridY = math.max(1, minGridY)
        maxGridX = math.min(gridWidth, maxGridX)
        maxGridY = math.min(gridHeight, maxGridY)

        -- Sample and render tiles
        for gridX = minGridX, maxGridX, TILE_SAMPLE_RATE do
            for gridY = minGridY, maxGridY, TILE_SAMPLE_RATE do
                -- Check if walkable (collisionGrid is worldMap[x][y] structure)
                local tileData = collisionGrid[gridX] and collisionGrid[gridX][gridY]
                local isWalkable = tileData and tileData.walkable or false

                -- Convert grid to world coordinates (gridToWorld already returns center of tile)
                local worldX, worldY = CoordinateUtils.gridToWorld(gridX, gridY)

                -- Convert to minimap coordinates
                local minimapX, minimapY = Minimap.worldToMinimap(worldX, worldY, playerX, playerY)

                -- Calculate tile draw size
                local scale = MINIMAP_SIZE / (MINIMAP_VISIBLE_RADIUS * 2)
                local tileDrawSize = tileSize * scale
                local halfTile = tileDrawSize / 2

                -- Skip if tile is completely outside minimap bounds (allow partially visible tiles)
                if minimapX + halfTile >= 0 and minimapX - halfTile <= MINIMAP_SIZE and
                   minimapY + halfTile >= 0 and minimapY - halfTile <= MINIMAP_SIZE then

                    -- Set color based on walkability
                    if isWalkable then
                        love.graphics.setColor(WALKABLE_COLOR)
                    else
                        love.graphics.setColor(BLOCKED_COLOR)
                    end

                    -- Draw tile
                    love.graphics.rectangle("fill",
                        minimapX - halfTile,
                        minimapY - halfTile,
                        tileDrawSize,
                        tileDrawSize
                    )
                end
            end
        end

        love.graphics.setCanvas()
end

---Draw the minimap
---@param playerX number Player world X position
---@param playerY number Player world Y position
function Minimap.draw(playerX, playerY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Calculate panel position (bottom-right with padding)
    local panelSize = MINIMAP_SIZE + (PANEL_PADDING * 2)
    local panelX = screenWidth - panelSize - MINIMAP_PADDING
    local panelY = screenHeight - panelSize - MINIMAP_PADDING

    -- Draw panel background
    panel.draw(panelX, panelY, panelSize, panelSize, 0.95, {0.9, 0.9, 0.9})

    -- Calculate minimap content position (inside panel with padding)
    local minimapX = panelX + PANEL_PADDING
    local minimapY = panelY + PANEL_PADDING

    -- Draw cached terrain
    if terrainCanvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(terrainCanvas, minimapX, minimapY)
    end

    return minimapX, minimapY
end

---Cleanup minimap resources
function Minimap.cleanup()
    if terrainCanvas then
        terrainCanvas:release()
        terrainCanvas = nil
    end
end

return Minimap

