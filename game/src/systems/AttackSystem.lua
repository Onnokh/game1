-- Import System base class
local System = require("src.core.System")
local InputHelpers = require("src.utils.input")
local CoordinateUtils = require("src.utils.coordinates")

---@class AttackSystem : System
---@field _lastPreviewTime number Last time a preview was shown
local AttackSystem = setmetatable({}, {__index = System})
AttackSystem.__index = AttackSystem
AttackSystem._lastPreviewTime = 0

---Create a new AttackSystem
---@return AttackSystem|System
function AttackSystem.new()
    local self = System.new({"Position", "Attack"})
    setmetatable(self, AttackSystem)
    return self
end

---Update all entities with Position and Attack components
---@param dt number Delta time
function AttackSystem:update(dt)
    local currentTime = love.timer.getTime()

    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local attack = entity:getComponent("Attack")
        local collision = entity:getComponent("Collision")

        if position and attack and attack.enabled then
            -- Show range preview for player when they're about to attack
            if entity.isPlayer and self:isPlayerAboutToAttack(entity, currentTime) then
                self:showRangePreview(entity, position, attack)
            end

            -- Check for attack input (this assumes the entity has input handling)
            -- For now, we'll check if the entity is the player and handle input
            if self:shouldAttack(entity, currentTime) then
                self:performAttack(entity, position, attack, collision, currentTime)
            end
        end
    end
end

---Check if an entity should attack
---@param entity Entity|{isPlayer:boolean} The entity to check
---@param currentTime number Current game time
---@return boolean True if the entity should attack
function AttackSystem:shouldAttack(entity, currentTime)
    local attack = entity:getComponent("Attack")
    if not attack or not attack:isReady(currentTime) then
        return false
    end

    -- Check if this is the player entity and handle input
    if entity.isPlayer then
        -- Get input state (this would need to be passed from the game state)
        -- For now, we'll use a simple check - this should be improved
        return love.mouse.isDown(1) or love.keyboard.isDown("space")
    end

    -- For AI entities, this would check their AI state
    -- For now, return false for non-player entities
    return false
end

---Perform an attack for an entity
---@param entity Entity The attacking entity
---@param position Position The position component
---@param attack Attack The attack component
---@param collision Collision|nil The collision component
---@param currentTime number Current game time
function AttackSystem:performAttack(entity, position, attack, collision, currentTime)
    if not attack:performAttack(currentTime) then
        return
    end

    -- Find targets within attack range
    local targets = self:findTargetsInRange(entity, position, attack)

    -- Create particle effects for the attack
    self:createAttackParticles(entity, position, attack, targets)

    -- Apply damage to each target
    for _, target in ipairs(targets) do
        self:applyDamageToTarget(entity, target, attack)
    end

    -- Apply knockback if specified
    if attack.knockback > 0 then
        self:applyKnockback(entity, targets, attack)
    end
end

---Find all targets within attack range
---@param attacker Entity The attacking entity
---@param position Position The attacker's position
---@param attack Attack The attack component
---@return table Array of target entities
function AttackSystem:findTargetsInRange(attacker, position, attack)
    local targets = {}
    local world = attacker._world

    if not world then
        return targets
    end

    -- Get all entities with Health component (potential targets)
    local potentialTargets = world:getEntitiesWith({"Health"})

    for _, target in ipairs(potentialTargets) do
        -- Skip self
        if target.id ~= attacker.id then
            local targetPosition = target:getComponent("Position")
            if targetPosition then
                -- Use visual centers for consistent distance calculation
                local attackerCenterX, attackerCenterY = self:getEntityVisualCenter(attacker, position)
                local targetCenterX, targetCenterY = self:getEntityVisualCenter(target, targetPosition)
                local distance = CoordinateUtils.calculateDistanceBetweenPoints(attackerCenterX, attackerCenterY, targetCenterX, targetCenterY)
                if distance <= attack.range then
                    table.insert(targets, target)
                end
            end
        end
    end

    return targets
end


