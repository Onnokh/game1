local Component = require("src.core.Component")

---@class Bullet : Component
---@field damage number Damage this bullet deals on impact
---@field velocityX number X velocity in pixels per second
---@field velocityY number Y velocity in pixels per second
---@field speed number Speed of the bullet
---@field lifetime number How long the bullet lasts (seconds)
---@field maxLifetime number Maximum lifetime of the bullet
---@field owner Entity|nil The entity that fired this bullet
---@field knockback number Knockback force applied on hit
---@field piercing boolean Whether the bullet can hit multiple targets
---@field hitEntities table<number, boolean> Set of entity IDs already hit (for piercing bullets)
---@field scaleAnimation boolean Whether the bullet is currently scaling up
---@field scaleAnimationDuration number Duration of the scale animation in seconds
---@field scaleAnimationTime number Current time in the scale animation
local Bullet = {}
Bullet.__index = Bullet

---Create a new Bullet component
---@param velocityX number X velocity
---@param velocityY number Y velocity
---@param speed number Speed of the bullet
---@param damage number Damage dealt
---@param lifetime number|nil Bullet lifetime in seconds (default: 3)
---@param owner Entity|nil The entity that fired this bullet
---@param knockback number|nil Knockback force (default: 0)
---@param piercing boolean|nil Whether bullet can hit multiple targets (default: false)
---@return Component|Bullet
function Bullet.new(velocityX, velocityY, speed, damage, lifetime, owner, knockback, piercing)
    local self = setmetatable(Component.new("Bullet"), Bullet)

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
    self.scaleAnimationDuration = 0.25 -- Quick 0.1 second scale animation
    self.scaleAnimationTime = 0

    return self
end

---Check if bullet has expired
---@return boolean True if bullet should be removed
function Bullet:isExpired()
    return self.lifetime >= self.maxLifetime
end

---Update bullet lifetime
---@param dt number Delta time
function Bullet:update(dt)
    self.lifetime = self.lifetime + dt

    -- Update scale animation
    if self.scaleAnimation then
        self.scaleAnimationTime = self.scaleAnimationTime + dt
        if self.scaleAnimationTime >= self.scaleAnimationDuration then
            self.scaleAnimation = false
        end
    end
end

---Check if this bullet has already hit a specific entity
---@param entityId number Entity ID to check
---@return boolean True if entity was already hit
function Bullet:hasHitEntity(entityId)
    return self.hitEntities[entityId] == true
end

---Mark an entity as hit by this bullet
---@param entityId number Entity ID to mark
function Bullet:markEntityAsHit(entityId)
    self.hitEntities[entityId] = true
end

---Get the direction angle of the bullet
---@return number Angle in radians
function Bullet:getAngle()
    return math.atan2(self.velocityY, self.velocityX)
end

---Get the current scale based on animation
---@return number Current scale factor (0.1 to 1.0)
function Bullet:getCurrentScale()
    if not self.scaleAnimation then
        return 1.0
    end

    -- Use smooth easing function (ease-out)
    local progress = self.scaleAnimationTime / self.scaleAnimationDuration
    if progress >= 1.0 then
        return 1.0
    end

    -- Start at 0.1 scale and ease to 1.0
    local startScale = 0.1
    local endScale = 1.0

    -- Ease-out cubic function for smooth scaling
    local easedProgress = 1 - math.pow(1 - progress, 3)
    return startScale + (endScale - startScale) * easedProgress
end

return Bullet

