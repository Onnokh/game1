-- MapManager.lua
-- Complete world loading and management system
-- Handles: level loading, island generation, pathfinding, collisions, entities, camera

local MapManager = {}

-- Dependencies (lazy loaded to avoid circular dependencies)
local TiledMapLoader = nil
local Player = nil
local Reactor = nil
local Tree = nil
local BridgeManager = nil
local GameConstants = nil

-- Internal state
MapManager.maps = {}
MapManager.baseIsland = nil
MapManager.levelConfig = nil
MapManager.initialized = false
MapManager.lastDrawnCount = 0
MapManager.lastCulledCount = 0

---=============================================================================
--- ISLAND GENERATION (from old IslandGenerator)
---=============================================================================

local function setRandomSeed()
    if os and os.time then
        math.randomseed(os.time())
    end
end

local function weightedRandom(pool)
    if not pool or #pool == 0 then return nil end

    local totalWeight = 0
    for _, item in ipairs(pool) do
        totalWeight = totalWeight + (item.weight or 1)
    end

    local randomValue = math.random() * totalWeight
    local currentWeight = 0

    for _, item in ipairs(pool) do
        currentWeight = currentWeight + (item.weight or 1)
        if randomValue <= currentWeight then
            return item
        end
    end

    return pool[1]
end

local function islandsOverlap(island1, island2, tolerance)
    tolerance = tolerance or 0
    return island1.x < island2.x + island2.width - tolerance and
           island1.x + island1.width > island2.x + tolerance and
           island1.y < island2.y + island2.height - tolerance and
           island1.y + island1.height > island2.y + tolerance
end

