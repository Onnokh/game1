---@class DiscoveryPhase
local Discovery = {}

function Discovery.onEnter(gameState)
  -- Bright, warmer ambient for exploration
  local GameScene = require("src.scenes.game")
  if GameScene and GameScene.setAmbientColor then
    -- brighter daylight
    GameScene.setAmbientColor(210, 210, 210, 255, 5)  -- Dark ambient lighting
  end
end


function Discovery.update(dt, gameState)
  -- When oxygen is depleted, switch to Siege phase
  local GameScene = require("src.scenes.game")
  local ecsWorld = GameScene and GameScene.ecsWorld
  if not ecsWorld then return end

  local player = ecsWorld:getPlayer()
  if player then
    local oxygen = player:getComponent("Oxygen")
    if oxygen and oxygen.isDepleted then
      local GameController = require("src.core.GameController")
      GameController.switchPhase("Siege")
    end
  end

end

function Discovery.draw(gameState)
  -- Optional phase-specific overlays
end

function Discovery.onExit(gameState)
end

return Discovery


