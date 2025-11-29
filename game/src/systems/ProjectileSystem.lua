local System = require("src.core.System")
local DamageQueue = require("src.DamageQueue")
local CustomLightRenderer = require("src.utils.CustomLightRenderer")

---@class ProjectileSystem : System
---Handles projectile movement, collision detection, and lifetime management
local ProjectileSystem = System:extend("ProjectileSystem", {"Position", "Projectile", "PhysicsCollision"})

---Update all projectiles
---@param dt number Delta time
function ProjectileSystem:update(dt)
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        local position = entity:getComponent("Position")
        local projectile = entity:getComponent("Projectile")
        local physicsCollision = entity:getComponent("PhysicsCollision")

        if position and projectile then
            -- Update projectile lifetime
            projectile:update(dt)

            -- Check if projectile has expired
            if projectile:isExpired() then
                self:removeProjectile(entity, physicsCollision)
            else
                -- Move projectile
                self:moveProjectile(position, projectile, physicsCollision, dt)

                -- Update projectile scale animation
                self:updateProjectileScale(entity, projectile)

                -- Check for collisions with entities
                self:checkCollisions(entity, position, projectile, physicsCollision)
            end
        end
    end
end

---Move a projectile based on its velocity
---@param position Position The position component
---@param projectile Projectile The projectile component
---@param physicsCollision PhysicsCollision The physics collision component
---@param dt number Delta time
function ProjectileSystem:moveProjectile(position, projectile, physicsCollision, dt)
    -- Use physics engine for movement so CCD (continuous collision detection) works properly
    if physicsCollision and physicsCollision:hasCollider() then
        -- Set the linear velocity on the physics body
        physicsCollision:setLinearVelocity(projectile.velocityX, projectile.velocityY)

        -- Read back the position from the physics body to keep ECS position in sync
        local x, y = physicsCollision:getPosition()
        position:setPosition(x, y)
    end
end

---Update projectile scale animation
---@param entity Entity The projectile entity
---@param projectile Projectile The projectile component
function ProjectileSystem:updateProjectileScale(entity, projectile)
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer then
        local currentScale = projectile:getCurrentScale()
        spriteRenderer:setScale(currentScale, currentScale)
    end
end

---Check for collisions between projectile and other entities
---This uses flags set by the physics collision callbacks in CollisionSystem
---@param projectileEntity Entity The projectile entity
---@param position Position The projectile's position
---@param projectile Projectile The projectile component
---@param physicsCollision PhysicsCollision The projectile's physics collision
function ProjectileSystem:checkCollisions(projectileEntity, position, projectile, physicsCollision)
    -- Check if projectile hit a static object (wall)
    -- Projectiles are ALWAYS removed when hitting walls, regardless of piercing
    if projectileEntity._hitStatic then
        -- Create wall impact particles
        self:createImpactParticles(position.x, position.y, projectile.velocityX, projectile.velocityY)
        self:removeProjectile(projectileEntity, physicsCollision)
        return
    end

    -- Check if projectile hit any entities (set by collision callbacks)
    if projectileEntity._hitEntities and #projectileEntity._hitEntities > 0 then
        local hitCount = 0
        for _, target in ipairs(projectileEntity._hitEntities) do
            -- Make sure target is still valid and has Health
            if not target.isDead and target:getComponent("Health") then
                -- Apply damage
                self:hitTarget(projectileEntity, target, projectile, position)
                hitCount = hitCount + 1
            end
        end

        -- Clear the hit list for this frame
        projectileEntity._hitEntities = {}

        -- If projectile is not piercing and hit something, remove it
        if hitCount > 0 and not projectile.piercing then
            self:removeProjectile(projectileEntity, physicsCollision)
            return
        end
    end
end

---Apply damage to a target hit by a projectile
---@param projectileEntity Entity The projectile entity
---@param target Entity The target entity
---@param projectile Projectile The projectile component
---@param projectilePosition Position The projectile's position
function ProjectileSystem:hitTarget(projectileEntity, target, projectile, projectilePosition)
    -- Mark this entity as hit (for piercing projectiles)
    projectile:markEntityAsHit(target.id)

    -- Call onHit hook if ability has one
    if projectile.abilityId and projectile.owner then
        local ability = projectile.owner:getComponent("Ability")
        if ability then
            local abilityData = ability.inventory and ability.inventory[projectile.abilityId]
            if abilityData and abilityData.onHit and type(abilityData.onHit) == "function" then
                local success, err = pcall(abilityData.onHit, target, projectile.owner, abilityData)
                if not success then
                    print(string.format("[ProjectileSystem] Error in onHit hook for ability %s: %s", projectile.abilityId, tostring(err)))
                end
            end
        end
    end

    -- Queue damage event (DamageSystem will handle knockback application)
    -- The DamageSystem calculates knockback direction from source to target automatically
    DamageQueue:push(target, projectile.damage, projectile.owner, "physical", projectile.knockback, nil)

    -- Create impact particles
    self:createImpactParticles(projectilePosition.x, projectilePosition.y, projectile.velocityX, projectile.velocityY)
end

---Remove a projectile from the world
---@param projectileEntity Entity The projectile entity to remove
---@param physicsCollision PhysicsCollision|nil The physics collision component (unused - kept for signature compatibility)
function ProjectileSystem:removeProjectile(projectileEntity, physicsCollision)
    -- Prevent double-removal
    if projectileEntity.isDead then
        return
    end

    -- Mark as dead first to prevent double-removal
    projectileEntity.isDead = true

    -- Remove light if attached
    local lightComp = projectileEntity:getComponent("Light")
    if lightComp and lightComp.lights then
        for i, lightConfig in ipairs(lightComp.lights) do
            if lightConfig.lightId then
                CustomLightRenderer.removeLight(lightConfig.lightId)
                lightConfig.lightId = nil
            end
        end
    end

    -- Remove entity from the world
    -- Entity:destroy() will automatically clean up all components
    local world = projectileEntity._world
    if world then
        world:removeEntity(projectileEntity)
    end
end

---Create impact particles when projectile hits something
---@param x number Impact X position
---@param y number Impact Y position
---@param velocityX number Projectile velocity X
---@param velocityY number Projectile velocity Y
function ProjectileSystem:createImpactParticles(x, y, velocityX, velocityY)
    if not self.world then return end

    -- Find the global particle entity
    local particleEntity = nil
    for _, entity in ipairs(self.world.entities) do
        if entity:hasTag("GlobalParticles") then
            particleEntity = entity
            break
        end
    end

    if not particleEntity then return end

    local particleSystem = particleEntity:getComponent("ParticleSystem")
    if not particleSystem then return end

    -- Calculate impact direction (opposite of projectile velocity)
    local speed = math.sqrt(velocityX * velocityX + velocityY * velocityY)
    if speed > 0 then
        velocityX = velocityX / speed
        velocityY = velocityY / speed
    end

    -- Create a small burst of particles
    local particleCount = 8
    for i = 1, particleCount do
        local angle = math.atan2(velocityY, velocityX) + (math.random() - 0.5) * math.pi
        local particleSpeed = 50 + math.random() * 50
        local vx = math.cos(angle) * particleSpeed
        local vy = math.sin(angle) * particleSpeed

        -- Mix of gray and yellow particles
        local color
        if math.random() > 0.5 then
            color = {r = 0.3, g = 0.3, b = 0.3, a = 1} -- Gray
        else
            color = {r = 1, g = 1, b = 0.2, a = 1} -- Yellow
        end

        particleSystem:addParticle(x, y, vx, vy, 0.3 + math.random() * 0.2, color, 1 + math.random())
    end
end

return ProjectileSystem

