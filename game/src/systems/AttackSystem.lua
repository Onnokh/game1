local System = require("src.core.System")
local GameState = require("src.core.GameState")
local EntityUtils = require("src.utils.entities")
local Knockback = require("src.components.Knockback")
local PlayerConfig = require("src.entities.Player.PlayerConfig")

---@class AttackSystem : System
---Handles attacks for entities with Attack component
---If entity has Ability component, uses ability stats; otherwise uses Attack component stats
local AttackSystem = System:extend("AttackSystem", {"Position", "Attack"})

---Update all entities with Position, Attack, and Ability components
---@param dt number Delta time
function AttackSystem:update(dt)
    local currentTime = love.timer.getTime()

    for _, entity in ipairs(self.entities) do
        local attack = entity:getComponent("Attack")

        if attack and attack.enabled then
            -- Handle cast interruption (movement cancels cast if flag is set in ability)
            if EntityUtils.isPlayer(entity) and attack.isCasting then
                local ability = entity:getComponent("Ability")
                if ability then
                    local abilityData = ability:getCurrentAbility()
                    -- Check if this ability's movementCancelsCast flag is true
                    if abilityData and abilityData.movementCancelsCast == true then
                        if self:shouldCancelCast(entity) then
                            attack:cancelCast()
                        end
                    end
                end
            end

            -- Update cast progress and check if complete
            if attack.isCasting then
                if attack:isCastComplete(currentTime) then
                    -- Cast complete, perform the attack
                    self:executeAttackAfterCast(entity, currentTime)
                end
            else
                -- Check for attack input (only if not casting)
                if self:shouldAttack(entity, currentTime) then
                    self:performAttack(entity, currentTime)
                end
            end
        end
    end
end

---Check if cast should be cancelled (e.g., player moved)
---@param entity Entity The entity to check
---@return boolean True if cast should be cancelled
function AttackSystem:shouldCancelCast(entity)
    if not EntityUtils.isPlayer(entity) then
        return false
    end

    local GameState = require("src.core.GameState")
    if not GameState or not GameState.input then
        return false
    end

    -- Cancel cast if player is moving
    return GameState.input.left or GameState.input.right or GameState.input.up or GameState.input.down
end

---Check if an entity should attack
---@param entity Entity The entity to check
---@param currentTime number Current game time
---@return boolean True if the entity should attack
function AttackSystem:shouldAttack(entity, currentTime)
    local attack = entity:getComponent("Attack")

    if not attack then
        return false
    end

    -- Don't allow new attacks while casting
    if attack.isCasting then
        return false
    end

    -- Check per-ability cooldown if entity has Ability component
    local ability = entity:getComponent("Ability")
    if ability then
        local abilityData = ability:getCurrentAbility()
        if abilityData and abilityData.id then
            -- Get AbilitySystem to check per-ability cooldown
            local AbilitySystem = require("src.systems.AbilitySystem")
            local abilitySystem = AbilitySystem.getInstance(self.world)
            if abilitySystem then
                if not abilitySystem:isAbilityReady(abilityData.id, abilityData, currentTime) then
                    return false -- Ability is on cooldown
                end
            end
        end
    else
        -- Fallback to Attack component cooldown for entities without Ability component
        local cooldown = attack.cooldown
        local timeSinceLastAttack = currentTime - attack.lastAttackTime
        if timeSinceLastAttack < cooldown then
            return false
        end
    end

    -- Check if this is the player entity and handle input
    if EntityUtils.isPlayer(entity) then
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
---@param currentTime number Current game time
function AttackSystem:performAttack(entity, currentTime)
    local attack = entity:getComponent("Attack")
    local position = entity:getComponent("Position")

    if not attack or not position then
        return
    end

    -- Get ability data to check for cast time
    local ability = entity:getComponent("Ability")
    local castTime = 0
    local abilityId = nil
    local abilityData = nil
    if ability then
        abilityData = ability:getCurrentAbility()
        if abilityData then
            castTime = abilityData.castTime or 0
            abilityId = abilityData.id
        end
    end

    -- If ability has cast time, start casting instead of attacking immediately
    if castTime > 0 and not attack.isCasting then
        -- Play sound effect when casting starts (use ability sound if available, otherwise default to gunshot)
        if _G.SoundManager and abilityData then
            local soundName = abilityData.sound or "gunshot"
            _G.SoundManager.play(soundName, .75, 1)
        end
        -- Start casting (direction will be calculated when cast completes)
        attack:startCast(abilityId or "unknown", castTime, currentTime)
        return -- Don't spawn bullet yet, wait for cast to complete
    end

    -- No cast time or cast already complete, proceed with normal attack
    -- Skip cooldown check for entities with Ability component (already validated in shouldAttack)
    local skipCooldownCheck = ability ~= nil
    attack:performAttack(currentTime, skipCooldownCheck)

    -- Mark ability as used (start cooldown) if entity has Ability component
    if ability and abilityId then
        local AbilitySystem = require("src.systems.AbilitySystem")
        local abilitySystem = AbilitySystem.getInstance(self.world)
        if abilitySystem then
            abilitySystem:markAbilityUsed(abilityId, currentTime)
        end
    end

    -- Play sound effect for instant attacks (use ability sound if available, otherwise default to gunshot)
    if _G.SoundManager then
        local soundName = (abilityData and abilityData.sound) or "gunshot"
        _G.SoundManager.play(soundName, .75, 1)
    end

    -- Calculate attack direction for player entities
    if EntityUtils.isPlayer(entity) then
        self:calculatePlayerAttackDirection(entity)
    end

    -- Spawn a bullet entity for ranged attacks
    self:spawnBullet(entity)
