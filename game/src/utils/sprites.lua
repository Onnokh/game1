---@class IffySprites
local IffySprites = {}

local iffy = require("lib.iffy")

-- Generic spritesheet loader
-- Loads any spritesheet with configurable grid dimensions
local loadedSheets = {}
local assetsLoaded = false
local menuBackgroundImage = nil

local function loadSpritesheet(name, path, cols, rows)
  if loadedSheets[name] then return end

  -- Load the image to get dimensions
  local image = love.graphics.newImage(path)
  -- Set filter to "nearest" for crisp pixel art
  image:setFilter("nearest", "nearest")
  local sw, sh = image:getWidth(), image:getHeight()
  local tileW, tileH = math.floor(sw / cols), math.floor(sh / rows)

  -- Register with iffy
  iffy.newTileset(name, path, tileW, tileH, 0, 0, sw, sh)
  loadedSheets[name] = true

  print(string.format("Loaded spritesheet '%s' with %dx%d grid (%d total frames)", name, cols, rows, cols * rows))
end

-- Initialize all sprites using Iffy
function IffySprites.load()
  if assetsLoaded then return end
  print("Loading sprites with Iffy...")

  -- Note: World tiles are now handled by Cartographer, not Iffy

  -- Load character spritesheet (8x6 grid)
  loadSpritesheet("character", "resources/character/AnimationSheet.png", 8, 6)
  loadSpritesheet("new", "resources/character/new.png", 4, 1)
  loadSpritesheet("new_walk", "resources/character/new_walk.png", 7, 1)

  -- Load skeleton spritesheet (6x10 grid - 6 columns, 10 rows)
  loadSpritesheet("skeleton", "resources/skeleton/Skeleton.png", 6, 10)

  -- Load slime spritesheet (8x3 grid - 8 columns, 3 rows)
  loadSpritesheet("slime", "resources/slime/Slime_Green.png", 8, 3)

  -- Load reactor spritesheet (1x1 grid, 64x64)
  loadSpritesheet("reactor", "resources/reactor/reactor-Sheet.png", 4, 1)

  -- Load coin spritesheet (1x9 grid, 9 frames)
  loadSpritesheet("coin", "resources/loot/coin.png", 9, 1)

  -- load warhog spritesheets (4x4 grid, 64x64 per frame)
  loadSpritesheet("Warhog_Attack", "resources/warhog/Warhog_Attack.png", 4, 4)
  loadSpritesheet("Warhog_Death", "resources/warhog/Warhog_Death.png", 4, 4)
  loadSpritesheet("Warhog_Idle", "resources/warhog/Warhog_Idle.png", 4, 4)
  loadSpritesheet("Warhog_Walk", "resources/warhog/Warhog_Walk.png", 4, 4)

  -- Load menu background as a standalone image (not using iffy)
  local okBg, imgOrErr = pcall(function()
    local img = love.graphics.newImage("resources/menu/background.jpg")
    img:setFilter("nearest", "nearest")
    return img
  end)
  if okBg then
    menuBackgroundImage = imgOrErr
  else
    print("ERROR loading menu background:", imgOrErr)
  end

  print("Iffy sprites loaded successfully")

  -- Debug: Check tilesets
  if iffy.spritesheets["wall"] then
    print(string.format("Wall tileset loaded with %d variants", #iffy.spritesheets["wall"]))
  else
    print("ERROR: Wall tileset not found!")
  end

  if iffy.spritesheets["character"] then
    print(string.format("Character tileset loaded with %d variants", #iffy.spritesheets["character"]))
  else
    print("ERROR: Character tileset not found!")
  end
  assetsLoaded = true
end

-- Generic animation helper
-- Draws a specific frame from any loaded spritesheet
function IffySprites.drawFrame(sheetName, frameIndex, x, y, scale, rotation)
  scale = scale or 1
  rotation = rotation or 0

  if iffy.spritesheets[sheetName] and iffy.spritesheets[sheetName][frameIndex] then
    iffy.draw(sheetName, frameIndex, x, y, rotation, scale, scale, 0, 0)
  else
    print(string.format("ERROR: Frame %d not found in spritesheet '%s'", frameIndex, sheetName))
  end
end

-- Draw character idle animation (frames 1-2)
function IffySprites.drawCharacterIdle(x, y, scale)
  scale = scale or 2
  local t = love.timer.getTime()
  local frame = (math.floor(t * 6) % 2) + 1 -- 6 fps over 2 frames
  local indices = {1, 2} -- row 1, col 1-2 (idle)
  local tileIndex = indices[frame]
  IffySprites.drawFrame("character", tileIndex, x, y, scale)
end

-- Draw a tile using Iffy
function IffySprites.drawTile(tileType, x, y, variant)
  variant = variant or 1

  -- Check if the tileset exists (silent check)
  if not iffy.spritesheets[tileType] then
    print(string.format("ERROR: %s tileset not found!", tileType))
    return
  end
  -- Check if the variant exists (silent check)
  if not iffy.spritesheets[tileType][variant] then
    print(string.format("ERROR: %s variant %d not found! Available variants: %d", tileType, variant, #iffy.spritesheets[tileType]))
    return
  end


  -- Use pcall to catch any errors
  local success, err = pcall(function()
    if tileType == "wall" or tileType == "grass" or tileType == "stone" or tileType == "structure" then
      iffy.draw(tileType, variant, x, y)
    end
  end)

  if not success then
    print(string.format("ERROR drawing %s tile at (%d,%d) variant %d: %s", tileType, x, y, variant, err))
  end
end

-- Draw player sprite with animation
function IffySprites.drawPlayer(x, y, direction, animation, animationTime)
  local baseIndex = 1

  -- Direction mapping (assuming 4 directions in 4x4 grid)
  if direction == "down" then
    baseIndex = 1
  elseif direction == "left" then
    baseIndex = 2
  elseif direction == "right" then
    baseIndex = 3
  elseif direction == "up" then
    baseIndex = 4
  end

  -- Animation offset (idle vs walk)
  local animOffset = 0
  if animation == "walk" then
    -- Simple walking animation based on time
    animOffset = math.floor(animationTime * 4) % 2
  end

  local tileIndex = baseIndex + animOffset * 4
  iffy.draw("player", tileIndex, x, y)
end

-- Create a tilemap for the world
function IffySprites.createTilemap(world, worldWidth, worldHeight)
  local tilemap = {}

  for y = 1, worldHeight do
    tilemap[y] = {}
    for x = 1, worldWidth do
      local tileType = world[x][y]
      local variant = math.random(1, 4) -- Random variant for each tile

      if tileType == 1 then
        tilemap[y][x] = variant -- Grass
      elseif tileType == 3 then
        tilemap[y][x] = variant + 8 -- Wall (offset by 8)
      elseif tileType == 4 then
        tilemap[y][x] = variant + 12 -- Plant (offset by 12)
      else
        tilemap[y][x] = 0 -- Empty
      end
    end
  end

  return tilemap
end

-- Draw the entire world using Iffy's tilemap system
function IffySprites.drawWorld(world, worldWidth, worldHeight, tileSize, tileVariants)
  -- Draw each tile individually for now (we can optimize this later)
  for x = 1, worldWidth do
    for y = 1, worldHeight do
      local tileX = (x - 1) * tileSize
      local tileY = (y - 1) * tileSize
      local variant = tileVariants and tileVariants[x] and tileVariants[x][y] or 1


      if world[x][y] == 1 then
        -- Grass tile
        IffySprites.drawTile("grass", tileX, tileY, variant)
      elseif world[x][y] == 2 then
        -- Stone ground tile
        IffySprites.drawTile("stone", tileX, tileY, variant)
      elseif world[x][y] == 3 then
        -- Wall tile
        IffySprites.drawTile("wall", tileX, tileY, variant)
      elseif world[x][y] == 4 then
        -- Structure tile
        IffySprites.drawTile("structure", tileX, tileY, variant)
      end
    end
  end
end

-- Draw the menu background scaled to cover the screen using raw image
function IffySprites.drawMenuBackground()
  if not menuBackgroundImage then return end
  local iw, ih = menuBackgroundImage:getWidth(), menuBackgroundImage:getHeight()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local scale = math.max(sw / iw, sh / ih)
  local drawW, drawH = iw * scale, ih * scale
  local dx = (sw - drawW) * 0.5
  local dy = (sh - drawH) * 0.5
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(menuBackgroundImage, dx, dy, 0, scale, scale)
end

return IffySprites
