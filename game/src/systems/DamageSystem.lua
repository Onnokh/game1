local System = require("src.core.System")
local EventBus = require("src.utils.EventBus")
local FlashEffect = require("src.components.FlashEffect")
local DamageQueue = require("src.DamageQueue")

-- Local constants to avoid magic numbers and repeated allocations
local DEFAULT_SPRITE_W = 24
local DEFAULT_SPRITE_H = 24

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
    local amount = entry.amount or 0
    health:takeDamage(amount)

    -- Emit UI-facing event
    EventBus.emit("entityDamaged", { target = entity, amount = amount, source = entry.source })

    -- Add damage flash effect
    self:addDamageFlash(entity)

    -- Apply knockback impulse directly (sensor-based attack flow)
    if (entry.knockback or 0) > 0 and entry.source then
        self:applyKnockback(entity, entry.source, entry.knockback)
    end

    if wasAlive and not health:isAlive() then
        self:handleEntityDeath(entity, { amount = entry.amount or 0, source = entry.source })
    end

    -- Effects
    if entry.effects then
        self:applyDamageEffects(entity, entry)
    end

    -- Damage numbers are now handled by UISystems.DamagePopupSystem via EventBus
end

---Handle entity death
---@param entity Entity The entity that died
---@param damageEvent any The damage event that caused death
function DamageSystem:handleEntityDeath(entity, damageEvent)
    entity.isDead = true
    print(string.format("Entity died from %d damage", damageEvent.amount))

    -- Emit entity death event for other systems to handle
    EventBus.emit("entityDied", {
        entity = entity,
        amount = damageEvent.amount,
        source = damageEvent.source
    })

    -- Check if this is a skeleton that should go into dying state
    local stateMachine = entity:getComponent("StateMachine")
    if stateMachine and stateMachine.states and stateMachine.states["dying"] then
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
---@param target Entity The entity to apply knockback to
---@param source Entity The source that caused the knockback
---@param force number Knockback force
function DamageSystem:applyKnockback(target, source, force)
    local physicsBody = target:getComponent("PathfindingCollision")
    local sourcePos = source and source:getComponent("Position") or nil
    local targetPos = target:getComponent("Position")
    if not (physicsBody and physicsBody:hasCollider() and sourcePos and targetPos) then
        return
    end

    local sourceSprite = source:getComponent("SpriteRenderer")
    local targetSprite = target:getComponent("SpriteRenderer")

    local sourceCenterX = sourcePos.x + (sourceSprite and sourceSprite.width or DEFAULT_SPRITE_W) / 2
    local sourceCenterY = sourcePos.y + (sourceSprite and sourceSprite.height or DEFAULT_SPRITE_H) / 2
    local targetCenterX = targetPos.x + (targetSprite and targetSprite.width or DEFAULT_SPRITE_W) / 2
    local targetCenterY = targetPos.y + (targetSprite and targetSprite.height or DEFAULT_SPRITE_H) / 2

    local dx = targetCenterX - sourceCenterX
    local dy = targetCenterY - sourceCenterY
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= 0 then return end

    local impulseX = (dx / dist) * force
    local impulseY = (dy / dist) * force
    physicsBody:applyLinearImpulse(impulseX, impulseY)

    -- Toggle existing knockback component (no churn)
    local Knockback = require("src.components.Knockback")
    local kb = target:getComponent("Knockback")
    if not kb then
        kb = Knockback.new(dx / dist, dy / dist, force, 0.2)
        target:addComponent("Knockback", kb)
    end
    kb.x = dx / dist
    kb.y = dy / dist
    kb.power = force
    kb.duration = 0.15
    kb.timer = 0
    kb.active = true
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


-- Damage creation helper was removed; damage now flows via DamageQueue only

return DamageSystem