---Apply damage to a target entity
---@param attacker Entity The attacking entity
---@param target Entity The target entity
---@param attack Attack The attack component
function AttackSystem:applyDamageToTarget(attacker, target, attack)
    -- Create a damage event and add it to the target
    local DamageEvent = require("src.components.DamageEvent")
    local damageEvent = DamageEvent.new(attack.damage, attacker, "physical", attack.knockback)

    -- Add the damage event to the target entity
    target:addComponent("DamageEvent", damageEvent)
end

---Apply knockback to targets
---@param attacker Entity The attacking entity
---@param targets table Array of target entities
---@param attack Attack The attack component
function AttackSystem:applyKnockback(attacker, targets, attack)
    local attackerPosition = attacker:getComponent("Position")
    if not attackerPosition then
        return
    end

    for _, target in ipairs(targets) do
        local targetPosition = target:getComponent("Position")
        local targetMovement = target:getComponent("Movement")

        if targetPosition and targetMovement then
            -- Calculate knockback direction using visual centers
            local attackerCenterX, attackerCenterY = self:getEntityVisualCenter(attacker, attackerPosition)
            local targetCenterX, targetCenterY = self:getEntityVisualCenter(target, targetPosition)
            local dx = targetCenterX - attackerCenterX
            local dy = targetCenterY - attackerCenterY
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance > 0 then
                -- Normalize direction and apply knockback force
                local knockbackX = (dx / distance) * attack.knockback
                local knockbackY = (dy / distance) * attack.knockback

                -- Apply knockback to movement velocity
                targetMovement.velocityX = targetMovement.velocityX + knockbackX
                targetMovement.velocityY = targetMovement.velocityY + knockbackY
            end
        end
    end
end

