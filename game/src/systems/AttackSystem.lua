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

    -- Clean up expired cast indicators
    if self.world then
        local castIndicators = self.world:getEntitiesWithTag("CastIndicator")
        for _, indicator in ipairs(castIndicators) do
            if indicator._spawnTime and indicator._lifetime then
                local elapsed = currentTime - indicator._spawnTime
                if elapsed >= indicator._lifetime then
                    self.world:removeEntity(indicator)
                end
            end
        end
    end

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

            -- Check mana cost if entity has Mana component
            local mana = entity:getComponent("Mana")
            if mana then
                local manaCost = (abilityData.mana or 0)
                if manaCost > 0 and not mana:hasEnoughMana(manaCost) then
                    return false -- Not enough mana
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
        -- Consume mana when casting starts (for cast-time abilities)
        if abilityData then
            local mana = entity:getComponent("Mana")
            if mana then
                local manaCost = (abilityData.mana or 0)
                if manaCost > 0 then
                    mana:consumeMana(manaCost)
                end
            end
        end

        -- Play sound effect when casting starts (use ability sound if available, otherwise default to gunshot)
        if _G.SoundManager and abilityData then
            local soundName = abilityData.sound or "gunshot"
            local soundInstance = _G.SoundManager.play(soundName, .75, 1)
            -- Store sound instance so we can stop it if cast is cancelled
            attack.castSoundInstance = soundInstance
        end
        -- Start casting (direction will be calculated when cast completes)
        attack:startCast(abilityId or "unknown", castTime, currentTime)
        return -- Don't spawn projectile yet, wait for cast to complete
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

        -- Consume mana if entity has Mana component
        if abilityData then
            local mana = entity:getComponent("Mana")
            if mana then
                local manaCost = (abilityData.mana or 0)
                if manaCost > 0 then
                    mana:consumeMana(manaCost)
                end
            end

            -- Call onCast hook if defined
            if abilityData.onCast and type(abilityData.onCast) == "function" then
                local success, err = pcall(abilityData.onCast, entity, abilityData)
                if not success then
                    print(string.format("[AttackSystem] Error in onCast hook for ability %s: %s", abilityId or "unknown", tostring(err)))
                end
            end
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

    -- Spawn a projectile entity for ranged attacks (if ability has projectile attribute)
    self:spawnProjectile(entity)
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

        -- Get ability data for onCast hook
        local abilityData = ability:getCurrentAbility()
        if abilityData and abilityData.onCast and type(abilityData.onCast) == "function" then
            local success, err = pcall(abilityData.onCast, entity, abilityData)
            if not success then
                print(string.format("[AttackSystem] Error in onCast hook for ability %s: %s", abilityId or "unknown", tostring(err)))
            end
        end

        -- Note: For cast-time abilities, mana is consumed when casting starts (in performAttack)
        -- For instant abilities, mana is consumed in performAttack as well
        -- So we don't consume mana again here in executeAttackAfterCast
    end

    -- Calculate attack direction for player entities (based on current mouse position)
    if EntityUtils.isPlayer(entity) then
        self:calculatePlayerAttackDirection(entity)
    end

    -- Clear cast state (don't stop sound, let it finish playing)
    attack:cancelCast(false)

    -- Spawn a projectile entity for ranged attacks (if ability has projectile attribute)
    self:spawnProjectile(entity)
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

---Create a temporary visual indicator at a position
---@param x number X position
---@param y number Y position
---@param spriteName string Sprite name for the indicator
---@param duration number Duration in seconds before removal
---@param world World The ECS world
---@return Entity The created indicator entity
local function createCastIndicator(x, y, spriteName, duration, world)
    local Entity = require("src.core.Entity")
    local Position = require("src.components.Position")
    local SpriteRenderer = require("src.components.SpriteRenderer")
    local DepthSorting = require("src.utils.depthSorting")

    local indicator = Entity.new()
    indicator:addTag("CastIndicator")

    -- Get sprite dimensions
    local spriteWidth = 16
    local spriteHeight = 16
    local iffy = require("lib.iffy")
    if iffy.tilesets[spriteName] then
        spriteWidth = iffy.tilesets[spriteName][1] or 16
        spriteHeight = iffy.tilesets[spriteName][2] or 16
    end

    -- Position at cursor (center the sprite)
    local position = Position.new(x - spriteWidth / 2, y - spriteHeight / 2, DepthSorting.getLayerZ("GROUND"))
    local spriteRenderer = SpriteRenderer.new(spriteName, spriteWidth, spriteHeight)

    indicator:addComponent("Position", position)
    indicator:addComponent("SpriteRenderer", spriteRenderer)

    -- Store lifetime for removal
    indicator._lifetime = duration
    indicator._spawnTime = love.timer.getTime()

    if world then
        world:addEntity(indicator)
    end

    return indicator
end

---Spawn a projectile for ranged attacks (only if ability has projectile attribute)
---@param entity Entity The attacking entity
function AttackSystem:spawnProjectile(entity)
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
    local projectileSpeed = 300
    local projectileLifetime = 3
    local projectileScale = nil
    local piercing = false

    local ability = entity:getComponent("Ability")
    local abilityData = nil
    local projectileType = nil
    if ability then
        abilityData = ability:getCurrentAbility()
        if abilityData then
            damage = abilityData.damage
            knockback = abilityData.knockback
            piercing = abilityData.piercing or piercing

            -- Handle different projectile types
            projectileType = abilityData.projectile and abilityData.projectile.type or nil

            -- If projectile is "instant" type or nil, handle instant hit at cursor
            if not abilityData.projectile or projectileType == "instant" then
                -- Get mouse position in world coordinates
                local mouseX = GameState.input.mouseX
                local mouseY = GameState.input.mouseY

                -- Create visual indicator at cursor if projectile is "instant" type
                if projectileType == "instant" and abilityData.projectile.sprite then
                    local indicatorDuration = 0.3 -- Show indicator for 0.3 seconds
                    createCastIndicator(mouseX, mouseY, abilityData.projectile.sprite, indicatorDuration, world)
                end

                -- Query for entities at cursor position using physics world
                local hitEntities = {}
                local hitRadius = 16 -- Small radius around cursor for hit detection

                if physicsWorld then
                    local fixturesInArea = {}
                    physicsWorld:queryBoundingBox(
                        mouseX - hitRadius, mouseY - hitRadius,
                        mouseX + hitRadius, mouseY + hitRadius,
                        function(fixture)
                            fixturesInArea[fixture] = true
                            return true -- Continue querying
                        end
                    )

                    -- Get all entities with Health component and check if they're in the hit area
                    local allEntities = world:getEntitiesWith({"Health"})
                    for _, targetEntity in ipairs(allEntities) do
                        if targetEntity ~= entity
                           and not targetEntity:hasTag("Projectile")
                           and not targetEntity.isDead then
                            -- Check if entity's collider is in the hit area
                            local targetPhys = targetEntity:getComponent("PhysicsCollision")
                            local targetPathfinding = targetEntity:getComponent("PathfindingCollision")
                            local targetPos = targetEntity:getComponent("Position")

                            if targetPos then
                                -- Check distance from cursor to entity position
                                local dx = targetPos.x - mouseX
                                local dy = targetPos.y - mouseY
                                local distance = math.sqrt(dx * dx + dy * dy)

                                -- Also check if fixture is in the query area
                                local inArea = false
                                if targetPhys and targetPhys:hasCollider() and targetPhys.collider.fixture then
                                    inArea = fixturesInArea[targetPhys.collider.fixture] ~= nil
                                elseif targetPathfinding and targetPathfinding:hasCollider() and targetPathfinding.collider.fixture then
                                    inArea = fixturesInArea[targetPathfinding.collider.fixture] ~= nil
                                end

                                if inArea or distance <= hitRadius then
                                    -- Check friendly fire prevention
                                    local attackerIsMonster = entity:hasTag("Monster")
                                    local targetIsMonster = targetEntity:hasTag("Monster")
                                    if not (attackerIsMonster and targetIsMonster) then
                                        table.insert(hitEntities, targetEntity)
                                    end
                                end
                            end
                        end
                    end
                end

                -- Apply damage to all hit entities
                local DamageQueue = require("src.DamageQueue")
                local currentAbilityId = abilityData and abilityData.id or nil
                for _, targetEntity in ipairs(hitEntities) do
                    -- Call onHit hook if ability has one
                    if abilityData and abilityData.onHit and type(abilityData.onHit) == "function" then
                        local success, err = pcall(abilityData.onHit, targetEntity, entity, abilityData)
                        if not success then
                            print(string.format("[AttackSystem] Error in onHit hook for ability %s: %s", currentAbilityId or "unknown", tostring(err)))
                        end
                    end

                    DamageQueue:push(targetEntity, damage, entity, "physical", knockback, nil)
                end

                -- Apply recoil to player
                if EntityUtils.isPlayer(entity) then
                    local spriteRenderer = entity:getComponent("SpriteRenderer")
                    local playerCenterX, playerCenterY
                    if spriteRenderer then
                        playerCenterX = position.x + (spriteRenderer.width or 24) / 2
                        playerCenterY = position.y + (spriteRenderer.height or 24) / 2
                    else
                        playerCenterX = position.x
                        playerCenterY = position.y
                    end

                    local directionX = mouseX - playerCenterX
                    local directionY = mouseY - playerCenterY
                    local directionLength = math.sqrt(directionX * directionX + directionY * directionY)
                    if directionLength > 0 then
                        directionX = directionX / directionLength
                        directionY = directionY / directionLength
                    end
                end

                return -- Instant hit complete, no projectile needed
            end

            -- Handle "moving" type projectile (moving projectile)
            if projectileType == "moving" then
                projectileSpeed = abilityData.projectile.speed or projectileSpeed
                projectileLifetime = abilityData.projectile.lifetime_seconds or projectileLifetime
                projectileScale = abilityData.projectile.scale
            else
                -- Backward compatibility: if no type specified, assume "moving"
                if type(abilityData.projectile) == "table" then
                    projectileSpeed = abilityData.projectile.speed or projectileSpeed
                    projectileLifetime = abilityData.projectile.lifetime_seconds or projectileLifetime
                    projectileScale = abilityData.projectile.scale
                else
                    -- Backward compatibility: old flat structure
                    projectileSpeed = abilityData.projectileSpeed or projectileSpeed
                    projectileLifetime = abilityData.projectileLifetime or projectileLifetime
                end
            end
        end
    else
        -- No ability component, don't spawn projectile
        return
    end

    -- Only spawn projectile if type is "moving" (or undefined for backward compatibility)
    if projectileType ~= "moving" and projectileType ~= nil then
        return -- Not a moving projectile, don't spawn
    end

    -- Get projectile sprite dimensions first (needed for spawn position calculation)
    local projectileSpriteName = "bullet"
    if type(abilityData.projectile) == "table" then
        projectileSpriteName = abilityData.projectile.sprite or "bullet"
    else
        -- Backward compatibility: old string format
        projectileSpriteName = abilityData.projectile or "bullet"
    end
    local projectileSpriteWidth = 8  -- Default fallback
    local projectileSpriteHeight = 8  -- Default fallback
    local iffy = require("lib.iffy")
    if iffy.tilesets[projectileSpriteName] then
        projectileSpriteWidth = iffy.tilesets[projectileSpriteName][1] or 8
        projectileSpriteHeight = iffy.tilesets[projectileSpriteName][2] or 8
    end

    -- Get player's sprite center (not collision center, which is at feet)
    -- Use sprite center directly for visual accuracy
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    local playerCenterX, playerCenterY
    if spriteRenderer then
        -- Sprite center is at position + half sprite dimensions
        playerCenterX = position.x + (spriteRenderer.width or 24) / 2
        playerCenterY = position.y + (spriteRenderer.height or 24) / 2
    else
        -- Fallback to position if no sprite renderer
        playerCenterX = position.x
        playerCenterY = position.y
    end

    -- Spawn projectile so its center aligns with player sprite center
    -- Position is top-left, so offset by half sprite dimensions
    local spawnX = playerCenterX - projectileSpriteWidth / 2
    local spawnY = playerCenterY - projectileSpriteHeight / 2

    -- The spawn center is now at player sprite center
    local spawnCenterX = playerCenterX
    local spawnCenterY = playerCenterY

    -- Get mouse position in world coordinates for precise aiming
    local mouseX = GameState.input.mouseX
    local mouseY = GameState.input.mouseY

    -- Calculate direction from spawn center to cursor
    local directionX = mouseX - spawnCenterX
    local directionY = mouseY - spawnCenterY
    local directionLength = math.sqrt(directionX * directionX + directionY * directionY)

    if directionLength > 0 then
        -- Normalize direction
        directionX = directionX / directionLength
        directionY = directionY / directionLength

        -- Apply small spawn offset to avoid self-collision (projectile center moves slightly forward)
        local spawnOffset = 8
        spawnCenterX = spawnCenterX + directionX * spawnOffset
        spawnCenterY = spawnCenterY + directionY * spawnOffset

        -- Recalculate spawn position (top-left) from new center
        spawnX = spawnCenterX - projectileSpriteWidth / 2
        spawnY = spawnCenterY - projectileSpriteHeight / 2

        -- Recalculate direction from new spawn center to cursor to ensure precise aim
        directionX = mouseX - spawnCenterX
        directionY = mouseY - spawnCenterY
        directionLength = math.sqrt(directionX * directionX + directionY * directionY)
        if directionLength > 0 then
            directionX = directionX / directionLength
            directionY = directionY / directionLength
        end

        -- Create projectile entity
        local ProjectileEntity = require("src.entities.Projectile")
        local currentAbilityId = abilityData and abilityData.id or nil

        ProjectileEntity.create(
            spawnX,
            spawnY,
            directionX,
            directionY,
            projectileSpeed,
            damage,
            entity, -- owner
            world,
            physicsWorld,
            knockback,
            projectileLifetime,
            piercing,
            projectileSpriteName, -- projectile sprite/animation name
            currentAbilityId, -- ability ID that created this projectile
            projectileScale -- projectile scale
        )
    end
end


return AttackSystem
