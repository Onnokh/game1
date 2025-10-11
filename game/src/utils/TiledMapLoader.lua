-- OKH: Todo: Expand this whenever we add more objects to Tiled map

---@class TiledMapLoader
--- Simple utility for extracting data from Tiled maps loaded via Cartographer
local TiledMapLoader = {}

-- Tile type constants
TiledMapLoader.TILE_EMPTY = 0
TiledMapLoader.TILE_GRASS = 1
TiledMapLoader.TILE_WORLDEDGE = 2


-- Strategy: Mark most tiles as walkable, only block specific edge tiles
TiledMapLoader.GRASS_TILES = {}

-- Island maps: All non-zero tiles are walkable except specific edge markers
TiledMapLoader.WORLDEDGE_TILES = {}

-- Helper: Check if GID is walkable (everything except 0 and edge tiles)
function TiledMapLoader.isGidWalkable(gid)
  -- 0 = empty/void
  if gid == 0 then return false end

  -- Edge tiles (these are the borders in island maps)
  -- We'll mark specific edges if needed, but for now treat all as walkable
  -- since we're using physics boundaries instead
  return true
end
--- Check if a tile type is walkable
function TiledMapLoader.isWalkable(tileType)
  -- Only grass tiles are walkable, blocked and empty are not
  return tileType == TiledMapLoader.TILE_GRASS
end

--- Get tile type name for debugging
function TiledMapLoader.getTileTypeName(tileType)
  if tileType == TiledMapLoader.TILE_EMPTY then return "EMPTY" end
  if tileType == TiledMapLoader.TILE_GRASS then return "GRASS" end
  if tileType == TiledMapLoader.TILE_BLOCKED then return "BLOCKED" end
  if tileType == TiledMapLoader.TILE_WORLDEDGE then return "WORLDEDGE" end
  return "UNKNOWN"
end

-- Blocked tile GIDs (walls, obstacles, etc.)
local BLOCKED_GIDS = {
  [23] = true,
  [24] = true,
  [25] = true,
  [162] = true,
  [169] = true,
  [170] = true,
  [172] = true,
  [173] = true,
}

--- Get tile collision type from GID
function TiledMapLoader.getTileType(gid)
  -- Empty tiles (no tile) are non-walkable
  if gid == 0 then return TiledMapLoader.TILE_EMPTY end

  -- Check if this GID is a blocked tile (walls, obstacles)
  if BLOCKED_GIDS[gid] then
    return TiledMapLoader.TILE_BLOCKED
  end

  -- All other non-zero tiles are walkable (grass)
  return TiledMapLoader.TILE_GRASS
end

--- Parse collision grid from tile layer
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
      local tileType = TiledMapLoader.getTileType(gid)
      local isWalkable = TiledMapLoader.isWalkable(tileType)

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

  print(string.format("[TiledMapLoader] Parsed grid %dx%d: %d walkable tiles (first GID sample: %s)",
    width, height, walkableCount, tostring(layer.data[1])))

  return grid
end


--- Get debug info for a tile at world coordinates
function TiledMapLoader.getTileDebugInfo(worldX, worldY, collisionGrid, tileSize)
  local tileX = math.floor(worldX / tileSize) + 1
  local tileY = math.floor(worldY / tileSize) + 1

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

--- Parse objects from object layers
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

--- Normalize object position (Tiled objects use bottom-left origin for y)
local function normalizeObjectPosition(obj)
  return {
    x = obj.x,
    y = obj.y - (obj.height or 0),
    width = obj.width,
    height = obj.height,
    name = obj.name,
    type = obj.type,
    properties = obj.properties
  }
end

--- Load and parse all map data
function TiledMapLoader.loadMapData(tiledMap)
  local mapData = {
    width = tiledMap.width,
    height = tiledMap.height,
    tileSize = tiledMap.tilewidth,
    collisionGrid = {},
    spawnPoint = nil,
    objects = {}
  }

  mapData.collisionGrid = TiledMapLoader.parseCollisionGrid(
    tiledMap,
    mapData.width,
    mapData.height
  )

  local objects = TiledMapLoader.parseObjects(tiledMap)
  mapData.objects = objects
  mapData.spawnPoint = objects.spawn

  -- Hide the Objects layer so we don't render object tiles (we spawn entities instead)
  if tiledMap.layers then
    local objectsLayer = tiledMap:getLayer("Objects")
    if objectsLayer then
      objectsLayer.visible = false
    end
  end

  return mapData
end

--- Spawn entities from map objects using provided factory functions
-- @param mapData The map data returned from loadMapData
-- @param factories Table mapping object types to factory functions
--   Example: { reactors = function(obj) ... end, enemies = function(obj) ... end }
function TiledMapLoader.spawnEntities(mapData, factories)
  if not mapData or not mapData.objects then return end

  for objectType, objectList in pairs(mapData.objects) do
    local factory = factories[objectType]
    if factory and type(objectList) == "table" then
      -- Handle single object (like spawn point)
      if objectList.x then
        local normalized = normalizeObjectPosition(objectList)
        factory(normalized)
      -- Handle array of objects
      else
        for _, obj in ipairs(objectList) do
          local normalized = normalizeObjectPosition(obj)
          factory(normalized)
        end
      end
    end
  end
end

--- Create physics collision bodies from map data
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

  -- Default offsets to 0 if not provided
  offsetX = offsetX or 0
  offsetY = offsetY or 0

  if not physicsWorld or not collisionGrid then
    return collisionBodies
  end

  -- Create a visited grid to track which tiles we've processed
  local visited = {}
  for x = 1, worldWidth do
    visited[x] = {}
    for y = 1, worldHeight do
      visited[x][y] = false
    end
  end

  -- Helper: Check if tile is blocked (not walkable)
  local function isBlocked(x, y)
    if x < 1 or x > worldWidth or y < 1 or y > worldHeight then
      return false
    end
    local tile = collisionGrid[x] and collisionGrid[x][y]
    return tile and not tile.walkable
  end

  -- Helper: Find the maximum width of a rectangle starting at (startX, startY)
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

  -- Helper: Check if we can extend a rectangle down by one row
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

  -- Greedy rectangle merging: find largest possible rectangles
  for y = 1, worldHeight do
    for x = 1, worldWidth do
      if isBlocked(x, y) and not visited[x][y] then
        -- Find width of rectangle
        local width = findRectWidth(x, y)

        -- Try to extend height
        local height = 1
        while canExtendDown(x, y, width, height) do
          height = height + 1
        end

        -- Mark all tiles in this rectangle as visited
        for rx = x, x + width - 1 do
          for ry = y, y + height - 1 do
            visited[rx][ry] = true
          end
        end

        -- Create a physics body for this rectangle
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