end

---Execute attack after cast completes
---@param entity Entity The attacking entity
---@param currentTime number Current game time
function AttackSystem:executeAttackAfterCast(entity, currentTime)
    local attack = entity:getComponent("Attack")
    local position = entity:getComponent("Position")

    if not attack or not position then
        return
    end

    -- Cast is complete, now perform the attack
    -- Skip cooldown check for entities with Ability component (already validated in shouldAttack)
    local ability = entity:getComponent("Ability")
    local skipCooldownCheck = ability ~= nil
    attack:performAttack(currentTime, skipCooldownCheck)

    -- Mark ability as used (start cooldown) if entity has Ability component
    local abilityId = attack.castAbilityId
    if ability and abilityId then
        local AbilitySystem = require("src.systems.AbilitySystem")
        local abilitySystem = AbilitySystem.getInstance(self.world)
        if abilitySystem then
            abilitySystem:markAbilityUsed(abilityId, currentTime)
        end
    end

    -- Calculate attack direction for player entities (based on current mouse position)
    if EntityUtils.isPlayer(entity) then
        self:calculatePlayerAttackDirection(entity)
    end

    -- Clear cast state
    attack:cancelCast()

    -- Spawn a bullet entity for ranged attacks
    self:spawnBullet(entity)
end

---Calculate attack direction for player based on mouse position
---@param entity Entity The attacking entity
function AttackSystem:calculatePlayerAttackDirection(entity)
    if not GameState or not GameState.input then
        return
    end

    local position = entity:getComponent("Position")
    local attack = entity:getComponent("Attack")

    if not position or not attack then
        return
    end

    -- Get range from Ability if available, otherwise from Attack
    local range = attack.range
    local ability = entity:getComponent("Ability")
    if ability then
        local abilityData = ability:getCurrentAbility()
        if abilityData then
            range = abilityData.range
        end
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

    -- Calculate hit area position using player center and ability range
    attack:calculateHitArea(playerCenterX, playerCenterY, range)
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

    if usePhysicsQuery and physicsWorld then
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
                if usePhysicsQuery and fixturesInArea then
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
        if EntityUtils.isPlayer(attacker) and attack.attackDirectionX ~= 0 and attack.attackDirectionY ~= 0 then
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

---Spawn a bullet for ranged attacks
---@param entity Entity The attacking entity
function AttackSystem:spawnBullet(entity)
    local world = entity._world
    if not world then return end

    local position = entity:getComponent("Position")
    local attack = entity:getComponent("Attack")
    local attackerPhys = entity:getComponent("PhysicsCollision")

    if not position or not attack then
        return
    end

    local physicsWorld = attackerPhys and attackerPhys.physicsWorld or nil
    if not physicsWorld then return end

    -- Get attack stats from Ability if available, otherwise from Attack component
    local damage = attack.damage
    local knockback = attack.knockback
    local bulletSpeed = 300
    local bulletLifetime = 3
    local piercing = false

    local ability = entity:getComponent("Ability")
    local abilityData = nil
    if ability then
        abilityData = ability:getCurrentAbility()
        if abilityData then
            damage = abilityData.damage
            knockback = abilityData.knockback
            bulletSpeed = abilityData.bulletSpeed or bulletSpeed
            bulletLifetime = abilityData.bulletLifetime or bulletLifetime
            piercing = abilityData.piercing or piercing
        end
    end

    -- Get spawn position
    local spawnX, spawnY
    if EntityUtils.isPlayer(entity) then
        -- Use gun layer offset for player (this already accounts for direction flipping)
        local animator = entity:getComponent("Animator")
        if animator then
            local gunOffset = animator:getLayerOffset("gun")
            spawnX = position.x + gunOffset.x
            spawnY = position.y + gunOffset.y + 3
        else
            -- Fallback to visual center if no animator
            spawnX, spawnY = EntityUtils.getEntityVisualCenter(entity, position)
        end
    else
        -- Use visual center for non-player entities
        spawnX, spawnY = EntityUtils.getEntityVisualCenter(entity, position)
    end

    -- Get bullet direction (normalized attack direction)
    local directionX = attack.attackDirectionX
    local directionY = attack.attackDirectionY
    local directionLength = math.sqrt(directionX * directionX + directionY * directionY)

    if directionLength > 0 then
        -- Normalize direction
        directionX = directionX / directionLength
        directionY = directionY / directionLength

        -- Apply start offset to account for gun sprite width, then add spawn offset to avoid self-collision
        local startOffset = PlayerConfig.START_OFFSET or 15
        local spawnOffset = 8
        spawnX = spawnX + directionX * (startOffset / 2 + spawnOffset)
        spawnY = spawnY + directionY * (startOffset / 2  + spawnOffset)

        -- Create bullet entity
        local BulletEntity = require("src.entities.Bullet")

        BulletEntity.create(
            spawnX,
            spawnY,
            directionX,
            directionY,
            bulletSpeed,
            damage,
            entity, -- owner
            world,
            physicsWorld,
            knockback,
            bulletLifetime,
            piercing
        )

        -- Apply recoil to player
        if EntityUtils.isPlayer(entity) and ability then
            local abilityData = ability:getCurrentAbility()
            if abilityData and abilityData.recoilKnockback then
                local movement = entity:getComponent("Movement")
                if movement then
                    -- Apply recoil in opposite direction of shot
                    local recoilVelocity = abilityData.recoilKnockback * 150
                    movement:addVelocity(-directionX * recoilVelocity, -directionY * recoilVelocity)
                end
            end
        end
    end
end


return AttackSystem
