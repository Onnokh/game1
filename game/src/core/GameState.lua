local GameConstants = require("src.constants")
local gamera = require("lib.gamera")

---@class GameState
---@field currentScene string The current active scene
---@field scenes table Table of all available scenes
---@field input table Input state tracking
---@field camera table Camera system
---@field player table Player character data
---@field phase string Current gameplay phase name

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
    mouseX = 0,
    mouseY = 0
  },
  camera = nil, -- Will be initialized with gamera
  player = {
    x = 320,  -- Tile (10, 10)
    y = 192,  -- Tile (10, 10)
    width = 16,
    height = 24,
    speed = 300,
    direction = "down"
  },
  phase = "Discovery"
}

---Initialize the game state
function GameState.load()
  -- Set values from constants (using local variables to avoid linter issues)
  local playerWidth = GameConstants.PLAYER_WIDTH
  local playerHeight = GameConstants.PLAYER_HEIGHT
  local playerSpeed = GameConstants.PLAYER_SPEED

  GameState.player.width = playerWidth
  GameState.player.height = playerHeight
  GameState.player.speed = playerSpeed

  -- Initialize gamera camera with proper bounds starting at (0,0)
  GameState.camera = gamera.new(
    0,  -- left
    0,  -- top
    GameConstants.WORLD_WIDTH_PIXELS,  -- width
    GameConstants.WORLD_HEIGHT_PIXELS  -- height
  )

  -- Initialize scenes
  GameState.scenes = {
    game = require("src.scenes.game"),
    menu = require("src.scenes.menu")
  }

  -- Load the current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].load then
    GameState.scenes[GameState.currentScene].load()
  end
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
  end

  -- Pass to current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].handleKeyPressed then
    GameState.scenes[GameState.currentScene].handleKeyPressed(key, GameState)
  end
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
  end
end

---Handle mouse press events
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button pressed
function GameState.handleMousePressed(x, y, button)
  if button == 1 then -- Left mouse button
    GameState.input.attack = true
  end

  -- Pass to current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].mousepressed then
    GameState.scenes[GameState.currentScene].mousepressed(x, y, button, GameState)
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
end

---Change to a different scene
---@param sceneName string Name of the scene to change to
function GameState.changeScene(sceneName)
  if GameState.scenes[sceneName] then
    GameState.currentScene = sceneName
    if GameState.scenes[sceneName].load then
      GameState.scenes[sceneName].load()
    end
  end
end

return GameState
