---@class SiegePhase
local Siege = {}

function Siege.onEnter(gameState)
  -- Spawn one skeleton at a fixed position using the scene's helper
  local GameScene = require("src.scenes.game")
  if GameScene and GameScene.addMonster then
    GameScene.addMonster(350, 350)
  end
end

function Siege.update(dt, gameState)
  -- Siege-specific logic
end

function Siege.draw(gameState)
  -- Optional overlays for siege
end

function Siege.onExit(gameState)
end

return Siege


