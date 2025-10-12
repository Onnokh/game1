-- TiledMapLoader.lua
-- Complete Tiled map handling: loading, rendering, collision parsing, object extraction
-- Uses Cartographer library for Tiled map support

local TiledMapLoader = {}

-- Cache loaded maps to avoid reloading
local mapCache = {}
local cartographer = require("lib.cartographer")
local GameConstants = require("src.constants")

---=============================================================================
--- TILE TYPE CONSTANTS
---=============================================================================

TiledMapLoader.TILE_EMPTY = 0
TiledMapLoader.TILE_GRASS = 1
TiledMapLoader.TILE_BLOCKED = 3
TiledMapLoader.TILE_WORLDEDGE = 2

-- Convert blocked tile GIDs array to hash table for O(1) lookups
local BLOCKED_GIDS_LOOKUP = {}
for _, gid in ipairs(GameConstants.BLOCKED_TILE_GIDS) do
    BLOCKED_GIDS_LOOKUP[gid] = true
end

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

---Draw a map
---@param map table The map instance to draw
---@param camera table|nil Optional camera for view culling
function TiledMapLoader.draw(map, camera)
    if not map then return end
    if map.draw then
        map:draw()
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
--- TILE UTILITIES
---=============================================================================

---Get tile collision type from GID
---@param gid number Tile GID
---@return number Tile type constant
function TiledMapLoader.getTileType(gid)
    if gid == 0 then return TiledMapLoader.TILE_EMPTY end
    if BLOCKED_GIDS_LOOKUP[gid] then return TiledMapLoader.TILE_BLOCKED end
    return TiledMapLoader.TILE_GRASS
end

---Check if a tile type is walkable
---@param tileType number Tile type constant
---@return boolean True if walkable
function TiledMapLoader.isWalkable(tileType)
    return tileType == TiledMapLoader.TILE_GRASS
end

---Get tile type name for debugging
---@param tileType number Tile type constant
---@return string Tile type name
function TiledMapLoader.getTileTypeName(tileType)
    if tileType == TiledMapLoader.TILE_EMPTY then return "EMPTY" end
    if tileType == TiledMapLoader.TILE_GRASS then return "GRASS" end
    if tileType == TiledMapLoader.TILE_BLOCKED then return "BLOCKED" end
    if tileType == TiledMapLoader.TILE_WORLDEDGE then return "WORLDEDGE" end
    return "UNKNOWN"
end

---=============================================================================
--- COLLISION PARSING
---=============================================================================

---Parse collision grid from tile layer
---@param tiledMap table Cartographer map instance
---@param width number Map width in tiles
---@param height number Map height in tiles
---@return table Collision grid [x][y] with type, gid, walkable
function TiledMapLoader.parseCollisionGrid(tiledMap, width, height)
    local grid = {}
    local layer = tiledMap.layers and tiledMap.layers[1]

    if not layer or layer.type ~= "tilelayer" then
        print("[TiledMapLoader] WARNING: No tile layer found in map")
        return grid
    end

    local walkableCount = 0
    for y = 1, height do
        for x = 1, width do
            if not grid[x] then grid[x] = {} end
            local gid = layer.data[(y - 1) * width + x]

            -- A tile is walkable if it exists (gid > 0) and is not blocked
            local tileType = TiledMapLoader.getTileType(gid)
            local isWalkable = (gid ~= 0) and not BLOCKED_GIDS_LOOKUP[gid]

            grid[x][y] = {
                type = tileType,
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
    local tileTypeName = TiledMapLoader.getTileTypeName(tileData.type)

    return {
        gid = tileData.gid,
        tileType = tileData.type,
        tileTypeName = tileTypeName,
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
---@return table Categorized objects {spawn, enemies, reactors, other}
function TiledMapLoader.parseObjects(tiledMap)
    local objects = {
        spawn = nil,
        enemies = {},
        reactors = {},
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
                    elseif obj.name:match("^Reactor") or obj.type == "reactor" then
                        table.insert(objects.reactors, obj)
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
