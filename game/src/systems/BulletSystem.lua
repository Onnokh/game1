local System = require("src.core.System")
local DamageQueue = require("src.DamageQueue")

---@class BulletSystem : System
---Handles bullet movement, collision detection, and lifetime management
local BulletSystem = System:extend("BulletSystem", {"Position", "Bullet", "PhysicsCollision"})

---Update all bullets
---@param dt number Delta time
function BulletSystem:update(dt)
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        local position = entity:getComponent("Position")
        local bullet = entity:getComponent("Bullet")
        local physicsCollision = entity:getComponent("PhysicsCollision")

        if position and bullet then
            -- Update bullet lifetime
            bullet:update(dt)

            -- Check if bullet has expired
            if bullet:isExpired() then
                self:removeBullet(entity, physicsCollision)
            else
                -- Move bullet
                self:moveBullet(position, bullet, physicsCollision, dt)

                -- Check for collisions with entities
                self:checkCollisions(entity, position, bullet, physicsCollision)
            end
        end
    end
end

---Move a bullet based on its velocity
---@param position Position The position component
---@param bullet Bullet The bullet component
---@param physicsCollision PhysicsCollision The physics collision component
---@param dt number Delta time
function BulletSystem:moveBullet(position, bullet, physicsCollision, dt)
    -- Use physics engine for movement so CCD (continuous collision detection) works properly
    if physicsCollision and physicsCollision:hasCollider() then
        -- Set the linear velocity on the physics body
        physicsCollision:setLinearVelocity(bullet.velocityX, bullet.velocityY)

        -- Read back the position from the physics body to keep ECS position in sync
        local x, y = physicsCollision:getPosition()
        position:setPosition(x, y)
    end
end

---Check for collisions between bullet and other entities
---This uses flags set by the physics collision callbacks in CollisionSystem
---@param bulletEntity Entity The bullet entity
---@param position Position The bullet's position
---@param bullet Bullet The bullet component
---@param physicsCollision PhysicsCollision The bullet's physics collision
function BulletSystem:checkCollisions(bulletEntity, position, bullet, physicsCollision)
    -- Check if bullet hit a static object (wall)
    -- Bullets are ALWAYS removed when hitting walls, regardless of piercing
    if bulletEntity._hitStatic then
        -- Create wall impact particles
        self:createImpactParticles(position.x, position.y, bullet.velocityX, bullet.velocityY)
        self:removeBullet(bulletEntity, physicsCollision)
        return
    end

    -- Check if bullet hit any entities (set by collision callbacks)
    if bulletEntity._hitEntities and #bulletEntity._hitEntities > 0 then
        local hitCount = 0
        for _, target in ipairs(bulletEntity._hitEntities) do
            -- Make sure target is still valid and has Health
            if not target.isDead and target:getComponent("Health") then
                -- Apply damage
                self:hitTarget(bulletEntity, target, bullet, position)
                hitCount = hitCount + 1
            end
        end

        -- Clear the hit list for this frame
        bulletEntity._hitEntities = {}

        -- If bullet is not piercing and hit something, remove it
        if hitCount > 0 and not bullet.piercing then
            self:removeBullet(bulletEntity, physicsCollision)
            return
        end
    end
end

---Apply damage to a target hit by a bullet
---@param bulletEntity Entity The bullet entity
---@param target Entity The target entity
---@param bullet Bullet The bullet component
---@param bulletPosition Position The bullet's position
function BulletSystem:hitTarget(bulletEntity, target, bullet, bulletPosition)
    -- Mark this entity as hit (for piercing bullets)
    bullet:markEntityAsHit(target.id)

    -- Queue damage event (DamageSystem will handle knockback application)
    -- The DamageSystem calculates knockback direction from source to target automatically
    DamageQueue:push(target, bullet.damage, bullet.owner, "physical", bullet.knockback, nil)

    -- Create impact particles
    self:createImpactParticles(bulletPosition.x, bulletPosition.y, bullet.velocityX, bullet.velocityY)
end

---Remove a bullet from the world
---@param bulletEntity Entity The bullet entity to remove
---@param physicsCollision PhysicsCollision|nil The physics collision component (unused - kept for signature compatibility)
function BulletSystem:removeBullet(bulletEntity, physicsCollision)
    -- Prevent double-removal
    if bulletEntity.isDead then
        return
    end

    -- Mark as dead first to prevent double-removal
    bulletEntity.isDead = true

    -- Remove light if attached
    local lightComp = bulletEntity:getComponent("Light")
    if lightComp and lightComp.lights then
        for i, lightConfig in ipairs(lightComp.lights) do
            if lightConfig.lightRef then
                lightConfig.lightRef:Remove()
                lightConfig.lightRef = nil
            end
        end
    end

    -- Remove entity from the world
    -- Entity:destroy() will automatically clean up all components
    local world = bulletEntity._world
    if world then
        world:removeEntity(bulletEntity)
    end
end

---Create impact particles when bullet hits something
---@param x number Impact X position
---@param y number Impact Y position
---@param velocityX number Bullet velocity X
---@param velocityY number Bullet velocity Y
function BulletSystem:createImpactParticles(x, y, velocityX, velocityY)
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

    -- Calculate impact direction (opposite of bullet velocity)
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

return BulletSystem

