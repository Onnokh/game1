---@class Health
---@field current number Current health value
---@field max number Maximum health value
---@field isDead boolean Whether the entity is dead
local Health = {}
Health.__index = Health

---Create a new Health component
---@param maxHealth number Maximum health value
---@param currentHealth number|nil Current health value, defaults to maxHealth
---@return Component|Health
function Health.new(maxHealth, currentHealth)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Health"), Health)

    self.max = maxHealth or 100
    self.current = currentHealth or self.max
    self.isDead = false

    return self
end

---Take damage and reduce health
---@param damage number Amount of damage to take
---@return boolean Whether the entity is still alive after taking damage
function Health:takeDamage(damage)
    if self.isDead then
        return false
    end

    self.current = math.max(0, self.current - damage)

    if self.current <= 0 then
        self.isDead = true
        return false
    end

    return true
end

---Heal and restore health
---@param amount number Amount of health to restore
---@return number Actual amount healed
function Health:heal(amount)
    if self.isDead then
        return 0
    end

    local oldHealth = self.current
    self.current = math.min(self.max, self.current + amount)
    return self.current - oldHealth
end

---Set health to a specific value
---@param value number Health value to set
function Health:setHealth(value)
    self.current = math.max(0, math.min(self.max, value))
    self.isDead = self.current <= 0
end

---Set maximum health
---@param value number New maximum health value
function Health:setMaxHealth(value)
    self.max = math.max(1, value)
    if self.current > self.max then
        self.current = self.max
    end
end

---Get health percentage (0-1)
---@return number Health percentage
function Health:getHealthPercentage()
    return self.current / self.max
end

---Check if the entity is at full health
---@return boolean True if at full health
function Health:isFullHealth()
    return self.current >= self.max
end

---Check if the entity is alive
---@return boolean True if alive
function Health:isAlive()
    return not self.isDead
end

---Revive the entity (set to full health and mark as alive)
function Health:revive()
    self.current = self.max
    self.isDead = false
end

---Get health status as a string
---@return string Health status string
function Health:getStatus()
    if self.isDead then
        return "Dead"
    elseif self:isFullHealth() then
        return "Full Health"
    else
        return string.format("%.0f%% Health", self:getHealthPercentage() * 100)
    end
end

return Health
