local GameConstants = require("src.constants")

---@class SiegePhase
local Siege = {}

function Siege.onEnter(gameState)
  -- Spawn one skeleton at a random position (y < 400) using the scene's helper
  local GameScene = require("src.scenes.game")
  if GameScene and GameScene.addMonster then
    local maxX = (GameConstants and GameConstants.WORLD_WIDTH_PIXELS) or 800
    local maxY = 500
    local x = math.random(0, math.max(0, maxX - 1))
    local y = math.random(401, math.max(401, maxY - 1))
    GameScene.addMonster(x, y)
  end
end

function Siege.update(dt, gameState)
  -- When all enemies are dead, return to Discovery phase
  local GameScene = require("src.scenes.game")
  local ecsWorld = GameScene and GameScene.ecsWorld
  if not ecsWorld then return end

  local remaining = 0
  for _, entity in ipairs(ecsWorld.entities or {}) do
    if entity.isSkeleton then
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
end

return Siege


