local System = require("src.core.System")
local GameState = require("src.core.GameState")
local EntityUtils = require("src.utils.entities")
local Knockback = require("src.components.Knockback")

---@class AttackSystem : System
---Handles attacks for entities with Attack component
---If entity has Weapon component, uses weapon stats; otherwise uses Attack component stats
local AttackSystem = System:extend("AttackSystem", {"Position", "Attack"})

---Update all entities with Position, Attack, and Weapon components
---@param dt number Delta time
function AttackSystem:update(dt)
    local currentTime = love.timer.getTime()

    -- Initialize active melee attacks tracker if not already initialized
    if not self.activeMeleeAttacks then
        self.activeMeleeAttacks = {}
    end

    for _, entity in ipairs(self.entities) do
        local attack = entity:getComponent("Attack")

        if attack and attack.enabled then
            -- Check for attack input
            if self:shouldAttack(entity, currentTime) then
                self:performAttack(entity, currentTime)
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

    if not attack then
        return false
    end

    -- Get cooldown from Weapon component if available, otherwise from Attack component
    local cooldown = attack.cooldown
    local weapon = entity:getComponent("Weapon")
    if weapon then
        local weaponData = weapon:getCurrentWeapon()
        if weaponData then
            cooldown = weaponData.cooldown
        end
    end

    -- Check cooldown
    local timeSinceLastAttack = currentTime - attack.lastAttackTime
    if timeSinceLastAttack < cooldown then
        return false
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

    if not attack:performAttack(currentTime) then
        return
    end

    -- Get attack stats from Weapon component if available, otherwise from Attack component
    local attackType = attack.attackType
    local weapon = entity:getComponent("Weapon")
    if weapon then
        local weaponData = weapon:getCurrentWeapon()
        if weaponData then
            attackType = weaponData.type
        end
    end

    -- Calculate attack direction for player entities
    if EntityUtils.isPlayer(entity) then
        self:calculatePlayerAttackDirection(entity)
    end

    -- Check attack type and perform appropriate attack
    if attackType == "ranged" then
        -- Spawn a bullet entity for ranged attacks
        self:spawnBullet(entity)
    else
        -- Spawn a short-lived attack collider sensor for melee attacks
        self:spawnMeleeAttack(entity)

        -- Register this melee attack for debug visualization
        local attackDuration = 0.2 -- Show hit area for 0.2 seconds
        table.insert(self.activeMeleeAttacks, {
            entity = entity,
            startTime = currentTime,
            endTime = currentTime + attackDuration
        })
    end
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

    -- Get range from Weapon if available, otherwise from Attack
    local range = attack.range
    local weapon = entity:getComponent("Weapon")
    if weapon then
        local weaponData = weapon:getCurrentWeapon()
        if weaponData then
            range = weaponData.range
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

    -- Calculate hit area position using player center and weapon range
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

    -- Get attack stats from Weapon if available, otherwise from Attack component
    local damage = attack.damage
    local knockback = attack.knockback
    local bulletSpeed = 300
    local bulletLifetime = 3
    local piercing = false

    local weapon = entity:getComponent("Weapon")
    if weapon then
        local weaponData = weapon:getCurrentWeapon()
        if weaponData then
            damage = weaponData.damage
            knockback = weaponData.knockback
            bulletSpeed = weaponData.bulletSpeed or bulletSpeed
            bulletLifetime = weaponData.bulletLifetime or bulletLifetime
            piercing = weaponData.piercing or piercing
        end
    end

    -- Get spawn position (center of attacker)
    local spawnX, spawnY = EntityUtils.getEntityVisualCenter(entity, position)

    -- Get bullet direction (normalized attack direction)
    local directionX = attack.attackDirectionX
    local directionY = attack.attackDirectionY
    local directionLength = math.sqrt(directionX * directionX + directionY * directionY)

    if directionLength > 0 then
        -- Normalize direction
        directionX = directionX / directionLength
        directionY = directionY / directionLength

        -- Offset spawn position slightly in front of attacker to avoid self-collision
        local spawnOffset = 16
        spawnX = spawnX + directionX * spawnOffset
        spawnY = spawnY + directionY * spawnOffset

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
    end
end

---Spawn a melee attack collider
---@param entity Entity The attacking entity
function AttackSystem:spawnMeleeAttack(entity)
    local attack = entity:getComponent("Attack")
    local attackerPhys = entity:getComponent("PhysicsCollision")

    if not attack then
        return
    end

    local physicsWorld = attackerPhys and attackerPhys.physicsWorld or nil
    if not physicsWorld then return end

    -- Get attack stats from Weapon if available, otherwise from Attack component
    local damage = attack.damage
    local knockback = attack.knockback

    local weapon = entity:getComponent("Weapon")
    if weapon then
        local weaponData = weapon:getCurrentWeapon()
        if weaponData then
            damage = weaponData.damage
            knockback = weaponData.knockback
        end
    end

    -- Spawn a short-lived attack collider sensor for melee attacks
    local AttackCollider = require("src.components.AttackCollider")
    local ac = AttackCollider.new(entity, damage, knockback, 0.05)
    ac:createFixture(physicsWorld, attack.hitAreaX, attack.hitAreaY, attack.hitAreaWidth, attack.hitAreaHeight)

    -- Rotate collider to match attack angle if available
    if attack.attackAngleRad and ac.setAngle then
        ac:setAngle(attack.attackAngleRad)
    end

    entity:addComponent("AttackCollider", ac)
end

---Draw debug visualization for active melee attacks
function AttackSystem:draw()
    -- Initialize active melee attacks tracker if not already initialized
    if not self.activeMeleeAttacks then
        self.activeMeleeAttacks = {}
        return
    end

    local currentTime = love.timer.getTime()

    -- Clean up expired attacks and draw active ones
    local i = 1
    while i <= #self.activeMeleeAttacks do
        local attackData = self.activeMeleeAttacks[i]

        if currentTime > attackData.endTime then
            -- Remove expired attack
            table.remove(self.activeMeleeAttacks, i)
        else
            -- Draw active attack
            local entity = attackData.entity
            local attack = entity:getComponent("Attack")
            local position = entity:getComponent("Position")

            if attack and position and attack.enabled then
                -- Draw the attack hit area as a rotated rectangle
                -- Use the exact same position calculation as the actual AttackCollider
                local angle = attack.attackAngleRad or 0

                -- The AttackCollider body is created at (hitAreaX + width/2, hitAreaY + height/2)
                -- So we use the same center point for the debug visualization
                local cx = attack.hitAreaX + attack.hitAreaWidth * 0.5
                local cy = attack.hitAreaY + attack.hitAreaHeight * 0.5

                love.graphics.push()
                love.graphics.translate(cx, cy)
                love.graphics.rotate(angle)

                love.graphics.setColor(1, 0, 0, 0.5) -- Red semi-transparent fill
                love.graphics.rectangle("fill", -attack.hitAreaWidth * 0.5, -attack.hitAreaHeight * 0.5, attack.hitAreaWidth, attack.hitAreaHeight)

                -- Draw outline
                love.graphics.setColor(1, 0, 0, 1) -- Red solid outline
                love.graphics.rectangle("line", -attack.hitAreaWidth * 0.5, -attack.hitAreaHeight * 0.5, attack.hitAreaWidth, attack.hitAreaHeight)

                love.graphics.pop()

                -- Reset color
                love.graphics.setColor(1, 1, 1, 1)
            end

            i = i + 1
        end
    end
end

return AttackSystem
