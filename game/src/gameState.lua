---@class GameState
---@field currentScene string The current active scene
---@field scenes table Table of all available scenes
---@field input table Input state tracking
---@field camera table Camera system
---@field player table Player character data
local GameConstants = require("src.constants")
local GameState = {
  currentScene = "menu",
  scenes = {},
  input = {
    up = false,
    down = false,
    left = false,
    right = false,
    action = false,
    cancel = false,
    mouseX = 0,
    mouseY = 0
  },
  camera = {
    x = 0,
    y = 0,
    targetX = 0,
    targetY = 0,
    followSpeed = 5,
    scale = GameConstants.CAMERA_SCALE
  },
  player = {
    x = 100,
    y = 100,
    width = 16,
    height = 24,
    speed = 300,
    direction = "down"
  }
}

---Initialize the game state
function GameState.load()
  -- Set values from constants (using local variables to avoid linter issues)
  local camFollowSpeed = GameConstants.CAMERA_FOLLOW_SPEED
  local camScale = GameConstants.CAMERA_SCALE
  local playerWidth = GameConstants.PLAYER_WIDTH
  local playerHeight = GameConstants.PLAYER_HEIGHT
  local playerSpeed = GameConstants.PLAYER_SPEED

  GameState.camera.followSpeed = camFollowSpeed
  GameState.camera.scale = camScale
  GameState.player.width = playerWidth
  GameState.player.height = playerHeight
  GameState.player.speed = playerSpeed

  -- Initialize scenes
  GameState.scenes = {
    game = require("src.scenes.gameScene"),
    menu = require("src.scenes.menuScene")
  }

  -- Load the current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].load then
    GameState.scenes[GameState.currentScene].load()
  end
end

---Update mouse position in world coordinates
function GameState.updateMousePosition()
  local mouseX, mouseY = love.mouse.getPosition()
  local scale = GameState.camera.scale

  -- Convert screen coordinates to world coordinates
  GameState.input.mouseX = (mouseX / scale) + GameState.camera.x
  GameState.input.mouseY = (mouseY / scale) + GameState.camera.y
end

---Update the game state
---@param dt number Delta time
function GameState.update(dt)
  -- Update current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].update then
    GameState.scenes[GameState.currentScene].update(dt, GameState)
  end

  -- Update camera
  GameState.updateCamera(dt)
end

---Draw the game state
function GameState.draw()
  -- Draw current scene
  if GameState.scenes[GameState.currentScene] and GameState.scenes[GameState.currentScene].draw then
    GameState.scenes[GameState.currentScene].draw(GameState)
  end
end

---Update camera position to follow player
---@param dt number Delta time
function GameState.updateCamera(dt)
  -- Use actual world dimensions from constants
  -- World is WORLD_WIDTH tiles × WORLD_HEIGHT tiles at TILE_SIZE pixels each
  local worldWidthPixels = GameConstants.WORLD_WIDTH_PIXELS
  local worldHeightPixels = GameConstants.WORLD_HEIGHT_PIXELS

  -- Set camera target to player position (account for camera scale)
  local scale = GameState.camera.scale
  local screenWidth = love.graphics.getWidth() / scale
  local screenHeight = love.graphics.getHeight() / scale

  GameState.camera.targetX = GameState.player.x - screenWidth / 2
  GameState.camera.targetY = GameState.player.y - screenHeight / 2

  -- Clamp camera target to world bounds
  -- Allow camera to go slightly negative to show first tile fully
  -- Allow camera to go to worldWidthPixels - screenWidth to show last tile fully
  GameState.camera.targetX = math.max(0, math.min(GameState.camera.targetX, worldWidthPixels - screenWidth))
  GameState.camera.targetY = math.max(0, math.min(GameState.camera.targetY, worldHeightPixels - screenHeight))

  -- Smoothly move camera towards target
  local dx = GameState.camera.targetX - GameState.camera.x
  local dy = GameState.camera.targetY - GameState.camera.y

  GameState.camera.x = GameState.camera.x + dx * GameState.camera.followSpeed * dt
  GameState.camera.y = GameState.camera.y + dy * GameState.camera.followSpeed * dt
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
