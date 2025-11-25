local Component = require("src.core.Component")

---@class Attack : Component
---@field damage number Amount of damage this attack deals (only used for entities without Ability component)
---@field range number Range of the attack (used to position the attack collider)
---@field cooldown number Cooldown time between attacks in seconds (only used for entities without Ability component)
---@field lastAttackTime number Time when the last attack was performed (only used for entities without Ability component)
---@field enabled boolean Whether the attack is enabled
---@field attackType string Type of attack ("ranged")
---@field knockback number Knockback force applied to targets (only used for entities without Ability component)
---@field attackDirectionX number X component of attack direction
---@field attackDirectionY number Y component of attack direction
---@field attackAngleRad number Angle of attack in radians (from +X axis)
---@field hitAreaX number X of spawned attack collider AABB
---@field hitAreaY number Y of spawned attack collider AABB
---@field hitAreaWidth number Width of spawned attack collider AABB
---@field hitAreaHeight number Height of spawned attack collider AABB
local Attack = {}
Attack.__index = Attack

---Create a new Attack component
---Used to track attack execution state (timing, direction, hit area)
---For entities with Ability component: attack stats come from Ability, cooldown tracked per-ability
---For entities without Ability component: attack stats stored here (monsters)
---@param damage number|nil Amount of damage this attack deals (optional, for entities without Ability)
---@param range number|nil Range of the attack (optional)
---@param cooldown number|nil Cooldown time between attacks (optional, only used for entities without Ability)
---@param attackType string|nil Type of attack (optional)
---@param knockback number|nil Knockback force (optional, for entities without Ability)
---@return Component|Attack
function Attack.new(damage, range, cooldown, attackType, knockback)
    local self = setmetatable(Component.new("Attack"), Attack)

    -- Attack execution state
    self.lastAttackTime = 0
    self.enabled = true

    -- Casting state
    self.isCasting = false
    self.castStartTime = 0
    self.castDuration = 0
    self.castAbilityId = nil

    -- Attack direction (calculated when attacking)
    self.attackDirectionX = 0
    self.attackDirectionY = 0
    self.attackAngleRad = 0

    -- Hit area (calculated when attacking)
    self.hitAreaX = 0
    self.hitAreaY = 0
    self.hitAreaWidth = 8
    self.hitAreaHeight = 8

    -- Attack stats (only used for entities without Ability component, e.g., monsters)
    self.damage = damage or 0
    self.range = range or 0
    self.cooldown = cooldown or 0
    self.attackType = attackType or "ranged"
    self.knockback = knockback or 0

    return self
end

---Check if the attack is ready (cooldown has passed)
---Note: Only used for entities without Ability component. Entities with Ability use per-ability cooldowns.
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
---@param skipCooldownCheck boolean|nil If true, skip cooldown check (for entities with Ability component that use per-ability cooldowns)
---@return boolean True if attack was performed successfully
function Attack:performAttack(currentTime, skipCooldownCheck)
    -- Skip cooldown check for entities with Ability component (they use per-ability cooldowns)
    if not skipCooldownCheck and not self:isReady(currentTime) then
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

---Start casting an ability
---@param abilityId string The ability ID being cast
---@param castTime number Cast duration in seconds
---@param currentTime number Current game time
function Attack:startCast(abilityId, castTime, currentTime)
    self.isCasting = true
    self.castStartTime = currentTime
    self.castDuration = castTime
    self.castAbilityId = abilityId
end

---Update cast progress and check if complete
---@param currentTime number Current game time
---@return boolean True if cast is complete
function Attack:updateCast(currentTime)
    if not self.isCasting then
        return false
    end

    local elapsed = currentTime - self.castStartTime
    if elapsed >= self.castDuration then
        self.isCasting = false
        return true
    end

    return false
end

---Cancel the current cast
function Attack:cancelCast()
    self.isCasting = false
    self.castStartTime = 0
    self.castDuration = 0
    self.castAbilityId = nil
end

---Check if cast is complete
---@param currentTime number Current game time
---@return boolean True if cast is complete
function Attack:isCastComplete(currentTime)
    if not self.isCasting then
        return false
    end
    return self:updateCast(currentTime)
end

