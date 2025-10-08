-- OKH: Todo: Expand this whenever we add more objects to Tiled map

---@class TiledMapLoader
--- Simple utility for extracting data from Tiled maps loaded via Cartographer
local TiledMapLoader = {}

--- Get tile collision type from properties or GID fallback
local function getTileType(tiledMap, gid)
  if gid == 0 then return 0 end

  -- Try tile properties first (set these in Tiled for flexibility)
  local collision = tiledMap:getTileProperty(gid, "collision")
  if collision ~= nil then
    return collision and 3 or 1
  end

  -- Fallback to GID ranges (project-specific)
  if gid >= 1 and gid < 65 then return 1      -- Grass
  elseif gid >= 65 and gid < 321 then return 3 -- Walls
  elseif gid >= 321 and gid < 385 then return 2 -- Stone
  elseif gid >= 385 then return 4              -- Structure
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
      grid[x][y] = getTileType(tiledMap, gid)
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
