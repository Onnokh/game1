local overlayStats = require("lib.overlayStats")
local gameState = require("src.core.State")
_G.gameState = gameState

-- Load Lovebird for debugging
local lovebird = require("lovebird")

function love.load()
  -- Initialize game state
  local success, err = pcall(function()
    gameState.load()
  end)

  if not success then
    print("Error in gameState.load():", err)
    error(err)
  end

  -- Your game load here
  overlayStats.load() -- Should always be called last
end

function love.draw()
  -- Draw game state
  local success, err = pcall(function()
    gameState.draw()
  end)

  if not success then
    print("Error in gameState.draw():", err)
    error(err)
  end

  -- Pass camera position and scale for world space gridlines
  overlayStats.draw(gameState.camera.x, gameState.camera.y, gameState.camera.scale)
end

function love.update(dt)
  -- lovebird.update()

  -- Update mouse position
  gameState.updateMousePosition()

  -- Update game state
  local success, err = pcall(function()
    gameState.update(dt)
  end)

  if not success then
    print("Error in gameState.update():", err)
    error(err)
  end

  -- Your game update here
  overlayStats.update(dt) -- Should always be called last
end

function love.keypressed(key)
  if key == "escape" and love.system.getOS() ~= "Web" then
    love.event.quit()
  else
    -- Handle input through game state
    gameState.handleKeyPressed(key)
    overlayStats.handleKeyboard(key) -- Should always be called last
  end
end

function love.keyreleased(key)
  -- Handle key release through game state
  gameState.handleKeyReleased(key)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  overlayStats.handleTouch(id, x, y, dx, dy, pressure) -- Should always be called last
end

function love.mousemoved(x, y, dx, dy, istouch)
  -- Mouse movement is handled in update() via updateMousePosition()
end

function love.mousepressed(x, y, button)
  -- Pass mouse events to current scene
  if gameState.scenes[gameState.currentScene] and gameState.scenes[gameState.currentScene].mousepressed then
    gameState.scenes[gameState.currentScene].mousepressed(x, y, button, gameState)
  end
end