---Get cast progress (0-1)
---@param currentTime number Current game time
---@return number Cast progress from 0 to 1
function Attack:getCastProgress(currentTime)
    if not self.isCasting or self.castDuration <= 0 then
        return 0
    end

    local elapsed = currentTime - self.castStartTime
    return math.min(1.0, math.max(0, elapsed / self.castDuration))
end

---Set the attack direction
---@param directionX number X component of attack direction
---@param directionY number Y component of attack direction
function Attack:setDirection(directionX, directionY)
    self.attackDirectionX = directionX
    self.attackDirectionY = directionY
    -- Cache angle for consumers (e.g., rotating colliders)
    if directionX ~= 0 or directionY ~= 0 then
        self.attackAngleRad = math.atan2(directionY, directionX)
    end
end

---Calculate and set the hit area based on attacker position and direction
---@param attackerX number Attacker X position
---@param attackerY number Attacker Y position
---@param range number|nil Range to use (optional, uses self.range if not provided)
function Attack:calculateHitArea(attackerX, attackerY, range)
    -- Use provided range or fall back to self.range (must be > 0)
    local attackRange = range or self.range
    if attackRange <= 0 then
        attackRange = 15 -- Fallback
    end
    -- Normalize direction
    local length = math.sqrt(self.attackDirectionX * self.attackDirectionX + self.attackDirectionY * self.attackDirectionY)
    if length > 0 then
        local normalizedX = self.attackDirectionX / length
        local normalizedY = self.attackDirectionY / length

        -- Use an oriented rectangle: length along local X, small thickness along local Y
        -- Make the length equal to the attack range for clear rotation visibility
        local orientedLength = attackRange
        local orientedThickness = self.hitAreaHeight > 0 and self.hitAreaHeight or 8
        self.hitAreaWidth = orientedLength
        self.hitAreaHeight = orientedThickness

        -- Place the rectangle center halfway along the direction from the attacker
        -- with an 8px offset to push it away from the player center
        local offset = 8
        local centerX = attackerX + normalizedX * (orientedLength / 2 + offset)
        local centerY = attackerY + normalizedY * (orientedLength / 2 + offset)

        -- Store as AABB top-left, since fixture creation uses x+w/2/y+h/2 for body center
        self.hitAreaX = centerX - (self.hitAreaWidth / 2)
        self.hitAreaY = centerY - (self.hitAreaHeight / 2)
    else
        -- Default to a horizontal blade to the right if no direction
        local orientedLength = attackRange
        local orientedThickness = self.hitAreaHeight > 0 and self.hitAreaHeight or 8
        self.hitAreaWidth = orientedLength
        self.hitAreaHeight = orientedThickness
        local centerX = attackerX + (orientedLength / 2)
        local centerY = attackerY
        self.hitAreaX = centerX - (self.hitAreaWidth / 2)
        self.hitAreaY = centerY - (self.hitAreaHeight / 2)
    end
end

---Serialize the Attack component for saving
---@return table Serialized attack data
function Attack:serialize()
    return {
        damage = self.damage,
        range = self.range,
        cooldown = self.cooldown,
        lastAttackTime = self.lastAttackTime,
        enabled = self.enabled,
        attackType = self.attackType,
        knockback = self.knockback,
        attackDirectionX = self.attackDirectionX,
        attackDirectionY = self.attackDirectionY,
        attackAngleRad = self.attackAngleRad,
        isCasting = self.isCasting,
        castStartTime = self.castStartTime,
        castDuration = self.castDuration,
        castAbilityId = self.castAbilityId
    }
end

---Deserialize Attack component from saved data
---@param data table Serialized attack data
---@return Attack Recreated Attack component
function Attack.deserialize(data)
    local attack = Attack.new(data.damage, data.range, data.cooldown, data.attackType, data.knockback)
    attack.lastAttackTime = data.lastAttackTime or 0
    attack.enabled = data.enabled ~= false
    attack.attackDirectionX = data.attackDirectionX or 0
    attack.attackDirectionY = data.attackDirectionY or 0
    attack.attackAngleRad = data.attackAngleRad or 0
    attack.isCasting = data.isCasting or false
    attack.castStartTime = data.castStartTime or 0
    attack.castDuration = data.castDuration or 0
    attack.castAbilityId = data.castAbilityId or nil
    return attack
end

return Attack
