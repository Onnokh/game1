-- MapManager.lua
-- Orchestrates loading and placement of all maps in the game
-- Manages main island + randomly generated surrounding islands
-- Provides draw/update interface for the game scene

local MapManager = {}

-- Internal state
MapManager.maps = {}           -- Table of all loaded map instances {id, map, x, y, width, height}
MapManager.baseIsland = nil    -- Reference to the main/starting island
MapManager.levelConfig = nil   -- Configuration loaded from level file
MapManager.bridges = {}        -- Array of bridge connections between islands
MapManager.initialized = false

-- Dependencies (will be required as needed)
local TiledMapLoader = nil
local IslandGenerator = nil

---@param levelPath string Path to level configuration file (e.g., "src/maps/level1")
function MapManager.load(levelPath)
    -- Clear previous state
    MapManager.maps = {}
    MapManager.baseIsland = nil
    MapManager.levelConfig = nil

    -- Load dependencies
    TiledMapLoader = require("src.maps.TiledMapLoader")
    IslandGenerator = require("src.maps.utils.IslandGenerator")

    -- Load level configuration
    local levelModule = require(levelPath:gsub("/", "."))
    MapManager.levelConfig = levelModule

    print("[MapManager] Loading level: " .. levelModule.name)

    -- Get base island definition (now embedded in level config)
    local baseIslandDef = levelModule.baseIsland
    print("[MapManager] Loading base island: " .. baseIslandDef.name)

    -- Load the base island map
    local baseMap = TiledMapLoader.load(baseIslandDef.mapPath)
    if not baseMap then
        print("[MapManager] ERROR: Failed to load base island map")
        return
    end

    -- Calculate actual map dimensions
    local baseWidth = baseMap.width * baseMap.tilewidth
    local baseHeight = baseMap.height * baseMap.tileheight

    -- Store base island data
    MapManager.baseIsland = {
        id = "base",
        definition = baseIslandDef,
        map = baseMap,
        x = 0,
        y = 0,
        width = baseWidth,
        height = baseHeight
    }

    table.insert(MapManager.maps, MapManager.baseIsland)
    print(string.format("[MapManager] Base island loaded: %dx%d pixels at (0, 0)", baseWidth, baseHeight))

    -- Generate random islands and bridges using IslandGenerator
    local generatedIslands, bridges = IslandGenerator.generate(
        MapManager.levelConfig,
        MapManager.baseIsland
    )

    -- Add generated islands (maps are already loaded by IslandGenerator)
    for _, islandData in ipairs(generatedIslands) do
        if islandData.map then
            table.insert(MapManager.maps, islandData)
        else
            print("[MapManager] WARNING: Island has no map: " .. islandData.id)
        end
    end

    -- Store bridges
    MapManager.bridges = bridges or {}

    MapManager.initialized = true
    print("[MapManager] Loaded " .. #MapManager.maps .. " islands total")
end

---@param dt number Delta time
---@param camera table|nil Optional camera for culling (only update visible islands)
function MapManager.update(dt, camera)
    if not MapManager.initialized then return end

    -- Update all loaded maps (for animations, etc.)
    -- OPTIMIZATION: Only update visible islands if camera provided
    for _, mapData in ipairs(MapManager.maps) do
        if mapData.map then
            local shouldUpdate = true

            -- Camera culling: skip updates for off-screen islands
            if camera then
                local camX, camY = camera:getPosition()
                local camScale = camera:getScale()
                local screenW, screenH = love.graphics.getDimensions()
                local viewWidth = screenW / camScale
                local viewHeight = screenH / camScale

                -- Check if island is visible
                local isVisible = not (
                    mapData.x + mapData.width < camX - viewWidth/2 or
                    mapData.x > camX + viewWidth/2 or
                    mapData.y + mapData.height < camY - viewHeight/2 or
                    mapData.y > camY + viewHeight/2
                )

                shouldUpdate = isVisible
            end

            if shouldUpdate then
                TiledMapLoader.update(mapData.map, dt)
            end
        end
    end
end

---@param camera table|nil Optional camera for frustum culling
function MapManager.draw(camera)
    if not MapManager.initialized then return end

    local drawnCount = 0
    local culledCount = 0

    -- Draw all maps at their respective positions
    for _, mapData in ipairs(MapManager.maps) do
        if mapData.map then
            local shouldDraw = true

            -- OPTIMIZATION: Camera frustum culling - skip off-screen islands
            if camera then
                local camX, camY = camera:getPosition()
                local camScale = camera:getScale()
                local screenW, screenH = love.graphics.getDimensions()
                local viewWidth = screenW / camScale
                local viewHeight = screenH / camScale

                -- Add margin to prevent pop-in at screen edges
                local margin = 10

                -- Check if island intersects camera view
                local isVisible = not (
                    mapData.x + mapData.width < camX - viewWidth/2 - margin or
                    mapData.x > camX + viewWidth/2 + margin or
                    mapData.y + mapData.height < camY - viewHeight/2 - margin or
                    mapData.y > camY + viewHeight/2 + margin
                )

                shouldDraw = isVisible

                if not shouldDraw then
                    culledCount = culledCount + 1
                end
            end

            if shouldDraw then
                love.graphics.push()
                love.graphics.translate(mapData.x, mapData.y)

                -- Draw the map using TiledMapLoader
                TiledMapLoader.draw(mapData.map)

                love.graphics.pop()
                drawnCount = drawnCount + 1
            end
        end
    end

    -- Store culling stats for debugging
    MapManager.lastDrawnCount = drawnCount
    MapManager.lastCulledCount = culledCount

    -- Draw bridges
    MapManager.drawBridges()
end

---Draw all bridges between islands
function MapManager.drawBridges()
    if #MapManager.bridges == 0 then return end

    -- Draw bridges as thick colored rectangles
    for _, bridge in ipairs(MapManager.bridges) do
        -- Set bright yellow color for visibility
        love.graphics.setColor(1, 1, 0, 1)

        if bridge.direction == "horizontal" then
            -- Horizontal bridge: 32 pixels tall, spanning the width
            love.graphics.rectangle("fill", bridge.x, bridge.y - 16, bridge.width, 32)
        elseif bridge.direction == "vertical" then
            -- Vertical bridge: 32 pixels wide, spanning the height
            love.graphics.rectangle("fill", bridge.x - 16, bridge.y, 32, bridge.height)
        end

        -- Draw debug outline
        love.graphics.setColor(1, 0, 0, 1)
        if bridge.direction == "horizontal" then
            love.graphics.rectangle("line", bridge.x, bridge.y - 16, bridge.width, 32)
        elseif bridge.direction == "vertical" then
            love.graphics.rectangle("line", bridge.x - 16, bridge.y, 32, bridge.height)
        end
    end

    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

---@param mapId string The ID of the map to retrieve
---@return table|nil Map data or nil if not found
function MapManager.getMap(mapId)
    for _, mapData in ipairs(MapManager.maps) do
        if mapData.id == mapId then
            return mapData
        end
    end
    return nil
end

---@return table List of all loaded maps
function MapManager.getAllMaps()
    return MapManager.maps
end

---@return table List of all bridges
function MapManager.getBridges()
    return MapManager.bridges
end

function MapManager.unload()
    -- Clean up all maps
    for _, mapData in ipairs(MapManager.maps) do
        -- Unload map resources if needed
        if mapData.map then
            TiledMapLoader.clearCache(mapData.definition.mapPath)
        end
    end

    MapManager.maps = {}
    MapManager.baseIsland = nil
    MapManager.levelConfig = nil
    MapManager.bridges = {}
    MapManager.initialized = false

    print("[MapManager] Unloaded all maps")
end

return MapManager
