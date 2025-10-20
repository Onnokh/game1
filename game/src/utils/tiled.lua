-- TiledMapLoader.lua
-- Complete Tiled map handling: loading, rendering, collision parsing, object extraction
-- Uses Cartographer library for Tiled map support

local TiledMapLoader = {}

-- Cache loaded maps to avoid reloading
local mapCache = {}
local cartographer = require("lib.cartographer")

---=============================================================================
--- MAP LOADING (Cartographer)
---=============================================================================

---Load a Tiled map file
---@param mapPath string Path to the Tiled map file (.lua or .tmx)
---@return table Loaded map instance
function TiledMapLoader.load(mapPath)
    -- Check cache first
    if mapCache[mapPath] then
        return mapCache[mapPath]
    end

    -- Verify file exists
    local fileInfo = love.filesystem.getInfo(mapPath)
    if not fileInfo then
        print("[TiledMapLoader] ERROR: File not found: " .. mapPath)
        return nil
    end

    -- Read and fix paths
    local content = love.filesystem.read(mapPath)
    if not content then
        print("[TiledMapLoader] ERROR: Could not read map file: " .. mapPath)
        return nil
    end

    -- Fix relative image paths (../../../ -> resources/)
    content = content:gsub('%.%.%/%.%.%/%.%.%/', 'resources/')

    -- Write to temporary file
    local tempPath = "temp_map_fixed.lua"
    love.filesystem.write(tempPath, content)

    -- Load with Cartographer
    local success, map = pcall(function()
        return cartographer.load(tempPath)
    end)

    -- Clean up temp file
    love.filesystem.remove(tempPath)

    if not success then
        print("[TiledMapLoader] ERROR loading map: " .. mapPath)
        print("[TiledMapLoader] Error: " .. tostring(map))
        return nil
    end

    -- Set pixel-perfect filtering
    if map and map._images then
        for _, image in pairs(map._images) do
            image:setFilter("nearest", "nearest")
        end
    end

    mapCache[mapPath] = map
    print("[TiledMapLoader] Loaded map: " .. mapPath)
    return map
end

---Draw a map (tile layers only, skip object layers)
---@param map table The map instance to draw
---@param camera table|nil Optional camera for view culling
function TiledMapLoader.draw(map, camera)
    if not map then return end

    -- Temporarily hide all object layers to prevent Cartographer from drawing them
    -- Object layers are handled by the game's entity system
    local hiddenLayers = {}
    if map.layers then
        for i, layer in ipairs(map.layers) do
            if layer.type == "objectgroup" then
                layer.visible = false
                table.insert(hiddenLayers, i)
            end
        end
    end

    -- Draw the map (only tile layers will be visible)
    if map.draw then
        map:draw()
    end

    -- Restore object layer visibility
    for _, layerIndex in ipairs(hiddenLayers) do
        if map.layers[layerIndex] then
            map.layers[layerIndex].visible = true
        end
    end
end

---Update a map (for animations)
---@param map table The map instance to update
---@param dt number Delta time
function TiledMapLoader.update(map, dt)
    if not map then return end
    if map.update then
        map:update(dt)
    end
end

---Clear map cache
---@param mapPath string|nil Path to clear from cache, or nil to clear all
function TiledMapLoader.clearCache(mapPath)
    if mapPath then
        mapCache[mapPath] = nil
    else
        mapCache = {}
    end
end

---=============================================================================
--- COLLISION PARSING
---=============================================================================

---Parse collision grid from tile layer
---@param tiledMap table Cartographer map instance
---@param width number Map width in tiles
---@param height number Map height in tiles
---@return table Collision grid [x][y] with gid, walkable
function TiledMapLoader.parseCollisionGrid(tiledMap, width, height)
    local grid = {}

    -- Find Walkable and Background layers by name
    local walkableLayer = nil
    local backgroundLayer = nil

    for _, layer in ipairs(tiledMap.layers) do
        if layer.type == "tilelayer" then
            if layer.name == "Walkable" then
                walkableLayer = layer
            elseif layer.name == "Background" then
                backgroundLayer = layer
            end
        end
    end

    if not walkableLayer then
        print("[TiledMapLoader] WARNING: No 'Walkable' layer found in map")
        return grid
    end

    local walkableCount = 0
    for y = 1, height do
        for x = 1, width do
            if not grid[x] then grid[x] = {} end

            local walkableGid = walkableLayer.data[(y - 1) * width + x]
            local backgroundGid = backgroundLayer and backgroundLayer.data[(y - 1) * width + x] or 0

            -- A tile is walkable ONLY if Walkable layer has non-zero GID
            local isWalkable = (walkableGid ~= nil and walkableGid > 0)

            -- Store the GID (prefer walkable, fallback to background for rendering)
            local gid = walkableGid and walkableGid > 0 and walkableGid or backgroundGid

            grid[x][y] = {
                gid = gid,
                walkable = isWalkable
            }

            if isWalkable then
                walkableCount = walkableCount + 1
            end
        end
    end

    print(string.format("[TiledMapLoader] Parsed grid %dx%d: %d walkable tiles",
        width, height, walkableCount))

    return grid
