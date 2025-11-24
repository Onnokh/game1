-- MapManager.lua
-- Simple world loading and management system
-- Handles: level loading, pathfinding, collisions, entities, camera

local MapManager = {}

-- Dependencies (lazy loaded to avoid circular dependencies)
local Player = nil
local Tree = nil
local Shop = nil
local Crystal = nil
local Event = nil
local GameConstants = nil
local MobManager = nil

-- Internal state
MapManager.levelConfig = nil
MapManager.initialized = false
MapManager.worldWidth = 0
MapManager.worldHeight = 0
MapManager.tileSize = 32

---=============================================================================
--- WORLD BUILDING
---=============================================================================

---Build pathfinding grid for 600x600 world
---@param worldWidth number World width in pixels
---@param worldHeight number World height in pixels
---@param tileSize number Tile size in pixels
---@return table Pathfinding grid data
local function buildPathfindingGrid(worldWidth, worldHeight, tileSize)
    local gridStart = love.timer.getTime()

    local gridWidth = math.ceil(worldWidth / tileSize)
    local gridHeight = math.ceil(worldHeight / tileSize)

    -- Pre-allocate grid
    local world = {}
    for x = 1, gridWidth do
        world[x] = {}
        for y = 1, gridHeight do
            -- Walls around edges (non-walkable), everything else walkable
            local isWall = (x == 1 or x == gridWidth or y == 1 or y == gridHeight)
            world[x][y] = {
                walkable = not isWall,
                gid = isWall and 0 or 1  -- 0 for walls, 1 for walkable tiles
            }
        end
    end

    print(string.format("[MapManager] Pathfinding grid: %dx%d tiles (%.2fs)",
        gridWidth, gridHeight, love.timer.getTime() - gridStart))

    return {
        grid = world,
        width = gridWidth,
        height = gridHeight
    }
end

