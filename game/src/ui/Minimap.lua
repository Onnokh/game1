---@class Minimap
---UI component for rendering the minimap
local Minimap = {}
local panel = require("src.ui.utils.panel")
local gamera = require("lib.gamera")

-- Minimap configuration
local MINIMAP_SIZE = 400
local MINIMAP_PADDING = 20
local MINIMAP_VISIBLE_RADIUS = 1000 -- World pixels visible around player
local PANEL_PADDING = 8 -- Padding inside the panel for the minimap content
local CACHE_UPDATE_THRESHOLD = 100 -- Update cache when player moves this many pixels

-- Full world terrain canvas (generated once at map load)
local worldTerrainCanvas = nil
local worldTerrainScale = nil

---Initialize the minimap (called at startup)
function Minimap.init()
    -- Canvas will be created when terrain is generated
end

---Generate the full world terrain once (called when map loads)
---Should be called from MapManager after map is loaded
function Minimap.generateWorldTerrain()
    -- Get world dimensions from GameState
    local GameState = require("src.core.GameState")
    if not GameState.mapData then
        print("[Minimap] Warning: Cannot generate terrain - no map data")
        return
    end

    local worldWidth = GameState.mapData.width * GameState.mapData.tileSize
    local worldHeight = GameState.mapData.height * GameState.mapData.tileSize

    print(string.format("[Minimap] Generating world terrain canvas: %dx%d pixels", worldWidth, worldHeight))

    -- Calculate scale to fit world into a reasonable canvas size
    -- We'll create a canvas at the same scale as the minimap uses (0.2x)
    worldTerrainScale = MINIMAP_SIZE / (MINIMAP_VISIBLE_RADIUS * 2)
    local canvasWidth = math.ceil(worldWidth * worldTerrainScale)
    local canvasHeight = math.ceil(worldHeight * worldTerrainScale)

    -- Create canvas for the entire world
    local success, result = pcall(love.graphics.newCanvas, canvasWidth, canvasHeight)
    if not success then
        print("[Minimap] Warning: Failed to create world terrain canvas:", result)
        return
    end

    worldTerrainCanvas = result

    -- Create a camera for the full world
    local worldCamera = gamera.new(0, 0, worldWidth, worldHeight)
    worldCamera:setWindow(0, 0, canvasWidth, canvasHeight)
    worldCamera:setScale(worldTerrainScale)
    worldCamera:setPosition(worldWidth / 2, worldHeight / 2)

    -- Render the entire world to the canvas ONCE
    love.graphics.setCanvas(worldTerrainCanvas)
    love.graphics.clear(0, 0, 0, 0)

    worldCamera:draw(function()
        local MapManager = require("src.core.managers.MapManager")
        MapManager.draw(worldCamera)
    end)

    love.graphics.setCanvas()

    print("[Minimap] World terrain generated successfully")
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

---Draw portion of world terrain centered on player position
---@param minimapX number Minimap screen X position
---@param minimapY number Minimap screen Y position
---@param playerX number Player world X position
---@param playerY number Player world Y position
function Minimap.drawTerrain(minimapX, minimapY, playerX, playerY)
    if not worldTerrainCanvas then
        -- Terrain hasn't been generated yet
        return
    end

    -- Calculate which portion of the world canvas to draw
    -- Convert player world position to canvas coordinates
    local canvasX = playerX * worldTerrainScale
    local canvasY = playerY * worldTerrainScale

    -- Create a quad to draw the portion centered on player
    local halfSize = MINIMAP_SIZE / 2
    local quadX = math.max(0, canvasX - halfSize)
    local quadY = math.max(0, canvasY - halfSize)
    local quadW = MINIMAP_SIZE
    local quadH = MINIMAP_SIZE

    -- Clamp to canvas bounds
    local canvasW = worldTerrainCanvas:getWidth()
    local canvasH = worldTerrainCanvas:getHeight()

    if quadX + quadW > canvasW then
        quadX = math.max(0, canvasW - quadW)
    end
    if quadY + quadH > canvasH then
        quadY = math.max(0, canvasH - quadH)
    end

    -- Create quad for the portion we want to draw
    local quad = love.graphics.newQuad(quadX, quadY, quadW, quadH, canvasW, canvasH)

    -- Draw the portion of the world canvas
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(worldTerrainCanvas, quad, minimapX, minimapY)
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

    -- Draw portion of world terrain centered on player
    Minimap.drawTerrain(minimapX, minimapY, playerX, playerY)

    return minimapX, minimapY
end

---Cleanup minimap resources
function Minimap.cleanup()
    if worldTerrainCanvas then
        worldTerrainCanvas:release()
        worldTerrainCanvas = nil
    end
    worldTerrainScale = nil
end

return Minimap

