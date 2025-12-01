---@class IffySprites
local IffySprites = {}

local iffy = require("lib.iffy")

-- Generic spritesheet loader
-- Loads any spritesheet with configurable grid dimensions
local loadedSheets = {}
local assetsLoaded = false
local images = {}

local function loadSpritesheet(name, path, cols, rows)
  if loadedSheets[name] then return end

  -- Load the image to get dimensions
  local image = love.graphics.newImage(path)
  -- Set filter to "nearest" for crisp pixel art
  image:setFilter("nearest", "nearest")
  local sw, sh = image:getWidth(), image:getHeight()
  local tileW, tileH = sw / cols, sh / rows

  -- Register with iffy
  iffy.newTileset(name, path, tileW, tileH, 0, 0, sw, sh)
  loadedSheets[name] = true

  print(string.format("Loaded spritesheet '%s' with %dx%d grid (%d total frames) - Frame size: %.1fx%.1f", name, cols, rows, cols * rows, tileW, tileH))
end

local function loadImage(name, path)
  if images[name] then return end

  local ok, imgOrErr = pcall(function()
    local img = love.graphics.newImage(path)
    img:setFilter("nearest", "nearest")
    return img
  end)

  if ok then
    images[name] = imgOrErr
    print(string.format("Loaded image '%s'", name))
  else
    print(string.format("ERROR loading image '%s': %s", name, imgOrErr))
  end
end


-- Initialize all sprites using Iffy
function IffySprites.load()
  if assetsLoaded then return end
  print("Loading sprites with Iffy...")

  -- Note: World tiles are now handled by Cartographer, not Iffy

  -- Load character spritesheet (8x6 grid)
  loadSpritesheet("shaman", "resources/classes/shaman/model/shaman.png", 10, 2)

  -- Load coin spritesheet (1x9 grid, 9 frames)
  loadSpritesheet("coin", "resources/loot/coin.png", 9, 1)

  -- Load items spritesheet (16x27 grid, 32x32 per item)
  loadSpritesheet("items", "resources/loot/items.png", 16, 27)

  -- Load bullet sprite (1x1 grid, 16x16)
  loadSpritesheet("bullet", "resources/projectile.png", 1, 1)

  -- Load standalone images (not using iffy)
  loadImage("menuBackground", "resources/global/menu/background.png")

  -- Load minimap icons
  loadImage("minimapShop", "resources/icons/shop.png")
  loadImage("minimapUpgrade", "resources/icons/upgrade.png")
  loadImage("minimapPlayer", "resources/icons/player.png")


  -- Load shaman abilities sprites
  loadSpritesheet("lightningbolt-projectile", "resources/classes/shaman/abilities/lightning-bolt/lightningbolt-projectile.png", 6, 1)
  loadSpritesheet("flameshock-projectile", "resources/classes/shaman/abilities/flame-shock/flameshock-projectile.png", 1, 1)

  -- dun morogh - decorations
  loadSpritesheet("tree-stump", "resources/dun-morogh/tree-stump.png", 1, 1)
  loadSpritesheet("tree", "resources/dun-morogh/tree.png", 1, 1)
  loadSpritesheet("tree2", "resources/dun-morogh/tree2.png", 1, 1)
  loadSpritesheet("tree3", "resources/dun-morogh/tree3.png", 1, 1)
  loadSpritesheet("torch", "resources/dun-morogh/torch.png", 1, 1)
  loadSpritesheet("barrel", "resources/dun-morogh/barrel.png", 1, 1)
  loadSpritesheet("inn", "resources/dun-morogh/inn.png", 1, 1)
  loadSpritesheet("mailbox", "resources/dun-morogh/mailbox.png", 1, 1)
  loadSpritesheet("tent1", "resources/dun-morogh/tent1.png", 1, 1)
  loadSpritesheet("tent2", "resources/dun-morogh/tent2.png", 1, 1)
  loadSpritesheet("firepit", "resources/dun-morogh/firepit.png", 1, 1)

  -- dun morogh - monsters
  loadSpritesheet("crag-boar", "resources/monsters/crag-boar/crag-boar.png", 1, 1)
  loadSpritesheet("bear", "resources/monsters/bear/bear.png", 1, 1)

  -- Load old monsters spritesheets (unused)
  loadSpritesheet("skeleton", "resources/monsters/skeleton/Skeleton.png", 6, 10)
  loadSpritesheet("slime", "resources/monsters/slime/Slime_Green.png", 8, 3)

  -- Load old spritesheets (unused)
  loadSpritesheet("shop", "resources/objects/shop.png", 8, 1)
  loadSpritesheet("crystal", "resources/objects/crystal.png", 14, 1)
  loadSpritesheet("event", "resources/objects/event-area.png", 11, 3)
  loadSpritesheet("event-gem", "resources/objects/event-gem.png", 11, 3)


  print("Iffy sprites loaded successfully")

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
  local menuBackground = images.menuBackground
  if not menuBackground then return end
  local iw, ih = menuBackground:getWidth(), menuBackground:getHeight()
  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local scale = math.max(sw / iw, sh / ih)
  local drawW, drawH = iw * scale, ih * scale
  local dx = (sw - drawW) * 0.5
  local dy = (sh - drawH) * 0.5
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(menuBackground, dx, dy, 0, scale, scale)
end

-- Get a loaded image by name
function IffySprites.getImage(name)
  return images[name]
end

return IffySprites
