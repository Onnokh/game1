local GameConstants = require("src.constants")

---@class SiegePhase
local Siege = {}

function Siege.onEnter(gameState)
  -- Darker, moodier ambient for siege
  local GameScene = require("src.scenes.game")
  if GameScene and GameScene.setAmbientColor then
    -- dusk-night tone over 0.8s
    GameScene.setAmbientColor(70, 90, 140, 255, 5)
  end

  -- Spawn one skeleton at a random position (y < 400) using the scene's helper
  local GameScene = require("src.scenes.game")
  if GameScene and GameScene.addMonster then
    local maxX = (GameConstants and GameConstants.WORLD_WIDTH_PIXELS) or 800
    local maxY = 500
    local x = math.random(0, math.max(0, maxX - 1))
    local y = math.random(401, math.max(401, maxY - 1))
    local enemy = GameScene.addMonster(x, y)
    if enemy and enemy.addTag then
      enemy:addTag("SiegeAttacker")
    end
  end
end

function Siege.update(dt, gameState)
  -- When all enemies are dead, return to Discovery phase
  local GameScene = require("src.scenes.game")
  local ecsWorld = GameScene and GameScene.ecsWorld
  if not ecsWorld then return end

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


