local GameState = require("src.core.GameState")
local EventBus = require("src.utils.EventBus")

---@class GameController
---@field paused boolean
local GameController = {
  paused = false,
  gameOver = false
}

---Initialize controller and game state
function GameController.load()
  -- Initialize GameState (loads scenes and initializes systems via scenes/game.lua)
  GameState.load()
end

---Update flow: controller -> GameState (scene + systems)
---@param dt number
function GameController.update(dt)
  if not GameController.paused then
    -- Maintain existing update behavior in GameState (updates scene and systems)
    GameState.updateMousePosition()
    GameState.update(dt)
  else
    -- When paused, still update UI systems so pause menu can respond
    GameState.updateMousePosition()
    GameState.updateUI(dt)
  end
end

---Draw flow: controller -> GameState draw
function GameController.draw()
  GameState.draw()
end


function GameController.setPaused(paused)
  GameController.paused = not not paused
end

function GameController.togglePause()
  if GameController.gameOver then
    return
  end
  GameController.paused = not GameController.paused

  -- Stop any movement loop sounds when pausing
  if GameController.paused then
    local player = GameState.ecsWorld and GameState.ecsWorld:getPlayer()
    if player then
      local stateMachine = player:getComponent("StateMachine")
      if stateMachine then
        local movementSound = stateMachine:getGlobalData("movementSound")
        if movementSound then
          movementSound:stop()
          stateMachine:setGlobalData("movementSound", nil)
        end
      end
    end
  end

  -- Emit event to show/hide pause menu
  local EventBus = require("src.utils.EventBus")
  if GameController.paused then
    EventBus.emit("showPauseMenu", {})
  else
    EventBus.emit("hidePauseMenu", {})
  end
end

function GameController.resetPauseState()
  GameController.paused = false
  GameController.gameOver = false
end

function GameController.setGameOver()
  GameController.gameOver = true
  GameController.setPaused(true)
end

-- Restart the current game session (reload the current scene and reset pause/gameOver)
function GameController.restartGame()
  -- Check if we're loading from a save
  local SaveSystem = require("src.utils.SaveSystem")
  local isLoadingSave = SaveSystem.pendingLoadData ~= nil

  -- Clear pause/game-over
  GameController.gameOver = false
  GameController.paused = false


  -- Reload the game scene cleanly
  local GS = require("src.core.GameState")
  if GS and GS.resetRunState then GS.resetRunState() end
  if GS and GS.changeScene then
    GS.changeScene("game")
  end
end

-- Back to main menu scene
function GameController.backToMenu()
  GameController.gameOver = false
  GameController.paused = false
  local GameState = require("src.core.GameState")
  if GameState and GameState.changeScene then
    GameState.changeScene("menu")
  end
end

-- Input delegation (phases may intercept if needed, but systems stay in scenes)
function GameController.keypressed(key)
  -- When paused or game over, let UI systems handle input first
  if GameController.paused or GameController.gameOver then
    local handled = GameState.handleKeyPressed(key)
    if handled then
      return true
    end
  end

  -- Controller-level bindings
  if key == "escape" then
    if not GameController.gameOver then
      GameController.togglePause()
      return true
    end
    return true -- consume ESC during game over
  end


  -- Pass to game state for normal gameplay input
  if not GameController.paused and not GameController.gameOver then
    GameState.handleKeyPressed(key)
  end
end

return GameController
