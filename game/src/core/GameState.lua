local GameConstants = require("src.constants")
local gamera = require("lib.gamera")
local GameTimeManager = require("src.core.managers.GameTimeManager")

-- Single source of truth for a fresh run's starting values
local DEFAULT_RUN = {
  coins = {
    total = 0,
    collectedThisSession = 0
  }
}

-- Utility: deep copy a table (handles nested tables)
local TableUtils = require("src.utils.table")

---@class GameState
---@field currentScene string The current active scene
---@field scenes table Table of all available scenes
---@field input table Input state tracking
---@field camera table Camera system
---@field player table Player character data

local GameState = {
  currentScene = "game",
  scenes = {},
  input = {
    up = false,
    down = false,
    left = false,
    right = false,
    action = false,
    cancel = false,
    shift = false,
    attack = false,
    interact = false,
    switchWeapon = false,
    mouseX = 0,
    mouseY = 0
  },
  camera = nil, -- Will be initialized with gamera
  player = {},
  coins = {},
  mapData = nil, -- Map data for debugging
  gameTimeManager = nil -- Game time manager for wave spawning
}

---Initialize the game state
function GameState.load()

  -- Start from a fresh deep copy of defaults for a clean run
  local runCopy = TableUtils.deepCopy(DEFAULT_RUN)
  GameState.coins = runCopy.coins

  -- Initialize player with constants only (spawn position comes from map)
  GameState.player = {
    width = GameConstants.PLAYER_WIDTH,
    height = GameConstants.PLAYER_HEIGHT,
    speed = GameConstants.PLAYER_SPEED
  }

  -- Initialize gamera camera with proper bounds starting at (0,0)
  GameState.camera = gamera.new(
    0,  -- left
    0,  -- top
    1,  -- -- will be updated in setCameraBounds when scene is loaded
    1  -- -- will be updated in setCameraBounds when scene is loaded
  )

  -- Initialize game time manager
  GameTimeManager.init()
  GameState.gameTimeManager = GameTimeManager

  -- Initialize scenes
  GameState.scenes = {
    game = require("src.scenes.game"),
    menu = require("src.scenes.menu")
  }

  -- Load the current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].load then
    GameState.scenes[GameState.currentScene].load()
  end

  -- Emit initial scene change event for cursor manager
  local EventBus = require("src.utils.EventBus")
  EventBus.emit("sceneChanged", { sceneName = GameState.currentScene })
end

---Reset run-specific state to start a fresh game
function GameState.resetRunState()
  -- Make a deep copy of DEFAULT_RUN and overwrite run-specific fields
  local runCopy = TableUtils.deepCopy(DEFAULT_RUN)

  for k, v in pairs(runCopy) do
    GameState[k] = v
  end

  -- Ensure persistent systems are not overwritten and are reset
  GameState.input = GameState.input or {}
  for k in pairs(GameState.input) do
    GameState.input[k] = false
  end

  -- Reapply constants for player block (spawn position comes from map)
  GameState.player = {
    width = GameConstants.PLAYER_WIDTH,
    height = GameConstants.PLAYER_HEIGHT,
    speed = GameConstants.PLAYER_SPEED
  }

  -- Camera will be positioned when the player entity spawns from the map
end

---Update mouse position in world coordinates
function GameState.updateMousePosition()
  local mouseX, mouseY = love.mouse.getPosition()

  -- Convert screen coordinates to world coordinates using gamera
  GameState.input.mouseX, GameState.input.mouseY = GameState.camera:toWorld(mouseX, mouseY)
end

---Update the game state
---@param dt number Delta time
function GameState.update(dt)
  -- Update current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].update then
    GameState.scenes[GameState.currentScene].update(dt, GameState)
  end
end

---Update only UI systems (used when game is paused)
---@param dt number Delta time
function GameState.updateUI(dt)
  -- Update current scene's UI world only
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].updateUI then
    GameState.scenes[GameState.currentScene].updateUI(dt, GameState)
  end
end

---Draw the game state
function GameState.draw()
  -- Draw current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].draw then
    GameState.scenes[GameState.currentScene].draw(GameState)
  end
end

