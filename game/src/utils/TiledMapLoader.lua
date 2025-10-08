-- OKH: Todo: Expand this whenever we add more objects to Tiled map

---@class TiledMapLoader
--- Simple utility for extracting data from Tiled maps loaded via Cartographer
local TiledMapLoader = {}

-- Tile type constants
TiledMapLoader.TILE_EMPTY = 0
TiledMapLoader.TILE_GRASS = 1
TiledMapLoader.TILE_STONE = 2
TiledMapLoader.TILE_WALL = 3
TiledMapLoader.TILE_STRUCTURE = 4

--- Check if a tile type is walkable
function TiledMapLoader.isWalkable(tileType)
  return tileType == TiledMapLoader.TILE_GRASS or tileType == TiledMapLoader.TILE_STONE
end

--- Get tile collision type from GID
local function getTileType(gid)
  if gid == 0 then return 0 end
  if gid >= 1 and gid < 65 then return 1      -- Grass (walkable)
  elseif gid >= 65 and gid < 321 then return 3 -- Walls (collision)
  elseif gid >= 321 and gid < 385 then return 2 -- Stone (walkable)
  elseif gid >= 385 then return 4              -- Structure (collision)
  else return 1 end
end

--- Parse collision grid from tile layer
function TiledMapLoader.parseCollisionGrid(tiledMap, width, height)
  local grid = {}
  local layer = tiledMap.layers and tiledMap.layers[1]

  if not layer or layer.type ~= "tilelayer" then
    return grid
  end

  for x = 1, width do
    grid[x] = {}
    for y = 1, height do
      local gid = layer.data[(y - 1) * width + x]
      grid[x][y] = getTileType(gid)
    end
  end

  return grid
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

  return mapData
end

return TiledMapLoader
