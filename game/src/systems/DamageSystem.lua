local System = require("src.core.System")
local FlashEffect = require("src.components.FlashEffect")
local DamageQueue = require("src.DamageQueue")

---@class DamageSystem : System
local DamageSystem = System:extend("DamageSystem", {"Health"})

---Update all entities with Health and DamageEvent components
---@param dt number Delta time
function DamageSystem:update(dt)
    -- Process queued damages once per frame
    if DamageQueue:isProcessing() then
        -- Another instance already processed this frame; skip
        return
    end
    DamageQueue:beginProcessing()

    local queued = DamageQueue:getAll()
    if #queued > 0 then
        print(string.format("DamageQueue: processing %d entries", #queued))
        for i = 1, #queued do
            local e = queued[i]
            if e and e.target and e.target.active ~= false then
                local health = e.target:getComponent("Health")
                if health and not health.isDead then
                    self:processDamageEntry(e.target, health, e)
                end
            end
        end
        DamageQueue:clear()
    end

    DamageQueue:endProcessing()
end

---Process a queued damage entry
---@param entity Entity
---@param health any
---@param entry table
function DamageSystem:processDamageEntry(entity, health, entry)
    if health.isDead then return end
    local wasAlive = health:isAlive()
    health:takeDamage(entry.amount or 0)

    -- Add damage flash effect
    self:addDamageFlash(entity)

    -- Apply knockback impulse directly (sensor-based attack flow)
    if (entry.knockback or 0) > 0 and entry.source then
        local pathfindingCollision = entity:getComponent("PathfindingCollision")
        local sourcePos = entry.source:getComponent("Position")
        local targetPos = entity:getComponent("Position")
        if pathfindingCollision and pathfindingCollision:hasCollider() and sourcePos and targetPos then
            local sourceSprite = entry.source:getComponent("SpriteRenderer")
            local targetSprite = entity:getComponent("SpriteRenderer")
            local sourceCenterX = sourcePos.x + (sourceSprite and sourceSprite.width or 24) / 2
            local sourceCenterY = sourcePos.y + (sourceSprite and sourceSprite.height or 24) / 2
            local targetCenterX = targetPos.x + (targetSprite and targetSprite.width or 24) / 2
            local targetCenterY = targetPos.y + (targetSprite and targetSprite.height or 24) / 2
            local dx = targetCenterX - sourceCenterX
            local dy = targetCenterY - sourceCenterY
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0 then
                local impulseX = (dx / dist) * entry.knockback
                local impulseY = (dy / dist) * entry.knockback
                pathfindingCollision:applyLinearImpulse(impulseX, impulseY)
            end
        end
    end

    if wasAlive and not health:isAlive() then
        self:handleEntityDeath(entity, { amount = entry.amount or 0, source = entry.source })
    end

    -- Effects
    if entry.effects then
        self:applyDamageEffects(entity, entry)
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
    if damageEvent.effects then
        for effect, value in pairs(damageEvent.effects) do
            self:applyEffect(entity, effect, value)
        end
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
-- Event-based damage path removed; damage now flows via DamageQueue only

return DamageSystem
