local Component = require("src.core.Component")

---@class Attack : Component
---@field damage number Amount of damage this attack deals
---@field range number Range of the attack
---@field cooldown number Cooldown time between attacks in seconds
---@field lastAttackTime number Time when the last attack was performed
---@field enabled boolean Whether the attack is enabled
---@field attackType string Type of attack ("melee", "ranged", etc.)
---@field knockback number Knockback force applied to targets
---@field attackDirectionX number X component of attack direction
---@field attackDirectionY number Y component of attack direction
---@field hitAreaX number X position of attack hit area
---@field hitAreaY number Y position of attack hit area
---@field hitAreaWidth number Width of attack hit area
---@field hitAreaHeight number Height of attack hit area
local Attack = {}
Attack.__index = Attack

---Create a new Attack component
---@param damage number|nil Amount of damage this attack deals
---@param range number|nil Range of the attack
---@param cooldown number|nil Cooldown time between attacks in seconds
---@param attackType string|nil Type of attack ("melee", "ranged", etc.)
---@param knockback number|nil Knockback force applied to targets
---@return Component|Attack
function Attack.new(damage, range, cooldown, attackType, knockback)
    local self = setmetatable(Component.new("Attack"), Attack)

    self.damage = damage or 10
    self.range = range or 32
    self.cooldown = cooldown or 1.0
    self.lastAttackTime = 0
    self.enabled = true
    self.attackType = attackType or "melee"
    self.knockback = knockback or 0
    self.attackDirectionX = 0
    self.attackDirectionY = 0
    self.hitAreaX = 0
    self.hitAreaY = 0
    self.hitAreaWidth = 16
    self.hitAreaHeight = 16

    return self
end

---Check if the attack is ready (cooldown has passed)
---@param currentTime number Current game time
---@return boolean True if attack is ready
function Attack:isReady(currentTime)
    if not self.enabled then
        return false
    end
    return (currentTime - self.lastAttackTime) >= self.cooldown
end

---Perform an attack and update the last attack time
---@param currentTime number Current game time
---@return boolean True if attack was performed successfully
function Attack:performAttack(currentTime)
    if not self:isReady(currentTime) then
        return false
    end

    self.lastAttackTime = currentTime
    return true
end

---Set the attack damage
---@param damage number New damage value
function Attack:setDamage(damage)
    self.damage = math.max(0, damage)
end

---Set the attack range
---@param range number New range value
function Attack:setRange(range)
    self.range = math.max(0, range)
end

---Set the attack cooldown
---@param cooldown number New cooldown value in seconds
function Attack:setCooldown(cooldown)
    self.cooldown = math.max(0, cooldown)
end

---Enable or disable the attack
---@param enabled boolean Whether the attack should be enabled
function Attack:setEnabled(enabled)
    self.enabled = enabled
end

---Get the remaining cooldown time
---@param currentTime number Current game time
---@return number Remaining cooldown time in seconds
function Attack:getRemainingCooldown(currentTime)
    if not self.enabled then
        return self.cooldown
    end
    return math.max(0, self.cooldown - (currentTime - self.lastAttackTime))
end

---Get cooldown percentage (0-1)
---@param currentTime number Current game time
---@return number Cooldown percentage
function Attack:getCooldownPercentage(currentTime)
    if not self.enabled then
        return 1.0
    end
    return math.min(1.0, self:getRemainingCooldown(currentTime) / self.cooldown)
end

---Set the attack direction
---@param directionX number X component of attack direction
---@param directionY number Y component of attack direction
function Attack:setDirection(directionX, directionY)
    self.attackDirectionX = directionX
    self.attackDirectionY = directionY
end

---Calculate and set the hit area based on attacker position and direction
---@param attackerX number Attacker X position
---@param attackerY number Attacker Y position
function Attack:calculateHitArea(attackerX, attackerY)
    -- Normalize direction
    local length = math.sqrt(self.attackDirectionX * self.attackDirectionX + self.attackDirectionY * self.attackDirectionY)
    if length > 0 then
        local normalizedX = self.attackDirectionX / length
        local normalizedY = self.attackDirectionY / length

        -- Position hit area at the end of the attack range
        self.hitAreaX = attackerX + normalizedX * self.range - self.hitAreaWidth / 2
        self.hitAreaY = attackerY + normalizedY * self.range - self.hitAreaHeight / 2
    else
        -- Default to right if no direction
        self.hitAreaX = attackerX + self.range - self.hitAreaWidth / 2
        self.hitAreaY = attackerY - self.hitAreaHeight / 2
    end
end

return Attack
