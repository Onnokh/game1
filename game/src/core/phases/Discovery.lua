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
  -- Discovery phase logic
end

function Discovery.draw(gameState)
  -- Optional phase-specific overlays
end

function Discovery.onExit(gameState)
end

return Discovery


