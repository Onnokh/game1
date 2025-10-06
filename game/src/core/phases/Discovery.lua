---@class DiscoveryPhase
local Discovery = {}

function Discovery.onEnter(gameState)
  -- Bright, warmer ambient for exploration
  local GameScene = require("src.scenes.game")
  if GameScene and GameScene.setAmbientColor then
    -- brighter daylight
    GameScene.setAmbientColor(255, 240, 255, 255, 5)
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


