local overlayStats = require("lib.overlayStats")
local GameController = require("src.core.GameController")
local gameState = require("src.core.GameState")
local SoundManager = require("src.core.managers.SoundManager")
local CursorManager = require("src.core.managers.CursorManager")
local PostprocessingManager = require("src.core.managers.PostprocessingManager")

_G.gameController = GameController
_G.SoundManager = SoundManager -- Make SoundManager globally accessible
_G.CursorManager = CursorManager -- Make CursorManager globally accessible

-- Load Lovebird for debugging
local lovebird = require("lovebird")

-- World canvas for postprocessing
local worldCanvas = nil

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
  scale = 3,  -- Scale factor for the background
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

  -- Load cursor manager
  CursorManager.load()

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

  -- Create world canvas for postprocessing
  local screenW, screenH = love.graphics.getDimensions()
  worldCanvas = love.graphics.newCanvas(screenW, screenH)

  -- Initialize bloom effect
  local BloomEffect = require("src.effects.BloomEffect")
  local bloomEffect = BloomEffect.new(screenW, screenH)
  bloomEffect:setThreshold(0.85)
  bloomEffect:setStrength(12.0)
  bloomEffect:setIntensity(3.0)

  -- Register bloom with PostprocessingManager
  PostprocessingManager.addComplexEffect("bloom", bloomEffect, true) -- enabled

  -- Initialize color grading effect
  local ShaderManager = require("src.core.managers.ShaderManager")
  local colorGradingShader = ShaderManager.getShader("color_grade")
  if colorGradingShader then
    PostprocessingManager.addEffect("color_grading", colorGradingShader, {
      factors = {1.0, 1.0, 1.0} -- RGB multipliers, neutral
    }, false) -- disabled by default
  end

  -- Initialize vignette effect
  local vignetteShader = ShaderManager.getShader("vignette")
  if vignetteShader then
    PostprocessingManager.addEffect("vignette", vignetteShader, {
      radius = 0.95,
      softness = 0.5,
      opacity = .25,
      color = {0.0, 0.0, 0.0, 1.0} -- Black vignette
    }, true) -- enabled
  end
end


function love.draw()
  -- Ensure canvas exists
  if not worldCanvas then
    return
  end

  -- Set canvas to world canvas for postprocessing
  love.graphics.setCanvas(worldCanvas)
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

  -- Draw world content only (no UI) to canvas
  local success, err = pcall(function()
    local GameScene = require("src.scenes.game")
    GameScene.drawWorld(gameState)
  end)

  if not success then
    print("Error in GameScene.drawWorld():", err)
    error(err)
  end

  -- Reset canvas to screen
  love.graphics.setCanvas()

  -- Apply lighting FIRST (before postprocessing effects)
  -- Create intermediate canvas for lit scene
  local litCanvas = love.graphics.newCanvas(worldCanvas:getWidth(), worldCanvas:getHeight())
  love.graphics.setCanvas(litCanvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.draw(worldCanvas, 0, 0)

  -- Apply lighting overlay (multiply blend)
  local GameScene = require("src.scenes.game")
  local lightWorld = GameScene.lightWorld
  if lightWorld and lightWorld.drawOverlay then
    lightWorld.drawOverlay()
  end

  -- Reset canvas to screen
  love.graphics.setCanvas()

  -- Apply all postprocessing effects to the lit scene
  love.graphics.clear(0, 0, 0, 1)
  PostprocessingManager.apply(litCanvas, nil)

  -- Cleanup intermediate canvas
  litCanvas:release()

  -- Draw UI after postprocessing (unaffected by effects)
  local success2, err2 = pcall(function()
    local GameScene = require("src.scenes.game")
    GameScene.drawUI(gameState)
  end)

  if not success2 then
    print("Error in GameScene.drawUI():", err2)
    error(err2)
  end

  -- Draw overlayStats on top
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
  -- Let overlayStats handle clicks first (for debug toggles)
  local handled = overlayStats.handleMousePressed(x, y, button)

  -- If not handled by overlay, pass to game
  if not handled then
    local gameState = require("src.core.GameState")
    gameState.handleMousePressed(x, y, button)
  end
end

function love.mousereleased(x, y, button)
  local gameState = require("src.core.GameState")
  gameState.handleMouseReleased(x, y, button)
end