---Create collision bodies for edge walls
---@param worldWidth number World width in pixels
---@param worldHeight number World height in pixels
---@param tileSize number Tile size in pixels
---@param physicsWorld love.World Physics world
---@return table Array of collision bodies
local function createCollisionBodies(worldWidth, worldHeight, tileSize, physicsWorld)
    local collisionStart = love.timer.getTime()
    local collisionBodies = {}

    if not physicsWorld then
        return collisionBodies
    end

    -- Create walls around the edges
    -- Top wall
    local topBody = love.physics.newBody(physicsWorld, worldWidth / 2, tileSize / 2, "static")
    local topShape = love.physics.newRectangleShape(worldWidth, tileSize)
    local topFixture = love.physics.newFixture(topBody, topShape)
    topFixture:setRestitution(0.1)
    topFixture:setFriction(0.8)
    table.insert(collisionBodies, { body = topBody, fixture = topFixture, shape = topShape })

    -- Bottom wall
    local bottomBody = love.physics.newBody(physicsWorld, worldWidth / 2, worldHeight - tileSize / 2, "static")
    local bottomShape = love.physics.newRectangleShape(worldWidth, tileSize)
    local bottomFixture = love.physics.newFixture(bottomBody, bottomShape)
    bottomFixture:setRestitution(0.1)
    bottomFixture:setFriction(0.8)
    table.insert(collisionBodies, { body = bottomBody, fixture = bottomFixture, shape = bottomShape })

    -- Left wall
    local leftBody = love.physics.newBody(physicsWorld, tileSize / 2, worldHeight / 2, "static")
    local leftShape = love.physics.newRectangleShape(tileSize, worldHeight)
    local leftFixture = love.physics.newFixture(leftBody, leftShape)
    leftFixture:setRestitution(0.1)
    leftFixture:setFriction(0.8)
    table.insert(collisionBodies, { body = leftBody, fixture = leftFixture, shape = leftShape })

    -- Right wall
    local rightBody = love.physics.newBody(physicsWorld, worldWidth - tileSize / 2, worldHeight / 2, "static")
    local rightShape = love.physics.newRectangleShape(tileSize, worldHeight)
    local rightFixture = love.physics.newFixture(rightBody, rightShape)
    rightFixture:setRestitution(0.1)
    rightFixture:setFriction(0.8)
    table.insert(collisionBodies, { body = rightBody, fixture = rightFixture, shape = rightShape })

    print(string.format("[MapManager] Collision setup took %.2fs", love.timer.getTime() - collisionStart))
    print(string.format("[MapManager] Total collision bodies: %d (edge walls)", #collisionBodies))

    return collisionBodies
end

---Spawn entities at fixed coordinates
---@param ecsWorld World ECS world
---@param physicsWorld love.World Physics world
---@param spawns table Spawn coordinates from level config
---@return Entity|nil Player entity (nil if no spawn point found)
local function spawnEntities(ecsWorld, physicsWorld, spawns)
    local spawnStart = love.timer.getTime()
    local playerEntity = nil

    -- Spawn player
    if spawns and spawns.player then
        playerEntity = Player.create(spawns.player.x, spawns.player.y, ecsWorld, physicsWorld)
        print(string.format("[MapManager] Player spawned at (%.0f, %.0f)", spawns.player.x, spawns.player.y))
    else
        -- Fallback: spawn at center
        playerEntity = Player.create(300, 300, ecsWorld, physicsWorld)
        print("[MapManager] Player spawned at default center (300, 300)")
    end

    -- Spawn other entities from spawns table
    -- Example: if spawns.shop then Shop.create(spawns.shop.x, spawns.shop.y, ecsWorld, physicsWorld) end
    -- Add more entity spawning here as needed

    print(string.format("[MapManager] Entity spawning took %.2fs", love.timer.getTime() - spawnStart))

    return playerEntity
end

---Setup camera with proper bounds
---@param worldWidth number World width
---@param worldHeight number World height
---@param playerEntity Entity|nil Player entity (nil when loading from save)
---@return table Camera object
local function setupCamera(worldWidth, worldHeight, playerEntity)
    local gamera = require("lib.gamera")

    local camera = gamera.new(0, 0, worldWidth, worldHeight)

    if playerEntity then
        local position = playerEntity:getComponent("Position")
        if position then
            camera:setPosition(position.x, position.y)
        end
    end

    -- Default camera scale is 1.0
    camera:setScale(1.0)

    print(string.format("[MapManager] Camera positioned at (%.2f, %.2f)", camera:getPosition()))
    print(string.format("[MapManager] World bounds: %dx%d", worldWidth, worldHeight))

    return camera
end

---=============================================================================
--- PUBLIC API
---=============================================================================

---Load a simple 600x600 world
---@param levelPath string Path to level configuration (e.g., "src/levels/level1")
---@param physicsWorld love.World Physics world for collision bodies
---@param ecsWorld World ECS world for entity spawning
---@param seed number|nil Optional random seed (unused for simple world, kept for API compatibility)
---@param skipEntitySpawn boolean|nil If true, skip entity spawning (used when loading from save)
---@return table World data containing grid, dimensions, camera bounds, player, etc.
function MapManager.load(levelPath, physicsWorld, ecsWorld, seed, skipEntitySpawn)
    local startTime = love.timer.getTime()

    -- Load dependencies FIRST (lazy loading to avoid circular dependencies)
    if not Player then
        Player = require("src.entities.Player.Player")
    end
    if not Tree then
        Tree = require("src.entities.Decoration.Tree")
    end
    if not Shop then
        Shop = require("src.entities.Shop.Shop")
    end
    if not Crystal then
        Crystal = require("src.entities.Crystal.Crystal")
    end
    if not Event then
        Event = require("src.entities.Event.Event")
    end
    if not GameConstants then
        GameConstants = require("src.constants")
    end
    if not MobManager then
        MobManager = require("src.core.managers.MobManager")
    end

    -- Clear previous state
    MapManager.levelConfig = nil
    MapManager.initialized = false
    MobManager.clear()

    -- Load level configuration
    local levelModule = require(levelPath:gsub("/", "."))
    MapManager.levelConfig = levelModule

    print("[MapManager] Loading level: " .. levelModule.name)

    -- Get world dimensions from level config
    local worldWidth = levelModule.worldWidth or 600
    local worldHeight = levelModule.worldHeight or 600
    local tileSize = GameConstants.TILE_SIZE

    MapManager.worldWidth = worldWidth
    MapManager.worldHeight = worldHeight
    MapManager.tileSize = tileSize

    print(string.format("[MapManager] Creating %dx%d world", worldWidth, worldHeight))

    -- Build pathfinding grid
    local pathfindingGrid = buildPathfindingGrid(worldWidth, worldHeight, tileSize)

    -- Create collision bodies (edge walls)
    local collisionBodies = createCollisionBodies(worldWidth, worldHeight, tileSize, physicsWorld)

    -- Spawn entities (skip if loading from save - SaveSystem will restore them)
    local playerEntity = nil
    if not skipEntitySpawn then
        playerEntity = spawnEntities(ecsWorld, physicsWorld, levelModule.spawns)
        print("[MapManager] Entities spawned")
    else
        print("[MapManager] Skipping entity spawn (loading from save)")
    end

    -- Setup camera (playerEntity will be nil if loading from save, updated later by SaveSystem)
    local camera = setupCamera(worldWidth, worldHeight, playerEntity)

    MapManager.initialized = true

    local totalTime = love.timer.getTime() - startTime
    print(string.format("[MapManager] ===== TOTAL LOAD TIME: %.2fs =====", totalTime))

    return {
        grid = pathfindingGrid.grid,
        gridWidth = pathfindingGrid.width,
        gridHeight = pathfindingGrid.height,
        tileSize = tileSize,
        camera = camera,
        cameraBounds = {
            offsetX = 0,
            offsetY = 0,
            cameraWidth = worldWidth,
            cameraHeight = worldHeight
        },
        playerEntity = playerEntity,
        collisionBodies = collisionBodies
    }
end

---Draw the simple world (colored tiles)
---@param camera table|nil Optional camera for culling (unused for simple world)
function MapManager.draw(camera)
    if not MapManager.initialized then return end

    local tileSize = MapManager.tileSize
    local worldWidth = MapManager.worldWidth
    local worldHeight = MapManager.worldHeight
    local gridWidth = math.ceil(worldWidth / tileSize)
    local gridHeight = math.ceil(worldHeight / tileSize)

    -- Color for walkable tiles: #ccd8db (RGB: 204, 216, 219)
    local walkableR, walkableG, walkableB = 204/255, 216/255, 219/255
    -- Color for walls: darker gray
    local wallR, wallG, wallB = 0.3, 0.3, 0.3

    -- Draw tiles, ensuring we only draw within the exact world bounds
    for x = 1, gridWidth do
        for y = 1, gridHeight do
            local isWall = (x == 1 or x == gridWidth or y == 1 or y == gridHeight)
            local pixelX = (x - 1) * tileSize
            local pixelY = (y - 1) * tileSize

            -- Calculate actual tile size (may be partial for edge tiles)
            local tileW = math.min(tileSize, worldWidth - pixelX)
            local tileH = math.min(tileSize, worldHeight - pixelY)

            if isWall then
                love.graphics.setColor(wallR, wallG, wallB, 1)
            else
                love.graphics.setColor(walkableR, walkableG, walkableB, 1)
            end

            love.graphics.rectangle("fill", pixelX, pixelY, tileW, tileH)
        end
    end

    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

---Update world (no-op for simple world)
---@param dt number Delta time
---@param camera table|nil Optional camera for culling
function MapManager.update(dt, camera)
    -- Simple world doesn't need updates
end

---Get all loaded maps (returns empty for simple world)
---@return table Empty list (for API compatibility)
function MapManager.getAllMaps()
    return {}
end

---Unload world
function MapManager.unload()
    -- Clear MobManager
    if MobManager then
        MobManager.clear()
    end

    MapManager.levelConfig = nil
    MapManager.initialized = false
    MapManager.worldWidth = 0
    MapManager.worldHeight = 0

    print("[MapManager] Unloaded world")
end

return MapManager
