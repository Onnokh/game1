-- Import System base class
local System = require("src.core.System")
local InputHelpers = require("src.utils.input")
local CoordinateUtils = require("src.utils.coordinates")

---@class AttackSystem : System
local AttackSystem = setmetatable({}, {__index = System})
AttackSystem.__index = AttackSystem

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
        -- Get input state from game state
        local GameState = require("src.core.GameState")
        if GameState and GameState.input then
            return GameState.input.attack
        end
        return false
    end

    -- For AI entities, this would check their AI state
    -- For now, return false for non-player entities
    return false
end

---Perform an attack for an entity
---@param entity Entity|{isPlayer:boolean} The attacking entity
---@param position Position The position component
---@param attack Attack The attack component
---@param collision Collision|nil The collision component
---@param currentTime number Current game time
function AttackSystem:performAttack(entity, position, attack, collision, currentTime)
    if not attack:performAttack(currentTime) then
        return
    end

    -- Calculate attack direction for player entities
    if entity.isPlayer then
        self:calculatePlayerAttackDirection(entity, position, attack)
    end

    -- Find targets within attack area
    local targets = self:findTargetsInAttackArea(entity, position, attack)

    -- Apply damage to each target
    for _, target in ipairs(targets) do
        self:applyDamageToTarget(entity, target, attack)
    end

    -- Apply knockback if specified
    if attack.knockback > 0 then
        self:applyKnockback(entity, targets, attack)
    end
end

---Calculate attack direction for player based on mouse position
---@param entity Entity|{isPlayer:boolean} The attacking entity
---@param position Position The attacker's position
---@param attack Attack The attack component
function AttackSystem:calculatePlayerAttackDirection(entity, position, attack)
    local GameState = require("src.core.GameState")
    if not GameState or not GameState.input then
        return
    end

    -- Get mouse position in world coordinates
    local mouseX = GameState.input.mouseX
    local mouseY = GameState.input.mouseY

    -- Get player's visual center (accounting for sprite size)
    local playerCenterX, playerCenterY = self:getEntityVisualCenter(entity, position)

    -- Calculate direction from player center to mouse
    local directionX = mouseX - playerCenterX
    local directionY = mouseY - playerCenterY

    -- Set the attack direction
    attack:setDirection(directionX, directionY)

    -- Calculate hit area position using player center
    attack:calculateHitArea(playerCenterX, playerCenterY)
end

---Find all targets within attack area
---@param attacker Entity The attacking entity
---@param position Position The attacker's position
---@param attack Attack The attack component
---@return table Array of target entities
function AttackSystem:findTargetsInAttackArea(attacker, position, attack)
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
                -- Check if target is within the attack hit area
                if self:isTargetInHitArea(target, targetPosition, attack) then
                    table.insert(targets, target)
                end
            end
        end
    end

    return targets
end

---Check if a target is within the attack hit area
---@param target Entity The target entity
---@param targetPosition Position The target's position component
---@param attack Attack The attack component
---@return boolean True if target is in hit area
function AttackSystem:isTargetInHitArea(target, targetPosition, attack)
    local targetCenterX, targetCenterY = self:getEntityVisualCenter(target, targetPosition)

    -- Check if target center is within the hit area rectangle
    return targetCenterX >= attack.hitAreaX and
           targetCenterX <= attack.hitAreaX + attack.hitAreaWidth and
           targetCenterY >= attack.hitAreaY and
           targetCenterY <= attack.hitAreaY + attack.hitAreaHeight
end

---Find all targets within attack range (legacy method for non-directional attacks)
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
    local Knockback = require("src.components.Knockback")

    for _, target in ipairs(targets) do
        local knockbackX, knockbackY = 0, 0

        -- For directional attacks, use the attack direction for knockback
        if attacker.isPlayer and attack.attackDirectionX ~= 0 and attack.attackDirectionY ~= 0 then
            -- Use the attack direction (normalized)
            local directionLength = math.sqrt(attack.attackDirectionX * attack.attackDirectionX + attack.attackDirectionY * attack.attackDirectionY)
            if directionLength > 0 then
                local normalizedX = attack.attackDirectionX / directionLength
                local normalizedY = attack.attackDirectionY / directionLength

                -- Apply knockback in the attack direction
                knockbackX = normalizedX
                knockbackY = normalizedY
            end
        else
            -- Fallback to radial knockback for non-player entities or when no direction is set
            local attackerPosition = attacker:getComponent("Position")
            local targetPosition = target:getComponent("Position")

            if attackerPosition and targetPosition then
                -- Calculate knockback direction using visual centers (radial from attacker)
                local attackerCenterX, attackerCenterY = self:getEntityVisualCenter(attacker, attackerPosition)
                local targetCenterX, targetCenterY = self:getEntityVisualCenter(target, targetPosition)
                local dx = targetCenterX - attackerCenterX
                local dy = targetCenterY - attackerCenterY
                local distance = math.sqrt(dx * dx + dy * dy)

                if distance > 0 then
                    -- Normalize direction and apply knockback force
                    knockbackX = dx / distance
                    knockbackY = dy / distance
                end
            end
        end

        -- Create knockback component for the target
        local knockbackComponent = Knockback.new(knockbackX, knockbackY, attack.knockback, 0.1)
        target:addComponent("Knockback", knockbackComponent)
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
