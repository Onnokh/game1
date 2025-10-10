local overlayStats = require("lib.overlayStats")
local GameController = require("src.core.GameController")
local gameState = require("src.core.GameState")
local SoundManager = require("src.utils.SoundManager")

_G.gameController = GameController
_G.SoundManager = SoundManager -- Make SoundManager globally accessible

-- Load Lovebird for debugging
local lovebird = require("lovebird")

-- Parallax background state
local parallaxBg = {
  image = nil,
  quads = {},
  frameWidth = 64,
  frameHeight = 62,
  frameCount = 4,
  currentFrame = 1,
  animationTimer = 0,
  animationSpeed = 0.25, -- Seconds per frame (4fps = 0.25s)
  offsetX = 0,
  speed = 20, -- Pixels per second scrolling to the right
  scale = 5,  -- Scale factor for the background
  parallaxFactorX = 0.2, -- Camera movement influence (0.2 = moves 20% of camera speed)
  parallaxFactorY = 1.5 -- Vertical parallax factor
}

function love.load()
  -- Load parallax background sprite sheet
  local bgPath = "resources/background/space2_4-frames.png"
  local success, result = pcall(function()
    local img = love.graphics.newImage(bgPath)
    img:setFilter("nearest", "nearest") -- Pixel-perfect for pixel art
    return img
  end)

  if success then
    parallaxBg.image = result
    -- Create quads for each frame
    for i = 0, parallaxBg.frameCount - 1 do
      local quad = love.graphics.newQuad(
        i * parallaxBg.frameWidth,
        0,
        parallaxBg.frameWidth,
        parallaxBg.frameHeight,
        parallaxBg.image:getWidth(),
        parallaxBg.image:getHeight()
      )
      table.insert(parallaxBg.quads, quad)
    end
    print("Parallax background loaded:", bgPath, "with", parallaxBg.frameCount, "frames")
  else
    print("Failed to load parallax background:", result)
  end

  -- Initialize sound manager
  SoundManager.load()

  -- Initialize controller (which initializes GameState and scenes)
  local success, err = pcall(function()
    GameController.load()
  end)

  if not success then
    print("Error in GameController.load():", err)
    error(err)
  end

  overlayStats.load() -- Should always be called last
end

function love.draw()
  -- Clear the screen first
  love.graphics.clear(0, 0, 0, 1)

  -- Draw parallax scrolling background
  if parallaxBg.image and #parallaxBg.quads > 0 then
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local imgW = parallaxBg.frameWidth * parallaxBg.scale
    local imgH = parallaxBg.frameHeight * parallaxBg.scale

    -- Calculate how many times to tile the image
    local tilesX = math.ceil(screenW / imgW) + 2
    local tilesY = math.ceil(screenH / imgH) + 2

    -- Apply camera-based parallax offset (moves slower than camera)
    local cameraOffsetX = gameState.camera.x * parallaxBg.parallaxFactorX
    local cameraOffsetY = gameState.camera.y * parallaxBg.parallaxFactorY

    -- Combine automatic scroll with camera parallax
    local totalOffsetX = (parallaxBg.offsetX + cameraOffsetX) % imgW
    local totalOffsetY = cameraOffsetY % imgH

    -- Get current animation frame
    local currentQuad = parallaxBg.quads[parallaxBg.currentFrame]

    love.graphics.setColor(1, 1, 1, 0.5) -- Draw with some transparency
    for y = -1, tilesY do
      for x = -1, tilesX do
        local drawX = (x * imgW) - totalOffsetX
        local drawY = (y * imgH) - totalOffsetY
        love.graphics.draw(parallaxBg.image, currentQuad, drawX, drawY, 0, parallaxBg.scale, parallaxBg.scale)
      end
    end
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
  end

  -- Draw via controller
  local success, err = pcall(function()
    GameController.draw()
  end)

  if not success then
    print("Error in GameController.draw():", err)
    error(err)
  end

  -- Pass camera position and scale for world space gridlines
  overlayStats.draw(gameState.camera.x, gameState.camera.y, gameState.camera.scale)
end

function love.update(dt)
  -- Update parallax background scroll position and animation
  if parallaxBg.image then
    parallaxBg.offsetX = parallaxBg.offsetX + (parallaxBg.speed * dt)

    -- Update animation frame
    parallaxBg.animationTimer = parallaxBg.animationTimer + dt
    if parallaxBg.animationTimer >= parallaxBg.animationSpeed then
      parallaxBg.animationTimer = parallaxBg.animationTimer - parallaxBg.animationSpeed
      parallaxBg.currentFrame = parallaxBg.currentFrame + 1
      if parallaxBg.currentFrame > parallaxBg.frameCount then
        parallaxBg.currentFrame = 1
      end
    end
  end

  -- lovebird.update()

  -- Update via controller
  local success, err = pcall(function()
    GameController.update(dt)
  end)

  if not success then
    print("Error in GameController.update():", err)
    error(err)
  end

  overlayStats.update(dt) -- Should always be called last
end

function love.keypressed(key)
  if key == "escape" and love.system.getOS() ~= "Web" then
    -- Let GameController handle escape for pause/unpause first
    local handled = GameController.keypressed(key)
    if not handled then
      love.event.quit()
    end
  else
    GameController.keypressed(key)
  end
  overlayStats.handleKeyboard(key) -- Should always be called last
end

function love.keyreleased(key)
  local gameState = require("src.core.GameState")
  gameState.handleKeyReleased(key)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  overlayStats.handleTouch(id, x, y, dx, dy, pressure) -- Should always be called last
end

function love.mousepressed(x, y, button)
  local gameState = require("src.core.GameState")
  gameState.handleMousePressed(x, y, button)
end

function love.mousereleased(x, y, button)
  local gameState = require("src.core.GameState")
  gameState.handleMouseReleased(x, y, button)
end
