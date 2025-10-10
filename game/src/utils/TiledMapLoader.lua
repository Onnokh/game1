-- OKH: Todo: Expand this whenever we add more objects to Tiled map

---@class TiledMapLoader
--- Simple utility for extracting data from Tiled maps loaded via Cartographer
local TiledMapLoader = {}

-- Tile type constants
TiledMapLoader.TILE_EMPTY = 0
TiledMapLoader.TILE_GRASS = 1
TiledMapLoader.TILE_WORLDEDGE = 2


TiledMapLoader.GRASS_TILES = {
  327,328,329, 443, 444, 445, 446, 447, 453, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 480, 482, 483, 490, 497, 498, 505
}

TiledMapLoader.WORLDEDGE_TILES = {
  481, 488,489,490,491,492, 512,513
}
--- Check if a tile type is walkable
function TiledMapLoader.isWalkable(tileType)
  return tileType == TiledMapLoader.TILE_GRASS
end

--- Get tile type name for debugging
function TiledMapLoader.getTileTypeName(tileType)
  if tileType == TiledMapLoader.TILE_EMPTY then return "EMPTY" end
  if tileType == TiledMapLoader.TILE_GRASS then return "GRASS" end
  if tileType == TiledMapLoader.TILE_WORLDEDGE then return "WORLDEDGE" end
  return "UNKNOWN"
end

--- Get tile collision type from GID
function TiledMapLoader.getTileType(gid)
  -- Empty tiles (no tile) are non-walkable
  if gid == 0 then return TiledMapLoader.TILE_EMPTY end

  -- Check if GID is in the grass tiles list
  for _, grassGid in ipairs(TiledMapLoader.GRASS_TILES) do
    if gid == grassGid then
      return TiledMapLoader.TILE_GRASS
    end
  end

  -- Check if GID is in the worldedge tiles list
  for _, worldedgeGid in ipairs(TiledMapLoader.WORLDEDGE_TILES) do
    if gid == worldedgeGid then
      return TiledMapLoader.TILE_WORLDEDGE
    end
  end

  -- Default: treat unknown tiles as non-walkable for safety
  return TiledMapLoader.TILE_WORLDEDGE
end

--- Parse collision grid from tile layer
function TiledMapLoader.parseCollisionGrid(tiledMap, width, height)
  local grid = {}
  local layer = tiledMap.layers and tiledMap.layers[1]

  if not layer or layer.type ~= "tilelayer" then
    return grid
  end

  for y = 1, height do
    for x = 1, width do
      if not grid[x] then grid[x] = {} end
      local gid = layer.data[(y - 1) * width + x]
      local tileType = TiledMapLoader.getTileType(gid)
      grid[x][y] = {
        type = tileType,
        gid = gid,
        walkable = TiledMapLoader.isWalkable(tileType)
      }
    end
  end

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
---@return table Array of collision bodies
function TiledMapLoader.createCollisionBodies(mapData, physicsWorld)
  local collisionBodies = {}
  local collisionGrid = mapData.collisionGrid
  local worldWidth = mapData.width
  local worldHeight = mapData.height
  local tileSize = mapData.tileSize

  -- Create colliders for non-walkable tiles
  for x = 1, worldWidth do
    for y = 1, worldHeight do
      local tileData = collisionGrid[x][y]
      if tileData and not tileData.walkable then
        local tileX = (x - 1) * tileSize
        local tileY = (y - 1) * tileSize

        -- Create a rectangular collider for each wall/structure tile
        if physicsWorld then
          local body = love.physics.newBody(physicsWorld,
            tileX + tileSize / 2, tileY + tileSize / 2, "static")
          local shape = love.physics.newRectangleShape(tileSize, tileSize)
          local fixture = love.physics.newFixture(body, shape)
          fixture:setRestitution(0.1) -- Slight bounce
          fixture:setFriction(0.8)    -- High friction

          table.insert(collisionBodies, {
            body = body,
            fixture = fixture,
            shape = shape
          })
        end
      end
    end
  end

  -- Create boundary walls around the entire map
  local mapWidthPixels = worldWidth * tileSize
  local mapHeightPixels = worldHeight * tileSize
  local wallThickness = 32 -- Thickness of boundary walls

  if physicsWorld then
    -- Left boundary wall
    local leftWall = love.physics.newBody(physicsWorld, -wallThickness/2, mapHeightPixels/2, "static")
    local leftShape = love.physics.newRectangleShape(wallThickness, mapHeightPixels + wallThickness * 2)
    local leftFixture = love.physics.newFixture(leftWall, leftShape)
    leftFixture:setRestitution(0.1)
    leftFixture:setFriction(0.8)
    table.insert(collisionBodies, {body = leftWall, fixture = leftFixture, shape = leftShape})

    -- Right boundary wall
    local rightWall = love.physics.newBody(physicsWorld, mapWidthPixels + wallThickness/2, mapHeightPixels/2, "static")
    local rightShape = love.physics.newRectangleShape(wallThickness, mapHeightPixels + wallThickness * 2)
    local rightFixture = love.physics.newFixture(rightWall, rightShape)
    rightFixture:setRestitution(0.1)
    rightFixture:setFriction(0.8)
    table.insert(collisionBodies, {body = rightWall, fixture = rightFixture, shape = rightShape})

    -- Top boundary wall
    local topWall = love.physics.newBody(physicsWorld, mapWidthPixels/2, -wallThickness/2, "static")
    local topShape = love.physics.newRectangleShape(mapWidthPixels, wallThickness)
    local topFixture = love.physics.newFixture(topWall, topShape)
    topFixture:setRestitution(0.1)
    topFixture:setFriction(0.8)
    table.insert(collisionBodies, {body = topWall, fixture = topFixture, shape = topShape})

    -- Bottom boundary wall
    local bottomWall = love.physics.newBody(physicsWorld, mapWidthPixels/2, mapHeightPixels + wallThickness/2, "static")
    local bottomShape = love.physics.newRectangleShape(mapWidthPixels, wallThickness)
    local bottomFixture = love.physics.newFixture(bottomWall, bottomShape)
    bottomFixture:setRestitution(0.1)
    bottomFixture:setFriction(0.8)
    table.insert(collisionBodies, {body = bottomWall, fixture = bottomFixture, shape = bottomShape})
  end

  return collisionBodies
end

return TiledMapLoader
