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
    -- Update position
    position.x = position.x + bullet.velocityX * dt
    position.y = position.y + bullet.velocityY * dt

    -- Sync physics collider position if it exists
    if physicsCollision and physicsCollision:hasCollider() then
        physicsCollision:setPosition(position.x, position.y)
    end
end

---Check for collisions between bullet and other entities
---@param bulletEntity Entity The bullet entity
---@param position Position The bullet's position
---@param bullet Bullet The bullet component
---@param physicsCollision PhysicsCollision The bullet's physics collision
function BulletSystem:checkCollisions(bulletEntity, position, bullet, physicsCollision)
    local world = bulletEntity._world
    if not world then return end

    -- Get all entities with Health component (potential targets)
    local potentialTargets = world:getEntitiesWith({"Health", "PhysicsCollision"})

    for _, target in ipairs(potentialTargets) do
        -- Don't hit the owner, dead entities, or already-hit entities
        if target.id ~= (bullet.owner and bullet.owner.id or -1)
           and not target.isDead
           and not bullet:hasHitEntity(target.id) then

            local targetPhysicsCollision = target:getComponent("PhysicsCollision")

            if targetPhysicsCollision and targetPhysicsCollision:hasCollider() then
                -- Check if bullet collider overlaps with target collider
                if self:checkOverlap(physicsCollision, targetPhysicsCollision) then
                    -- Apply damage
                    self:hitTarget(bulletEntity, target, bullet, position)

                    -- If bullet is not piercing, remove it after first hit
                    if not bullet.piercing then
                        self:removeBullet(bulletEntity, physicsCollision)
                        return
                    end
                end
            end
        end
    end
end

---Check if two physics colliders overlap
---@param collider1 PhysicsCollision First collider
---@param collider2 PhysicsCollision Second collider
---@return boolean True if colliders overlap
function BulletSystem:checkOverlap(collider1, collider2)
    if not collider1:hasCollider() or not collider2:hasCollider() then
        return false
    end

    -- Get center positions of the physics bodies (not top-left corners!)
    local x1, y1 = collider1.collider.body:getPosition()
    local x2, y2 = collider2.collider.body:getPosition()

    -- Simple circle-circle collision for now
    -- (can be improved with proper shape-based collision detection)
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)

    -- Get radii (approximate for both circle and rectangle shapes)
    local radius1 = (collider1.width + collider1.height) / 4
    local radius2 = (collider2.width + collider2.height) / 4

    return distance < (radius1 + radius2)
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

    -- TODO: Add particle effects for bullet impact
end

---Remove a bullet from the world
---@param bulletEntity Entity The bullet entity to remove
---@param physicsCollision PhysicsCollision|nil The physics collision component
function BulletSystem:removeBullet(bulletEntity, physicsCollision)
    -- Destroy physics collider
    if physicsCollision and physicsCollision:hasCollider() then
        physicsCollision:destroy()
    end

    -- Mark entity as dead for removal
    bulletEntity.isDead = true
end

return BulletSystem