---Create particle effects for an attack
---@param attacker Entity The attacking entity
---@param position Position The attacker's position
---@param attack Attack The attack component
---@param targets table Array of target entities
function AttackSystem:createAttackParticles(attacker, position, attack, targets)
    -- Get or create a particle system for the attacker
    local particleSystem = attacker:getComponent("ParticleSystem")
    if not particleSystem then
        local ParticleSystem = require("src.components.ParticleSystem")
        particleSystem = ParticleSystem.new(200, 0, 0) -- max particles, gravity, wind
        attacker:addComponent("ParticleSystem", particleSystem)
    end

    -- Get the visual center of the entity (account for sprite size)
    local centerX, centerY = self:getEntityVisualCenter(attacker, position)

    -- Create different particle effects based on attack type
    if attack.attackType == "melee" then
        -- Create a clear range indicator with particles around the circumference
        self:createRangeIndicator(particleSystem, centerX, centerY, attack.range)

        -- Create impact particles for each target hit
        for _, target in ipairs(targets) do
            local targetPosition = target:getComponent("Position")
            if targetPosition then
                local targetCenterX, targetCenterY = self:getEntityVisualCenter(target, targetPosition)
                local impactColor = {r = 1, g = 0.2, b = 0.2, a = 1} -- Red impact
                particleSystem:createBurst(targetCenterX, targetCenterY, 8, 8, 0.3, impactColor, 2)
            end
        end

        -- Create slash effect particles
        local slashCount = math.min(12, #targets * 2 + 6)
        local slashColor = {r = 1, g = 0.9, b = 0.3, a = 0.9} -- Bright golden slash
        particleSystem:createBurst(centerX, centerY, attack.range * 0.6, slashCount, 0.3, slashColor, 1.5)

    elseif attack.attackType == "ranged" then
        -- Create a line of particles from attacker to targets
        for _, target in ipairs(targets) do
            local targetPosition = target:getComponent("Position")
            if targetPosition then
                local targetCenterX, targetCenterY = self:getEntityVisualCenter(target, targetPosition)
                local projectileColor = {r = 0.2, g = 0.8, b = 1, a = 0.9} -- Blue projectile
                particleSystem:createLine(centerX, centerY, targetCenterX, targetCenterY, 12, 0.3, projectileColor, 1.5)
            end
        end
    end
end

---Check if player is about to attack (mouse button held down)
---@param entity Entity|{isPlayer:boolean} The entity to check
---@param currentTime number Current game time
---@return boolean True if player is about to attack
function AttackSystem:isPlayerAboutToAttack(entity, currentTime)
    if not entity.isPlayer then
        return false
    end

    local attack = entity:getComponent("Attack")
    if not attack or not attack:isReady(currentTime) then
        return false
    end

    -- Check if mouse button is held down (about to attack)
    return love.mouse.isDown(1) or love.keyboard.isDown("space")
end

---Show a preview of the attack range
---@param entity Entity The attacking entity
---@param position Position The position component
---@param attack Attack The attack component
function AttackSystem:showRangePreview(entity, position, attack)
    -- Get or create a particle system for the attacker
    local particleSystem = entity:getComponent("ParticleSystem")
    if not particleSystem then
        local ParticleSystem = require("src.components.ParticleSystem")
        particleSystem = ParticleSystem.new(200, 0, 0)
        entity:addComponent("ParticleSystem", particleSystem)
    end

    -- Only show preview occasionally to avoid particle spam
    local currentTime = love.timer.getTime()
    if (currentTime - AttackSystem._lastPreviewTime) > 0.1 then
        AttackSystem._lastPreviewTime = currentTime

        -- Get the visual center of the entity (account for sprite size)
        local centerX, centerY = self:getEntityVisualCenter(entity, position)

        -- Create subtle range preview particles
        local previewColor = {r = 1, g = 1, b = 0.3, a = 0.3} -- Dim yellow
        local previewCount = math.floor(attack.range * 0.3)

        for i = 1, previewCount do
            local angle = (i / previewCount) * math.pi * 2
            local px = centerX + math.cos(angle) * attack.range
            local py = centerY + math.sin(angle) * attack.range

            particleSystem:addParticle(px, py, 0, 0, 0.2, previewColor, 1, true)
        end
    end
end

---Create a clear range indicator showing the attack radius
---@param particleSystem any The particle system to add particles to
---@param x number Center X position
---@param y number Center Y position
---@param radius number Attack radius
function AttackSystem:createRangeIndicator(particleSystem, x, y, radius)
    -- Create particles around the circumference to show the exact range
    local rangeColor = {r = 1, g = 1, b = 0.5, a = 0.8} -- Bright yellow for visibility
    local particleCount = math.floor(radius * 0.8) -- More particles for larger ranges

    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local px = x + math.cos(angle) * radius
        local py = y + math.sin(angle) * radius

        -- Add some variation to make it look more natural
        local variation = 2
        px = px + (math.random() - 0.5) * variation
        py = py + (math.random() - 0.5) * variation

        -- Create particles that fade out quickly to show the range
        particleSystem:addParticle(px, py, 0, 0, 0.6, rangeColor, 2, true)
    end

    -- Add some inner particles to fill the range area
    local innerCount = math.floor(particleCount * 0.3)
    for i = 1, innerCount do
        local angle = math.random() * math.pi * 2
        local distance = math.random() * radius * 0.7
        local px = x + math.cos(angle) * distance
        local py = y + math.sin(angle) * distance

        local innerColor = {r = 1, g = 0.8, b = 0.2, a = 0.4} -- Dimmer inner particles
        particleSystem:addParticle(px, py, 0, 0, 0.4, innerColor, 1.5, true)
    end
end

---Get the visual center of an entity (accounting for sprite size)
---@param entity Entity The entity to get the center of
---@param position Position The position component
---@return number, number Center X and Y coordinates
function AttackSystem:getEntityVisualCenter(entity, position)
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer then
        -- Account for sprite size and any offsets
        local centerX = position.x + (spriteRenderer.width or 24) / 2
        local centerY = position.y + (spriteRenderer.height or 24) / 2
        return centerX, centerY
    else
        -- Fallback to position if no sprite renderer
        return position.x, position.y
    end
end

return AttackSystem
