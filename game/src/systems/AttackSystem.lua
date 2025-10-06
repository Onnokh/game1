local System = require("src.core.System")
local CoordinateUtils = require("src.utils.coordinates")
local DamageQueue = require("src.DamageQueue")
local GameState = require("src.core.GameState")
local EntityUtils = require("src.utils.entities")

---@class AttackSystem : System
local AttackSystem = System:extend("AttackSystem", {"Position", "Attack"})

---Update all entities with Position and Attack components
---@param dt number Delta time
function AttackSystem:update(dt)
    local currentTime = love.timer.getTime()

    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local attack = entity:getComponent("Attack")
        local physicsCollision = entity:getComponent("PhysicsCollision")

        if position and attack and attack.enabled then
            -- Check for attack input (this assumes the entity has input handling)
            -- For now, we'll check if the entity is the player and handle input
            if self:shouldAttack(entity, currentTime) then
                self:performAttack(entity, position, attack, physicsCollision, currentTime)
            end
        end
    end
end

---Check if an entity should attack
---@param entity Entity The entity to check
---@param currentTime number Current game time
---@return boolean True if the entity should attack
function AttackSystem:shouldAttack(entity, currentTime)
    local attack = entity:getComponent("Attack")
    if not attack or not attack:isReady(currentTime) then
        return false
    end

    -- Check if this is the player entity and handle input
    if entity.hasTag and entity:hasTag("Player") then
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
---@param entity Entity The attacking entity
---@param position Position The position component
---@param attack Attack The attack component
---@param physicsCollision PhysicsCollision|nil The physics collision component
---@param currentTime number Current game time
function AttackSystem:performAttack(entity, position, attack, physicsCollision, currentTime)
    if not attack:performAttack(currentTime) then
        return
    end

    -- Calculate attack direction for player entities
    if entity.hasTag and entity:hasTag("Player") then
        self:calculatePlayerAttackDirection(entity, position, attack)
    end

    -- Spawn a short-lived attack collider sensor (no fallback path)
    local AttackCollider = require("src.components.AttackCollider")
    local attackerPhys = entity:getComponent("PhysicsCollision")
    local physicsWorld = attackerPhys and attackerPhys.physicsWorld or nil
    if not physicsWorld then return end
    local ac = AttackCollider.new(entity, attack.damage, attack.knockback, 0.05)
    ac:createFixture(physicsWorld, attack.hitAreaX, attack.hitAreaY, attack.hitAreaWidth, attack.hitAreaHeight)
    -- Rotate collider to match attack angle if available
    if attack.attackAngleRad and ac.setAngle then
        ac:setAngle(attack.attackAngleRad)
    end
    entity:addComponent("AttackCollider", ac)

    -- Apply knockback if specified
    -- Knockback is handled in DamageSystem during queue processing
end

---Calculate attack direction for player based on mouse position
---@param entity Entity The attacking entity
---@param position Position The attacker's position
---@param attack Attack The attack component
function AttackSystem:calculatePlayerAttackDirection(entity, position, attack)
    if not GameState or not GameState.input then
        return
    end

    -- Get mouse position in world coordinates
    local mouseX = GameState.input.mouseX
    local mouseY = GameState.input.mouseY

    -- Get player's visual center (accounting for sprite size)
    local playerCenterX, playerCenterY = EntityUtils.getEntityVisualCenter(entity, position)

    -- Calculate direction from player center to mouse
    local directionX = mouseX - playerCenterX
    local directionY = mouseY - playerCenterY

    -- Set the attack direction
    attack:setDirection(directionX, directionY)

    -- Calculate hit area position using player center
    attack:calculateHitArea(playerCenterX, playerCenterY)
end

---Find all targets within attack area using PhysicsCollision overlap detection
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

    -- Try to use Box2D broadphase via physicsWorld:queryBoundingBox to find overlapping fixtures quickly
    local physicsWorld = nil
    local attackerPhys = attacker:getComponent("PhysicsCollision")
    if attackerPhys and attackerPhys.physicsWorld then
        physicsWorld = attackerPhys.physicsWorld
    end

    local usePhysicsQuery = physicsWorld ~= nil
    local fixturesInArea = nil

    if usePhysicsQuery then
        fixturesInArea = {}
        local minX = attack.hitAreaX
        local minY = attack.hitAreaY
        local maxX = attack.hitAreaX + attack.hitAreaWidth
        local maxY = attack.hitAreaY + attack.hitAreaHeight

        physicsWorld:queryBoundingBox(minX, minY, maxX, maxY, function(fixture)
            fixturesInArea[fixture] = true
            return true -- continue query
        end)
    end

    -- Get all entities with Health and PhysicsCollision components (potential targets)
    local potentialTargets = world:getEntitiesWith({"Health", "PhysicsCollision"})

    for _, target in ipairs(potentialTargets) do
        if target.id ~= attacker.id and not target.isDead then
            local targetPhysicsCollision = target:getComponent("PhysicsCollision")
            if targetPhysicsCollision and targetPhysicsCollision:hasCollider() then
                if usePhysicsQuery then
                    -- Filter using physics query results first
                    local targetFixture = targetPhysicsCollision.collider and targetPhysicsCollision.collider.fixture
                    if targetFixture and fixturesInArea[targetFixture] then
                        table.insert(targets, target)
                    end
                end
            end
        end
    end

    return targets
end

---Apply knockback to targets
---@param attacker Entity The attacking entity
---@param targets table Array of target entities
---@param attack Attack The attack component
function AttackSystem:applyKnockback(attacker, targets, attack)
    for _, target in ipairs(targets) do
        local knockbackX, knockbackY = 0, 0

        -- For directional attacks, use the attack direction for knockback
        if attacker.hasTag and attacker:hasTag("Player") and attack.attackDirectionX ~= 0 and attack.attackDirectionY ~= 0 then
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
                local attackerCenterX, attackerCenterY = EntityUtils.getEntityVisualCenter(attacker, attackerPosition)
                local targetCenterX, targetCenterY = EntityUtils.getEntityVisualCenter(target, targetPosition)
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


return AttackSystem
