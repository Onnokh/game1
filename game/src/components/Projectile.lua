local Component = require("src.core.Component")

---@class Projectile : Component
---@field damage number Damage this projectile deals on impact
---@field velocityX number X velocity in pixels per second
---@field velocityY number Y velocity in pixels per second
---@field speed number Speed of the projectile
---@field lifetime number How long the projectile lasts (seconds)
---@field maxLifetime number Maximum lifetime of the projectile
---@field owner Entity|nil The entity that fired this projectile
---@field knockback number Knockback force applied on hit
---@field piercing boolean Whether the projectile can hit multiple targets
---@field hitEntities table<number, boolean> Set of entity IDs already hit (for piercing projectiles)
---@field scaleAnimation boolean Whether the projectile is currently scaling up
---@field scaleAnimationDuration number Duration of the scale animation in seconds
---@field scaleAnimationTime number Current time in the scale animation
---@field baseScale number Base scale factor for the projectile (default: 1.0)
---@field abilityId string|nil The ability ID that created this projectile
local Projectile = {}
Projectile.__index = Projectile

---Create a new Projectile component
---@param velocityX number X velocity
---@param velocityY number Y velocity
---@param speed number Speed of the projectile
---@param damage number Damage dealt
---@param lifetime number|nil Projectile lifetime in seconds (default: 3)
---@param owner Entity|nil The entity that fired this projectile
---@param knockback number|nil Knockback force (default: 0)
---@param piercing boolean|nil Whether projectile can hit multiple targets (default: false)
---@param abilityId string|nil The ability ID that created this projectile
---@param baseScale number|nil Base scale factor for the projectile (default: 1.0)
---@return Component|Projectile
function Projectile.new(velocityX, velocityY, speed, damage, lifetime, owner, knockback, piercing, abilityId, baseScale)
    local self = setmetatable(Component.new("Projectile"), Projectile)

    -- Normalize velocity and apply speed
    local length = math.sqrt(velocityX * velocityX + velocityY * velocityY)
    if length > 0 then
        self.velocityX = (velocityX / length) * speed
        self.velocityY = (velocityY / length) * speed
    else
        self.velocityX = speed
        self.velocityY = 0
    end

    self.speed = speed
    self.damage = damage or 10
    self.lifetime = 0
    self.maxLifetime = lifetime or 3
    self.owner = owner
    self.knockback = knockback or 0
    self.piercing = piercing or false
    self.hitEntities = {}
    self.scaleAnimation = true
    self.scaleAnimationDuration = 0.25 -- Quick 0.25 second scale animation
    self.scaleAnimationTime = 0
    self.baseScale = baseScale or 1.0
    self.abilityId = abilityId

    return self
end

---Check if projectile has expired
---@return boolean True if projectile should be removed
function Projectile:isExpired()
    return self.lifetime >= self.maxLifetime
end

---Update projectile lifetime
---@param dt number Delta time
function Projectile:update(dt)
    self.lifetime = self.lifetime + dt

    -- Update scale animation
    if self.scaleAnimation then
        self.scaleAnimationTime = self.scaleAnimationTime + dt
        if self.scaleAnimationTime >= self.scaleAnimationDuration then
            self.scaleAnimation = false
        end
    end
end

---Check if this projectile has already hit a specific entity
---@param entityId number Entity ID to check
---@return boolean True if entity was already hit
function Projectile:hasHitEntity(entityId)
    return self.hitEntities[entityId] == true
end

---Mark an entity as hit by this projectile
---@param entityId number Entity ID to mark
function Projectile:markEntityAsHit(entityId)
    self.hitEntities[entityId] = true
end

---Get the direction angle of the projectile
---@return number Angle in radians
function Projectile:getAngle()
    return math.atan2(self.velocityY, self.velocityX)
end

---Get the current scale based on animation
---@return number Current scale factor (animates from 0.1 * baseScale to baseScale)
function Projectile:getCurrentScale()
    if not self.scaleAnimation then
        return self.baseScale
    end

    -- Use smooth easing function (ease-out)
    local progress = self.scaleAnimationTime / self.scaleAnimationDuration
    if progress >= 1.0 then
        return self.baseScale
    end

    -- Start at 0.1 * baseScale and ease to baseScale
    local startScale = 0.1 * self.baseScale
    local endScale = self.baseScale

    -- Ease-out cubic function for smooth scaling
    local easedProgress = 1 - math.pow(1 - progress, 3)
    return startScale + (endScale - startScale) * easedProgress
end

return Projectile

