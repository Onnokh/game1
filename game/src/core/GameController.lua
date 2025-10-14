local GameState = require("src.core.GameState")
local EventBus = require("src.utils.EventBus")
local Reactor = require("src.entities.Reactor.Reactor")

---@class GameController
---@field currentPhase string
---@field phases table<string, table>
---@field paused boolean
local GameController = {
  currentPhase = "Discovery", -- default phase
  phases = {},
  paused = false,
  gameOver = false
}

---Initialize controller, game state, and phases
function GameController.load()
  -- Initialize GameState (loads scenes and initializes systems via scenes/game.lua)
  GameState.load()

  -- Prepare phases (phases consume systems prepared by scenes/game.lua)
  GameController.phases = {
    Discovery = require("src.core.phases.Discovery"),
    Siege = require("src.core.phases.Siege")
  }

  if GameController.phases[GameController.currentPhase] and GameController.phases[GameController.currentPhase].onEnter then
    -- Record phase on shared state for systems/UI
    GameState.phase = GameController.currentPhase
    GameController.phases[GameController.currentPhase].onEnter(GameState)
  end

  -- Subscribe once for game-over trigger on reactor death
  EventBus.subscribe("entityDied", function(payload)
    local entity = payload and payload.entity
    if entity and entity:hasTag("Reactor") then
      -- Ensure reactor-specific visual shutdown runs
      Reactor.handleDeath(entity)
      -- Then enter game-over state via controller
      GameController.setGameOver()
    end
  end)

end

---Update flow: controller -> current phase -> GameState (scene + systems)
---@param dt number
function GameController.update(dt)
  local phase = GameController.phases and GameController.phases[GameController.currentPhase]
  if phase and phase.update then
    phase.update(dt, GameState)
  end

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

---Draw flow: controller -> phase overlay -> GameState draw
function GameController.draw()
  local phase = GameController.phases and GameController.phases[GameController.currentPhase]
  if phase and phase.draw then
    phase.draw(GameState)
  end

  GameState.draw()
end

---Switch to a different gameplay phase
---@param nextPhase string
function GameController.switchPhase(nextPhase)
  if nextPhase == GameController.currentPhase then return end
  local current = GameController.phases and GameController.phases[GameController.currentPhase]
  if current and current.onExit then current.onExit(GameState) end
  GameController.currentPhase = nextPhase
  GameState.phase = nextPhase
  local incoming = GameController.phases and GameController.phases[GameController.currentPhase]
  if incoming and incoming.onEnter then incoming.onEnter(GameState) end
end

function GameController.setPaused(paused)
  GameController.paused = not not paused
end

function GameController.togglePause()
  if GameController.gameOver then
    return
  end
  GameController.paused = not GameController.paused
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

  if not isLoadingSave then
    -- Only reset phase for new games, not when loading saves
    GameController.currentPhase = "Discovery"
    -- Update phase overlay state
    local phase = GameController.phases and GameController.phases[GameController.currentPhase]
    if phase and phase.onEnter then
      GameState.phase = GameController.currentPhase
      phase.onEnter(GameState)
    end
  end

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
  -- Controller-level bindings
  if key == "escape" then
    if not GameController.gameOver then
      GameController.togglePause()
      return true
    end
    return true -- consume ESC during game over
  end

  -- When paused or game over, let UI systems handle input first
  if GameController.paused or GameController.gameOver then
    local handled = GameState.handleKeyPressed(key)
    if handled then
      return true
    end
  end

  -- Phase switching (only when not paused/game over)
  if not GameController.paused and not GameController.gameOver then
    if key == "1" then
      GameController.switchPhase("Discovery")
      return true
    elseif key == "2" then
      GameController.switchPhase("Siege")
      return true
    end
  end

  -- Pass to game state for normal gameplay input
  if not GameController.paused and not GameController.gameOver then
    GameState.handleKeyPressed(key)
  end
end

return GameController
