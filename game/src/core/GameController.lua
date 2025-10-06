local overlayStats = require("lib.overlayStats")
local GameState = require("src.core.GameState")

---@class GameController
---@field currentPhase string
---@field phases table<string, table>
---@field paused boolean
local GameController = {
  currentPhase = "Discovery", -- default phase
  phases = {},
  paused = false
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

  -- overlayStats.load() is called from main.lua last, per existing behavior
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
  GameController.paused = not GameController.paused
end

-- Input delegation (phases may intercept if needed, but systems stay in scenes)
function GameController.keypressed(key)
  -- Controller-level bindings
  if key == "p" then
    GameController.togglePause()
    return true
  elseif key == "1" then
    GameController.switchPhase("Discovery")
    return true
  elseif key == "2" then
    GameController.switchPhase("Siege")
    return true
  end
  GameState.handleKeyPressed(key)
end

-- keyreleased/mousepressed/mousereleased are handled directly in main.lua via GameState

return GameController


