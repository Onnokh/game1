---@class Attacking : State
---Ranged attacking state for skeleton - fires projectiles from distance
local Attacking = {}
Attacking.__index = Attacking
setmetatable(Attacking, {__index = require("src.core.State")})

local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")
local GameConstants = require("src.constants")
local BulletEntity = require("src.entities.Bullet")

---@return Attacking The created attacking state
function Attacking.new()
    local self = setmetatable({}, Attacking)
    return self
end

function Attacking:onEnter(stateMachine, entity)
    -- Stop movement when starting attack
    local movement = entity:getComponent("Movement")
    if movement then
        movement.velocityX = 0
        movement.velocityY = 0
    end
end

function Attacking:onUpdate(stateMachine, entity, dt)
    local position = entity:getComponent("Position")
    local attack = entity:getComponent("Attack")
    local movement = entity:getComponent("Movement")
    if not position or not attack then
        return
    end

    -- Use the entity's current target
    local target = entity.target

    if not target or target.isDead then
        return
    end

    -- Compute direction to closest point on target
    local ex, ey = position.x, position.y
    local pfc = entity:getComponent("PathfindingCollision")
    if pfc and pfc:hasCollider() then
        ex, ey = pfc:getCenterPosition()
    end

    local EntityUtils = require("src.utils.entities")
    local tx, ty = EntityUtils.getClosestPointOnTarget(ex, ey, target)
    local dx, dy = tx - ex, ty - ey
    local dist = math.sqrt(dx*dx + dy*dy)

    local attackRange = SkeletonConfig.ATTACK_RANGE_TILES * GameConstants.TILE_SIZE
    local preferredRange = SkeletonConfig.PREFERRED_CHASE_RANGE_TILES * GameConstants.TILE_SIZE

    -- Ranged attacking behavior: maintain distance while attacking
    if dist < preferredRange * 0.8 then
        -- Target too close - move away while attacking (kiting)
        if movement and dist > 0 then
            local desiredSpeed = movement.maxSpeed * 0.5
            movement.velocityX = -(dx / dist) * desiredSpeed
            movement.velocityY = -(dy / dist) * desiredSpeed
        end
    elseif dist > attackRange then
        -- Target out of attack range - move closer
        if movement and dist > 0 then
            local desiredSpeed = movement.maxSpeed * 0.7
            movement.velocityX = (dx / dist) * desiredSpeed
            movement.velocityY = (dy / dist) * desiredSpeed
        end
    else
        -- In good position - stay still and attack
        if movement then
            movement.velocityX = 0
            movement.velocityY = 0
        end
    end

    -- Try to attack when cooldown ready and in range
    local now = love.timer.getTime()
    if dist <= attackRange and attack:isReady(now) then
        -- Fire a projectile towards the target
        local attackerPhys = entity:getComponent("PhysicsCollision")
        local physicsWorld = attackerPhys and attackerPhys.physicsWorld or (pfc and pfc.physicsWorld) or nil

        if physicsWorld then
            -- Spawn projectile from skeleton's position
            local bulletSpeed = SkeletonConfig.PROJECTILE_SPEED or 200
            local bulletLifetime = SkeletonConfig.PROJECTILE_LIFETIME or 2.0

            -- Create bullet moving towards target
            BulletEntity.create(
                ex, ey,           -- Start position (skeleton center)
                dx, dy,           -- Direction (towards target)
                bulletSpeed,      -- Speed
                attack.damage,    -- Damage
                entity,           -- Owner (skeleton)
                entity._world,    -- World
                physicsWorld,     -- Physics world
                attack.knockback, -- Knockback
                bulletLifetime,   -- Lifetime
                false             -- Not piercing
            )

            attack:performAttack(now)
        end
    end

    -- Flip sprite based on target direction
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer then
        if dx < -0.1 then
            spriteRenderer.scaleX = -1
        elseif dx > 0.1 then
            spriteRenderer.scaleX = 1
        end
    end
end

return Attacking

