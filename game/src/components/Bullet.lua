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

return Bullet

