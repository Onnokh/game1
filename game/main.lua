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
local postprocessCanvas = nil

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


local function createRenderCanvases(screenW, screenH)
  local newWorldCanvas = love.graphics.newCanvas(screenW, screenH)
  local newPostprocessCanvas = love.graphics.newCanvas(screenW, screenH)

  if worldCanvas then
    worldCanvas:release()
  end
  if postprocessCanvas then
    postprocessCanvas:release()
  end

  worldCanvas = newWorldCanvas
  postprocessCanvas = newPostprocessCanvas
end

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
  createRenderCanvases(screenW, screenH)

  -- Initialize lighting at full resolution
  local WorldLight = require("src.utils.worldlight")
  WorldLight.init(screenW, screenH)

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
    }, false) -- disabled by default
  end
end


function love.draw()
  -- Ensure canvas exists
  if not worldCanvas then
    return
  end

  local screenW, screenH = love.graphics.getDimensions()

  -- Ensure render canvases match current screen size
  if not postprocessCanvas
     or worldCanvas:getWidth() ~= screenW
     or worldCanvas:getHeight() ~= screenH
     or postprocessCanvas:getWidth() ~= screenW
     or postprocessCanvas:getHeight() ~= screenH then
    createRenderCanvases(screenW, screenH)
  end

  local currentSceneName = gameState.currentScene
  local currentSceneModule = gameState.scenes[currentSceneName]
  local isGameScene = currentSceneName == "game"

  if isGameScene then
    -- STEP 1 & 2: Draw parallax background and world content at full resolution
    love.graphics.setCanvas(worldCanvas)
    love.graphics.clear(0, 0, 0, 1)

    local GameScene = require("src.scenes.game")

    local success, err = pcall(function()
      -- Draw world content
      GameScene.drawWorld(gameState)

      -- Render darkness map and lighting overlay
      if GameScene.lightWorld and GameScene.lightWorld.renderDarknessMap then
        GameScene.lightWorld.renderDarknessMap(gameState.camera)
      end
      if GameScene.lightWorld and GameScene.lightWorld.drawOverlay then
        GameScene.lightWorld.drawOverlay()
      end
    end)

    if not success then
      print("Error in GameScene.drawWorld():", err)
      error(err)
    end

    love.graphics.setCanvas()

    -- STEP 3: Apply postprocessing effects to full-resolution world canvas
    if postprocessCanvas then
      love.graphics.setCanvas(postprocessCanvas)
      love.graphics.clear(0, 0, 0, 1)
      love.graphics.draw(worldCanvas, 0, 0)
      love.graphics.setCanvas()

      -- Apply postprocessing effects
      PostprocessingManager.apply(postprocessCanvas)
    end

    -- -- Draw screen-space effects AFTER postprocessing (e.g., aim line)
    -- if GameScene.drawAimLine then
    --   GameScene.drawAimLine(gameState)
    -- end

    -- STEP 4: Draw UI at full resolution (unaffected by pixel scaling)
    local success2, err2 = pcall(function()
      GameScene.drawUI(gameState)
    end)

    if not success2 then
      print("Error in GameScene.drawUI():", err2)
      error(err2)
    end
  else
    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0, 1)

    if currentSceneModule and currentSceneModule.draw then
      local successSceneDraw, errSceneDraw = pcall(function()
        currentSceneModule.draw(gameState)
      end)

      if not successSceneDraw then
        print(string.format("Error in %s.draw():", currentSceneName), errSceneDraw)
        error(errSceneDraw)
      end
    end
  end

  -- Draw overlayStats on top
  overlayStats.draw(gameState.camera.x, gameState.camera.y, gameState.camera.scale)
end

function love.update(dt)
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