end

---Get debug info for a tile at world coordinates
---@param worldX number World X coordinate
---@param worldY number World Y coordinate
---@param collisionGrid table Collision grid
---@param tileSize number Tile size in pixels
---@return table|nil Tile debug info
function TiledMapLoader.getTileDebugInfo(worldX, worldY, collisionGrid, tileSize)
    local CoordinateUtils = require("src.utils.coordinates")
    local tileX, tileY = CoordinateUtils.worldToGrid(worldX, worldY)

    if not collisionGrid[tileX] or not collisionGrid[tileX][tileY] then
        return nil
    end

    local tileData = collisionGrid[tileX][tileY]

    return {
        gid = tileData.gid,
        tileX = tileX,
        tileY = tileY,
        walkable = tileData.walkable
    }
end

---=============================================================================
--- OBJECT PARSING
---=============================================================================

---Parse objects from object layers
---@param tiledMap table Cartographer map instance
---@return table Categorized objects {spawn, enemies, other}
function TiledMapLoader.parseObjects(tiledMap)
    local objects = {
        spawn = nil,
        enemies = {},
        other = {}
    }

    if not tiledMap.layers then return objects end

    for _, layer in ipairs(tiledMap.layers) do
        if layer.type == "objectgroup" and layer.objects then
            for _, obj in ipairs(layer.objects) do
                if obj.visible ~= false then
                    if obj.name == "Spawn" then
                        objects.spawn = { x = obj.x, y = obj.y }
                    elseif obj.name:match("^Enemy") or obj.type == "enemy" then
                        table.insert(objects.enemies, obj)
                    else
                        table.insert(objects.other, obj)
                    end
                end
            end
        end
    end

    return objects
end

---=============================================================================
--- COLLISION BODY CREATION
---=============================================================================

---Create physics collision bodies from map data using rectangle merging
---@param mapData table Map data with collision grid
---@param physicsWorld love.World Physics world to create bodies in
---@param offsetX number X offset for this island (default 0)
---@param offsetY number Y offset for this island (default 0)
---@return table Array of collision bodies
function TiledMapLoader.createCollisionBodies(mapData, physicsWorld, offsetX, offsetY)
    local collisionBodies = {}
    local collisionGrid = mapData.collisionGrid
    local worldWidth = mapData.width
    local worldHeight = mapData.height
    local tileSize = mapData.tileSize

    offsetX = offsetX or 0
    offsetY = offsetY or 0

    if not physicsWorld or not collisionGrid then
        return collisionBodies
    end

    -- Create visited grid
    local visited = {}
    for x = 1, worldWidth do
        visited[x] = {}
        for y = 1, worldHeight do
            visited[x][y] = false
        end
    end

    -- Helper: Check if tile is blocked
    local function isBlocked(x, y)
        if x < 1 or x > worldWidth or y < 1 or y > worldHeight then
            return false
        end
        local tile = collisionGrid[x] and collisionGrid[x][y]
        return tile and not tile.walkable
    end

    -- Helper: Find rectangle width
    local function findRectWidth(startX, startY)
        local width = 0
        for x = startX, worldWidth do
            if isBlocked(x, startY) and not visited[x][startY] then
                width = width + 1
            else
                break
            end
        end
        return width
    end

    -- Helper: Check if rectangle can extend down
    local function canExtendDown(startX, startY, width, currentHeight)
        local nextY = startY + currentHeight
        if nextY > worldHeight then
            return false
        end

        for x = startX, startX + width - 1 do
            if not isBlocked(x, nextY) or visited[x][nextY] then
                return false
            end
        end
        return true
    end

    -- Greedy rectangle merging algorithm
    for y = 1, worldHeight do
        for x = 1, worldWidth do
            if isBlocked(x, y) and not visited[x][y] then
                local width = findRectWidth(x, y)

                local height = 1
                while canExtendDown(x, y, width, height) do
                    height = height + 1
                end

                -- Mark tiles as visited
                for rx = x, x + width - 1 do
                    for ry = y, y + height - 1 do
                        visited[rx][ry] = true
                    end
                end

                -- Create physics body
                local rectWidth = width * tileSize
                local rectHeight = height * tileSize
                local centerX = offsetX + (x - 1) * tileSize + rectWidth / 2
                local centerY = offsetY + (y - 1) * tileSize + rectHeight / 2

                local body = love.physics.newBody(physicsWorld, centerX, centerY, "static")
                local shape = love.physics.newRectangleShape(rectWidth, rectHeight)
                local fixture = love.physics.newFixture(body, shape)
                fixture:setRestitution(0.1)
                fixture:setFriction(0.8)

                table.insert(collisionBodies, {
                    body = body,
                    fixture = fixture,
                    shape = shape,
                    x = x,
                    y = y,
                    width = width,
                    height = height
                })
            end
        end
    end

    return collisionBodies
end

return TiledMapLoader
