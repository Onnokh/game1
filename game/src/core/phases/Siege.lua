---@class SiegePhase
local Siege = {}

function Siege.onEnter(gameState)
  -- Darker, moodier ambient for siege
  local GameScene = require("src.scenes.game")
  if GameScene and GameScene.setAmbientColor then
    -- dusk-night tone over 0.8s
    GameScene.setAmbientColor(70, 90, 140, 255, 5)
  end

  -- Spawn enemies from MobSpawn areas marked for "Siege" phase
  local MobManager = require("src.core.managers.MobManager")

  if GameScene and GameScene.ecsWorld and GameScene.physicsWorld then
    -- Spawn enemies from MobSpawn areas with phase="Siege"
    MobManager.spawnPhaseEnemies(
      "Siege",
      GameScene.ecsWorld,
      GameScene.physicsWorld,
      "SiegeAttacker"
    )
  end
end

function Siege.update(dt, gameState)
  -- When all enemies are dead, return to Discovery phase
  local GameScene = require("src.scenes.game")
  local ecsWorld = GameScene and GameScene.ecsWorld
  if not ecsWorld then return end

  -- Check if all siege attackers are defeated
  local remaining = 0
  for _, entity in ipairs(ecsWorld.entities or {}) do
    if entity:hasTag("SiegeAttacker") then
      remaining = remaining + 1
      if remaining > 0 then break end
    end
  end

  if remaining == 0 then
    -- Late-require to avoid circular dependency during module load
    local GameController = require("src.core.GameController")
    GameController.switchPhase("Discovery")
  end
end

function Siege.draw(gameState)
  -- Optional overlays for siege
end

function Siege.onExit(gameState)
  -- Increment global day counter when leaving Siege
  if gameState then
    local current = tonumber(gameState.day or 0) or 0
    gameState.day = current + 1
  end
end

return Siege


