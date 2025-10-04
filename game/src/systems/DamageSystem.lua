-- Import System base class
local System = require("src.core.System")
local FlashEffect = require("src.components.FlashEffect")

---@class DamageSystem : System
local DamageSystem = setmetatable({}, {__index = System})
DamageSystem.__index = DamageSystem

---Create a new DamageSystem
---@return DamageSystem|System
function DamageSystem.new()
    local self = System.new({"Health", "DamageEvent"})
    setmetatable(self, DamageSystem)
    return self
end

---Update all entities with Health and DamageEvent components
---@param dt number Delta time
function DamageSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local health = entity:getComponent("Health")
        local damageEvent = entity:getComponent("DamageEvent")

        if health and damageEvent then
            -- Apply damage
            self:processDamageEvent(entity, health, damageEvent)

            -- Remove the damage event after processing
            entity:removeComponent("DamageEvent")
        end
    end
end

---Process a damage event and apply damage to the entity
---@param entity Entity The entity taking damage
---@param health any The health component
---@param damageEvent any The damage event component
function DamageSystem:processDamageEvent(entity, health, damageEvent)
    if health.isDead then
        return
    end

    -- Apply the damage
    local wasAlive = health:isAlive()
    health:takeDamage(damageEvent.amount)

    -- Add damage flash effect
    self:addDamageFlash(entity)

    -- Handle death if the entity died
    if wasAlive and not health:isAlive() then
        self:handleEntityDeath(entity, damageEvent)
    end

    -- Apply any additional effects
    self:applyDamageEffects(entity, damageEvent)

    -- Apply knockback if specified
    if damageEvent.knockback > 0 then
        self:applyKnockback(entity, damageEvent)
    end
end

---Handle entity death
---@param entity Entity The entity that died
---@param damageEvent any The damage event that caused death
function DamageSystem:handleEntityDeath(entity, damageEvent)
    print(string.format("Entity died from %d damage", damageEvent.amount))

    -- Check if this is a skeleton that should go into dying state
    local stateMachine = entity:getComponent("StateMachine")
    if stateMachine and stateMachine.states and stateMachine.states["dying"] then
        -- Set skeleton to dying state instead of immediately deactivating
        stateMachine:changeState("dying", entity)
        print("Skeleton entering dying state")
    else
        -- For other entities, mark as inactive immediately
        entity.active = false
    end

    -- You can add death effects here:
    -- - Play death animation
    -- - Drop items
    -- - Spawn particles
    -- - Play death sound

    -- If this was a monster, you might want to:
    -- - Add score
    -- - Spawn loot
    -- - Trigger events
end

---Apply additional damage effects
---@param entity Entity The entity taking damage
---@param damageEvent any The damage event
function DamageSystem:applyDamageEffects(entity, damageEvent)
    -- Apply any effects specified in the damage event
    for effect, value in pairs(damageEvent.effects) do
        self:applyEffect(entity, effect, value)
    end
end

---Apply a specific effect to an entity
---@param entity Entity The entity to apply the effect to
---@param effect string The effect name
---@param value any The effect value
function DamageSystem:applyEffect(entity, effect, value)
    -- Handle different effect types
    if effect == "poison" then
        -- Apply poison effect (could add a Poison component)
        print(string.format("Applied poison effect: %s", tostring(value)))
    elseif effect == "burn" then
        -- Apply burn effect
        print(string.format("Applied burn effect: %s", tostring(value)))
    elseif effect == "freeze" then
        -- Apply freeze effect
        print(string.format("Applied freeze effect: %s", tostring(value)))
    elseif effect == "stun" then
        -- Apply stun effect
        print(string.format("Applied stun effect: %s", tostring(value)))
    else
        -- Unknown effect
        print(string.format("Unknown effect: %s = %s", effect, tostring(value)))
    end
end

---Apply knockback to an entity
---@param entity Entity The entity to apply knockback to
---@param damageEvent any The damage event containing knockback info
function DamageSystem:applyKnockback(entity, damageEvent)
    local movement = entity:getComponent("Movement")
    local position = entity:getComponent("Position")

    if not movement or not position then
        return
    end

    -- Get the source entity position for knockback direction
    local sourcePosition = nil
    if damageEvent.source then
        sourcePosition = damageEvent.source:getComponent("Position")
    end

    if sourcePosition then
        -- Calculate knockback direction from source to target using visual centers
        local sourceSpriteRenderer = damageEvent.source:getComponent("SpriteRenderer")
        local targetSpriteRenderer = entity:getComponent("SpriteRenderer")

        local sourceCenterX = sourcePosition.x + (sourceSpriteRenderer and sourceSpriteRenderer.width or 24) / 2
        local sourceCenterY = sourcePosition.y + (sourceSpriteRenderer and sourceSpriteRenderer.height or 24) / 2
        local targetCenterX = position.x + (targetSpriteRenderer and targetSpriteRenderer.width or 24) / 2
        local targetCenterY = position.y + (targetSpriteRenderer and targetSpriteRenderer.height or 24) / 2

        local dx = targetCenterX - sourceCenterX
        local dy = targetCenterY - sourceCenterY
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance > 0 then
            -- Normalize direction and apply knockback force
            local knockbackX = (dx / distance) * damageEvent.knockback
            local knockbackY = (dy / distance) * damageEvent.knockback

            -- Apply knockback to movement velocity
            movement.velocityX = movement.velocityX + knockbackX
            movement.velocityY = movement.velocityY + knockbackY
        end
    end
end

---Add damage flash effect to an entity
---@param entity Entity The entity to flash
function DamageSystem:addDamageFlash(entity)
    -- Check if entity already has a flash effect component
    local existingFlash = entity:getComponent("FlashEffect")
    if existingFlash then
        -- Restart the existing flash
        existingFlash:startFlash()
    else
        -- Create new flash effect component
        local flashEffect = FlashEffect.new(0.5) -- 0.5 second flash
        flashEffect:startFlash()
        entity:addComponent("FlashEffect", flashEffect)
    end
end

---Create a damage event for an entity
---@param entity Entity The entity to damage
---@param amount number Amount of damage
---@param source Entity|nil Source of the damage
---@param damageType string|nil Type of damage
---@param knockback number|nil Knockback force
---@param effects table|nil Additional effects
function DamageSystem:createDamageEvent(entity, amount, source, damageType, knockback, effects)
    local DamageEvent = require("src.components.DamageEvent")
    local damageEvent = DamageEvent.new(amount, source, damageType, knockback, effects)

    -- Add the damage event to the entity
    entity:addComponent("DamageEvent", damageEvent)
end

return DamageSystem
