local System = require("src.core.System")
local GameState = require("src.core.GameState")
local EntityUtils = require("src.utils.entities")

---@class AutoAimSystem : System
---System that automatically aims at and shoots the closest enemy when auto-aim is enabled
---@field lastAutoShootTime number Time of last auto-shot
---@field autoShootCooldown number Minimum time between auto-shots
local AutoAimSystem = System:extend("AutoAimSystem", {})

---Create a new AutoAimSystem
---@return AutoAimSystem
function AutoAimSystem.new()
    local self = System.new()
    setmetatable(self, AutoAimSystem)
    self.lastAutoShootTime = 0
    self.autoShootCooldown = 0.1 -- Minimum time between auto-shots (100ms)
    self.wasAutoShooting = false -- Track if we were auto-shooting last frame
    return self
end

---Update auto-aim targeting
---@param dt number Delta time
function AutoAimSystem:update(dt)
  if not GameState.input.autoAim then
    return -- Only run when auto-aim is enabled
  end

  local player = self.world:getPlayer()
  if not player or player.isDead then
    return
  end

  local playerPos = player:getComponent("Position")
  if not playerPos then return end

  local playerCenterX, playerCenterY = EntityUtils.getEntityVisualCenter(player, playerPos)

  -- Find all living monsters
  local monsters = self.world:getEntitiesWithTag("Monster")
  local closestEnemy = nil
  local closestDistance = math.huge

  for _, enemy in ipairs(monsters) do
    if not enemy.isDead then
      local health = enemy:getComponent("Health")
      local enemyPos = enemy:getComponent("Position")

      if health and health:isAlive() and enemyPos then
        local enemyCenterX, enemyCenterY = EntityUtils.getEntityVisualCenter(enemy, enemyPos)
        local dx = enemyCenterX - playerCenterX
        local dy = enemyCenterY - playerCenterY
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance < closestDistance then
          closestDistance = distance
          closestEnemy = enemy
        end
      end
    end
  end

  -- Update mouse position to aim at closest enemy and auto-shoot
  if closestEnemy then
    local enemyPos = closestEnemy:getComponent("Position")
    local enemyCenterX, enemyCenterY = EntityUtils.getEntityVisualCenter(closestEnemy, enemyPos)
    GameState.input.mouseX = enemyCenterX
    GameState.input.mouseY = enemyCenterY

    -- Auto-shoot when there's a target
    local currentTime = love.timer.getTime()
    if currentTime - self.lastAutoShootTime >= self.autoShootCooldown then
      GameState.input.attack = true
      self.lastAutoShootTime = currentTime
      self.wasAutoShooting = true
    end
  else
    -- No enemy found
    if self.wasAutoShooting then
      -- We were auto-shooting but now no target, stop shooting
      GameState.input.attack = false
      self.wasAutoShooting = false
    end
    -- Don't override mouse position - let GameState.updateMousePosition() handle it
  end
end

return AutoAimSystem