---Generate random islands around base island
---@param levelConfig table Level configuration
---@param baseIsland table Base island data
---@return table Array of generated islands
local function generateIslands(levelConfig, baseIsland)
    setRandomSeed()

    local islandPool = levelConfig.generation.islandPool
    local generation = levelConfig.generation

    local islandCount = math.random(generation.islandCount.min, generation.islandCount.max)
    local placementMode = generation.placement.distributionMode or "tile-based"

    print(string.format("[MapManager] Generating %d islands (%s placement)", islandCount, placementMode))

    local generated = {}
    local allIslands = {baseIsland}

    for i = 1, islandCount do
        local islandDef = weightedRandom(islandPool)
        if not islandDef then break end

        local islandMap = TiledMapLoader.load(islandDef.mapPath)
        if not islandMap then
            print(string.format("[MapManager] ERROR: Failed to load island map: %s", islandDef.mapPath))
            break
        end

        local island = {
            id = islandDef.id,
            definition = islandDef,
            map = islandMap,
            x = 0,
            y = 0,
            width = islandMap.width * islandMap.tilewidth,
            height = islandMap.height * islandMap.tileheight
        }

        -- Place island adjacent to existing islands
        local placed = false
        local maxAttempts = 100

        for attempt = 1, maxAttempts do
            if placementMode == "tile-based" or placementMode == "scattered" then
                local targetIsland = allIslands[math.random(#allIslands)]
                local edges = {"north", "south", "east", "west"}
                local edge = edges[math.random(#edges)]

                if edge == "north" then
                    island.x = targetIsland.x
                    island.y = targetIsland.y - island.height
                elseif edge == "south" then
                    island.x = targetIsland.x
                    island.y = targetIsland.y + targetIsland.height
                elseif edge == "east" then
                    island.x = targetIsland.x + targetIsland.width
                    island.y = targetIsland.y
                elseif edge == "west" then
                    island.x = targetIsland.x - island.width
                    island.y = targetIsland.y
                end

                -- Check for overlaps
                local hasOverlap = false
                for _, existingIsland in ipairs(allIslands) do
                    if islandsOverlap(island, existingIsland, 0) then
                        hasOverlap = true
                        break
                    end
                end

                if not hasOverlap then
                    print(string.format("[MapManager] Placed %s at (%d, %d) [%s edge]",
                        islandDef.name, island.x, island.y, edge))
                    placed = true
                    break
                end
            end
        end

        if placed then
            table.insert(generated, island)
            table.insert(allIslands, island)
        end
    end

    return generated
end

---=============================================================================
--- WORLD BUILDING (from old WorldLoader)
---=============================================================================

---Calculate world bounds and apply grid-aligned offset to all islands
---@param tileSize number Tile size in pixels
---@return table World bounds with offset, camera bounds
local function calculateWorldBounds(tileSize)
    local minX, minY = 0, 0
    local maxX, maxY = 0, 0

    for _, island in ipairs(MapManager.maps) do
        minX = math.min(minX, island.x)
        minY = math.min(minY, island.y)
        maxX = math.max(maxX, island.x + island.width)
        maxY = math.max(maxY, island.y + island.height)
    end

    -- Add padding
    local padding = 500
    minX = minX - padding
    minY = minY - padding
    maxX = maxX + padding
    maxY = maxY + padding

    -- Calculate grid-aligned offset
    local offsetX = math.ceil(-minX / tileSize) * tileSize
    local offsetY = math.ceil(-minY / tileSize) * tileSize

    -- Adjust all island positions
    for _, island in ipairs(MapManager.maps) do
        island.x = island.x + offsetX
        island.y = island.y + offsetY
    end

    local camWidth = maxX - minX
    local camHeight = maxY - minY

    print(string.format("[MapManager] World offset: (%.0f, %.0f)", offsetX, offsetY))
    print(string.format("[MapManager] Camera bounds: (0, 0) to (%.0f, %.0f)", camWidth, camHeight))

    return {
        offsetX = offsetX,
        offsetY = offsetY,
        cameraWidth = camWidth,
        cameraHeight = camHeight
    }
end

---Build pathfinding grid from all islands
---@param tileSize number Tile size in pixels
---@param camWidth number Camera width
---@param camHeight number Camera height
---@return table Pathfinding grid data
local function buildPathfindingGrid(tileSize, camWidth, camHeight)
    local gridStart = love.timer.getTime()

    local worldWidth = math.ceil(camWidth / tileSize)
    local worldHeight = math.ceil(camHeight / tileSize)

    -- Pre-allocate grid
    local world = {}
    local emptyTile = { walkable = false, type = 0 }
    for x = 1, worldWidth do
        world[x] = {}
        for y = 1, worldHeight do
            world[x][y] = emptyTile
        end
    end

    print(string.format("[MapManager] Pathfinding grid: %dx%d tiles (%.2fs)",
        worldWidth, worldHeight, love.timer.getTime() - gridStart))

    -- Cache collision grids by map path
    local collisionGridCache = {}

    -- Mark walkable tiles from each island
    for _, island in ipairs(MapManager.maps) do
        local islandMap = island.map
        local mapPath = island.definition.mapPath

        local islandCollisionGrid = collisionGridCache[mapPath]
        if not islandCollisionGrid then
            islandCollisionGrid = TiledMapLoader.parseCollisionGrid(
                islandMap,
                islandMap.width,
                islandMap.height
            )
            collisionGridCache[mapPath] = islandCollisionGrid
        end

        local walkableTileCount = 0
        for localX = 1, islandMap.width do
            for localY = 1, islandMap.height do
                local tileData = islandCollisionGrid[localX][localY]

                if tileData and tileData.gid and tileData.gid > 0 then
                    local worldTileX = math.floor(island.x / tileSize) + localX
                    local worldTileY = math.floor(island.y / tileSize) + localY

                    if worldTileX >= 1 and worldTileX <= worldWidth and
                       worldTileY >= 1 and worldTileY <= worldHeight then
                        -- Store ALL tiles (walkable and blocked)
                        world[worldTileX][worldTileY] = {
                            walkable = tileData.walkable,
                            type = tileData.type,
                            gid = tileData.gid
                        }
                        if tileData.walkable then
                            walkableTileCount = walkableTileCount + 1
                        end
                    end
                end
            end
        end

        print(string.format("  Island '%s': %d walkable tiles marked (%.0f, %.0f)",
            island.definition.name, walkableTileCount, island.x, island.y))
    end

    return {
        grid = world,
        width = worldWidth,
        height = worldHeight
    }
end

---Create collision bodies from completed world grid (includes islands AND bridges)
---@param worldGrid table The completed world pathfinding grid
---@param gridWidth number Grid width in tiles
---@param gridHeight number Grid height in tiles
---@param tileSize number Tile size in pixels
---@param physicsWorld love.World Physics world
---@return table Array of collision bodies
local function createCollisionBodiesFromWorldGrid(worldGrid, gridWidth, gridHeight, tileSize, physicsWorld)
    local collisionStart = love.timer.getTime()

    -- Convert world grid to collision grid format for TiledMapLoader
    local collisionGrid = {}
    for x = 1, gridWidth do
        collisionGrid[x] = {}
        for y = 1, gridHeight do
            local tile = worldGrid[x] and worldGrid[x][y]
            if tile then
                collisionGrid[x][y] = {
                    type = tile.type or 0,
                    gid = tile.gid or 0,
                    walkable = tile.walkable or false
                }
            else
                collisionGrid[x][y] = {
                    type = 0,
                    gid = 0,
                    walkable = false
                }
            end
        end
    end

    -- Generate collision bodies from the complete world grid
    local collisionBodies = TiledMapLoader.createCollisionBodies(
        {
            collisionGrid = collisionGrid,
            width = gridWidth,
            height = gridHeight,
            tileSize = tileSize
        },
        physicsWorld,
        0, -- No offset, world grid is already in world coordinates
        0
    )

    print(string.format("[MapManager] Collision setup took %.2fs", love.timer.getTime() - collisionStart))
    print(string.format("[MapManager] Total collision bodies: %d (from world grid)", #collisionBodies))

    return collisionBodies
end

---Spawn entities from all islands
---@param ecsWorld World ECS world
---@param physicsWorld love.World Physics world
---@return Entity Player entity
local function spawnEntities(ecsWorld, physicsWorld)
    local spawnStart = love.timer.getTime()
    local playerEntity = nil

    for _, island in ipairs(MapManager.maps) do
        local islandMap = island.map
        local islandX = island.x
        local islandY = island.y

        local objects = TiledMapLoader.parseObjects(islandMap)

        -- Spawn player at base island spawn point
        if objects.spawn and not playerEntity and island.id == "base" then
            playerEntity = Player.create(islandX + objects.spawn.x, islandY + objects.spawn.y, ecsWorld, physicsWorld)
        end

        -- Spawn reactors
        for _, obj in ipairs(objects.reactors or {}) do
            Reactor.create(islandX + obj.x, islandY + obj.y - obj.height, ecsWorld, physicsWorld)
        end

        -- Spawn other objects
        for _, obj in ipairs(objects.other or {}) do
            if obj.name == "Tree" then
                Tree.create(islandX + obj.x, islandY + obj.y - obj.height, ecsWorld, physicsWorld)
            end
        end
    end

    -- Fallback: spawn player at center of base island
    if not playerEntity and MapManager.baseIsland then
        local centerX = MapManager.baseIsland.x + MapManager.baseIsland.width / 2
        local centerY = MapManager.baseIsland.y + MapManager.baseIsland.height / 2
        playerEntity = Player.create(centerX, centerY, ecsWorld, physicsWorld)
    end

    print(string.format("[MapManager] Entity spawning took %.2fs", love.timer.getTime() - spawnStart))

    return playerEntity
end

---Setup camera with proper bounds
---@param camWidth number Camera width
---@param camHeight number Camera height
---@param playerEntity Entity Player entity
---@return table Camera object
local function setupCamera(camWidth, camHeight, playerEntity)
    local gamera = require("lib.gamera")
    local camera = gamera.new(0, 0, camWidth, camHeight)

    if playerEntity then
        local position = playerEntity:getComponent("Position")
        if position then
            camera:setPosition(position.x, position.y)
        end
    end

    camera:setScale(GameConstants.CAMERA_SCALE)
    print(string.format("[MapManager] Camera positioned at (%.2f, %.2f)", camera:getPosition()))

    return camera
end

---=============================================================================
--- PUBLIC API
---=============================================================================

---Load a complete world from a level configuration
---@param levelPath string Path to level config (e.g., "src/levels/level1")
---@param physicsWorld love.World Physics world for collision bodies
---@param ecsWorld World ECS world for entity spawning
---@return table World data containing grid, dimensions, camera bounds, player, etc.
function MapManager.load(levelPath, physicsWorld, ecsWorld)
    local startTime = love.timer.getTime()

    -- Load dependencies FIRST (lazy loading to avoid circular dependencies)
    -- These must be loaded before any function that uses them is called
    if not TiledMapLoader then
        TiledMapLoader = require("src.utils.tiled")
    end
    if not Player then
        Player = require("src.entities.Player.Player")
    end
    if not Reactor then
        Reactor = require("src.entities.Reactor.Reactor")
    end
    if not Tree then
        Tree = require("src.entities.Decoration.Tree")
    end
    if not BridgeManager then
        BridgeManager = require("src.core.managers.BridgeManager")
    end
    if not GameConstants then
        GameConstants = require("src.constants")
    end

    -- Clear previous state
    MapManager.maps = {}
    MapManager.baseIsland = nil
    MapManager.levelConfig = nil
    MapManager.initialized = false

    -- Load level configuration
    local levelModule = require(levelPath:gsub("/", "."))
    MapManager.levelConfig = levelModule

    print("[MapManager] Loading level: " .. levelModule.name)

    -- Load base island
    local baseIslandDef = levelModule.baseIsland
    print("[MapManager] Loading base island: " .. baseIslandDef.name)

    local baseMap = TiledMapLoader.load(baseIslandDef.mapPath)
    if not baseMap then
        error("[MapManager] ERROR: Failed to load base island map")
    end

    local baseWidth = baseMap.width * baseMap.tilewidth
    local baseHeight = baseMap.height * baseMap.tileheight
    local tileSize = baseMap.tilewidth

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

    -- Generate additional islands
    local generatedIslands = generateIslands(levelModule, MapManager.baseIsland)
    for _, islandData in ipairs(generatedIslands) do
        if islandData.map then
            table.insert(MapManager.maps, islandData)
        end
    end

    print(string.format("[MapManager] Loaded %d islands total", #MapManager.maps))

    -- Calculate world bounds and apply offsets
    local worldBounds = calculateWorldBounds(tileSize)

    -- Build pathfinding grid
    local pathfindingGrid = buildPathfindingGrid(tileSize, worldBounds.cameraWidth, worldBounds.cameraHeight)

    -- Initialize BridgeManager and add bridges to world grid
    BridgeManager.initialize(MapManager.maps, tileSize, pathfindingGrid)
    BridgeManager.markBridgeTilesWalkable(pathfindingGrid.grid)

    -- Create collision bodies from the COMPLETED world grid (includes bridges)
    local collisionBodies = createCollisionBodiesFromWorldGrid(
        pathfindingGrid.grid,
        pathfindingGrid.width,
        pathfindingGrid.height,
        tileSize,
        physicsWorld
    )

    -- Spawn entities
    local playerEntity = spawnEntities(ecsWorld, physicsWorld)

    -- Setup camera
    local camera = setupCamera(worldBounds.cameraWidth, worldBounds.cameraHeight, playerEntity)

    MapManager.initialized = true

    local totalTime = love.timer.getTime() - startTime
    print(string.format("[MapManager] ===== TOTAL LOAD TIME: %.2fs =====", totalTime))

    return {
        grid = pathfindingGrid.grid,
        gridWidth = pathfindingGrid.width,
        gridHeight = pathfindingGrid.height,
        tileSize = tileSize,
        camera = camera,
        cameraBounds = worldBounds,
        playerEntity = playerEntity,
        collisionBodies = collisionBodies
    }
end

---Update all islands
---@param dt number Delta time
---@param camera table|nil Optional camera for culling
function MapManager.update(dt, camera)
    if not MapManager.initialized then return end

    for _, mapData in ipairs(MapManager.maps) do
        if mapData.map then
            local shouldUpdate = true

            if camera then
                local camX, camY = camera:getPosition()
                local camScale = camera:getScale()
                local screenW, screenH = love.graphics.getDimensions()
                local viewWidth = screenW / camScale
                local viewHeight = screenH / camScale

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

---Draw all islands
---@param camera table|nil Optional camera for frustum culling
function MapManager.draw(camera)
    if not MapManager.initialized then return end

    local drawnCount = 0
    local culledCount = 0

    for _, mapData in ipairs(MapManager.maps) do
        if mapData.map then
            local shouldDraw = true

            if camera then
                local camX, camY = camera:getPosition()
                local camScale = camera:getScale()
                local screenW, screenH = love.graphics.getDimensions()
                local viewWidth = screenW / camScale
                local viewHeight = screenH / camScale
                local margin = 10

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
                TiledMapLoader.draw(mapData.map)
                love.graphics.pop()
                drawnCount = drawnCount + 1
            end
        end
    end

    MapManager.lastDrawnCount = drawnCount
    MapManager.lastCulledCount = culledCount
end

---Get all loaded maps
---@return table List of all maps
function MapManager.getAllMaps()
    return MapManager.maps
end

---Unload all maps
function MapManager.unload()
    for _, mapData in ipairs(MapManager.maps) do
        if mapData.map then
            TiledMapLoader.clearCache(mapData.definition.mapPath)
        end
    end

    -- Unload BridgeManager
    if BridgeManager then
        BridgeManager.unload()
    end

    MapManager.maps = {}
    MapManager.baseIsland = nil
    MapManager.levelConfig = nil
    MapManager.initialized = false

    print("[MapManager] Unloaded all maps")
end

return MapManager