---Handle input events
---@param key string Key pressed
function GameState.handleKeyPressed(key)
  if key == "w" or key == "up" then
    GameState.input.up = true
  elseif key == "s" or key == "down" then
    GameState.input.down = true
  elseif key == "a" or key == "left" then
    GameState.input.left = true
  elseif key == "d" or key == "right" then
    GameState.input.right = true
  elseif key == "space" or key == "return" then
    GameState.input.action = true
  elseif key == "escape" then
    GameState.input.cancel = true
  elseif key == "lshift" or key == "rshift" then
    GameState.input.shift = true
  elseif key == "e" then
    GameState.input.interact = true
  elseif key == "q" then
    GameState.input.switchWeapon = true
  end

  -- Pass to current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].handleKeyPressed then
    local handled = GameState.scenes[GameState.currentScene].handleKeyPressed(key, GameState)
    if handled then
      return true
    end
  end
  return false
end

---Handle key release events
---@param key string Key released
function GameState.handleKeyReleased(key)
  if key == "w" or key == "up" then
    GameState.input.up = false
  elseif key == "s" or key == "down" then
    GameState.input.down = false
  elseif key == "a" or key == "left" then
    GameState.input.left = false
  elseif key == "d" or key == "right" then
    GameState.input.right = false
  elseif key == "space" or key == "return" then
    GameState.input.action = false
  elseif key == "escape" then
    GameState.input.cancel = false
  elseif key == "lshift" or key == "rshift" then
    GameState.input.shift = false
  elseif key == "e" then
    GameState.input.interact = false
  elseif key == "q" then
    GameState.input.switchWeapon = false
  end
end

---Handle mouse press events
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button pressed
function GameState.handleMousePressed(x, y, button)
  -- Pass to current scene first to check if UI systems want to handle it
  local handled = false
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].mousepressed then
    handled = GameState.scenes[GameState.currentScene].mousepressed(x, y, button, GameState)
  end

  -- Only set attack input if the UI didn't consume the click
  if not handled and button == 1 then -- Left mouse button
    GameState.input.attack = true
  end
end

---Handle mouse release events
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button released
function GameState.handleMouseReleased(x, y, button)
  if button == 1 then -- Left mouse button
    GameState.input.attack = false
  end

  -- Pass to current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].mousereleased then
    GameState.scenes[GameState.currentScene].mousereleased(x, y, button, GameState)
  end
end

---Change to a different scene
---@param sceneName string Name of the scene to change to
function GameState.changeScene(sceneName)
  if GameState.scenes[sceneName] then
    -- Cleanup current scene before switching
    local currentScene = GameState.scenes[GameState.currentScene]
    if currentScene and currentScene.cleanup then
      currentScene.cleanup()
    end

    -- Switch to new scene
    GameState.currentScene = sceneName

    -- Emit scene change event for cursor manager
    local EventBus = require("src.utils.EventBus")
    EventBus.emit("sceneChanged", { sceneName = sceneName })

    -- Load new scene
    if GameState.scenes[sceneName].load then
      GameState.scenes[sceneName].load()
    end
  end
end

---Add coins to the player's total
---@param amount number Number of coins to add
function GameState.addCoins(amount)
  GameState.coins.total = GameState.coins.total + amount
  GameState.coins.collectedThisSession = GameState.coins.collectedThisSession + amount
end

---Remove coins from the player's total
---@param amount number Number of coins to remove
---@return boolean True if enough coins were available to remove
function GameState.removeCoins(amount)
  if GameState.coins.total >= amount then
    GameState.coins.total = GameState.coins.total - amount
    return true
  end
  return false
end

---Get the total coin count
---@return number Total number of coins
function GameState.getTotalCoins()
  return GameState.coins.total
end

---Get coins collected this session
---@return number Coins collected in current session
function GameState.getCoinsThisSession()
  return GameState.coins.collectedThisSession
end

---Reset session coins (keep total, reset session counter)
function GameState.resetSessionCoins()
  GameState.coins.collectedThisSession = 0
end

---Update camera bounds based on the current level dimensions
---@param width number World width in pixels
---@param height number World height in pixels
function GameState.updateCameraBounds(width, height)
  if GameState.camera then
    -- Create a new camera with the updated bounds
    local currentX, currentY = GameState.camera:getPosition()
    GameState.camera = gamera.new(0, 0, width, height)
    GameState.camera:setPosition(currentX, currentY)
  end
end

---Get the current world bounds in pixels
---@return number width World width in pixels
---@return number height World height in pixels
function GameState.getWorldBounds()
  if GameState.camera then
    local l, t, r, b = GameState.camera:getWorld()
    return r - l, b - t
  end
  -- Fallback to default if camera not initialized
  return 768, 768
end

return GameState
