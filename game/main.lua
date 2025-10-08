local overlayStats = require("lib.overlayStats")
local GameController = require("src.core.GameController")
local gameState = require("src.core.GameState")
local SoundManager = require("src.utils.SoundManager")

_G.gameController = GameController
_G.SoundManager = SoundManager -- Make SoundManager globally accessible

-- Load Lovebird for debugging
local lovebird = require("lovebird")

function love.load()
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
