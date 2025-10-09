---@class SlimeAttacking : State
---@field jumpController SlimeJumpController Shared jump controller
---Ranged attacking state for slime - fires projectiles from distance with jumping movement
local Attacking = {}
Attacking.__index = Attacking
setmetatable(Attacking, {__index = require("src.core.State")})

local SlimeConfig = require("src.entities.Monsters.Slime.SlimeConfig")
local GameConstants = require("src.constants")
local BulletEntity = require("src.entities.Bullet")

---@param jumpController SlimeJumpController Shared jump controller
---@return SlimeAttacking The created attacking state
function Attacking.new(jumpController)
    local self = setmetatable({}, Attacking)
    self.jumpController = jumpController
    return self
end

function Attacking:onEnter(stateMachine, entity)
    local jc = self.jumpController
    local timerBefore = jc.jumpTimer
    local animator = entity:getComponent("Animator")

    if jc:isCurrentlyJumping() then
        -- Preserve ongoing jump - ensure walking animation is active
        if animator then
            animator:setAnimation(SlimeConfig.WALKING_ANIMATION)
        end
        print(string.format("[SLIME %d] Entered ATTACKING state MID-JUMP (timer=%.2fs, duration=%.2fs)",
            entity.id, jc.jumpTimer, jc.jumpDuration))
    else
        -- Set ready to reposition immediately if needed (only if out of combat)
        jc:resetToReady()

        local movement = entity:getComponent("Movement")
        if movement then
            movement.velocityX = 0
            movement.velocityY = 0
        end

        -- Set idle animation
        if animator then
            animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
        end

        print(string.format("[SLIME %d] Entered ATTACKING state (isJumping=%s, cooldown: %.2fs -> %.2fs, canJump=%s)",
            entity.id, tostring(jc:isCurrentlyJumping()), timerBefore, jc.jumpTimer, tostring(jc:canJump())))
    end
end

function Attacking:onUpdate(stateMachine, entity, dt)
    local position = entity:getComponent("Position")
    local attack = entity:getComponent("Attack")
    local movement = entity:getComponent("Movement")
    local animator = entity:getComponent("Animator")

    if not position or not attack or not movement then
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

    local attackRange = SlimeConfig.ATTACK_RANGE_TILES * GameConstants.TILE_SIZE
    local preferredRange = SlimeConfig.PREFERRED_CHASE_RANGE_TILES * GameConstants.TILE_SIZE

    local jc = self.jumpController

    -- Update jump timer every frame (for cooldown tracking)
    jc:update(dt)

    -- Apply sprite Y offset for jump arc visual effect
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer then
        spriteRenderer.offsetY = jc:getSpriteYOffset()
    end

    -- Apply shadow scale for jump effect
    local groundShadow = entity:getComponent("GroundShadow")
    if groundShadow then
        local scale = jc:getShadowScale()
        groundShadow.widthFactor = 0.9 * scale
        groundShadow.heightFactor = 0.2 * scale
    end

    -- Determine if we need to reposition
    local shouldMove = false
    local moveAwayFromTarget = false

    if dist < preferredRange * 0.8 then
        -- Too close - jump away
        shouldMove = true
        moveAwayFromTarget = true
    elseif dist > attackRange then
        -- Too far - jump closer
        shouldMove = true
        moveAwayFromTarget = false
    end

    -- Jumping behavior for repositioning
    if jc:isJumpFinished() then
        -- Jump finished - enter cooldown
        print(string.format("[SLIME %d] Attack-Jump FINISHED, dist=%.2f tiles", entity.id, dist / GameConstants.TILE_SIZE))
        jc:finishJump()
        movement.velocityX = 0
        movement.velocityY = 0

        -- Switch to idle animation
        if animator then
            animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
        end
    elseif jc:isCurrentlyJumping() then
        -- Apply jump velocity
        local vx, vy = jc:getJumpVelocity()
        movement.velocityX = vx
        movement.velocityY = vy
    elseif shouldMove and jc:canJump() then
        -- Start new jump
        local tileSize = GameConstants.TILE_SIZE
        jc:startJump(dx, dy, dist, tileSize, moveAwayFromTarget)

        local direction = moveAwayFromTarget and "AWAY" or "TOWARD"
        print(string.format("[SLIME %d] Attack-Jump START %s target, dist=%.2f tiles, jumpDist=%.2f tiles, speed=%.1f, duration=%.2fs",
            entity.id, direction, dist / tileSize, jc.jumpDistance / tileSize, jc.jumpSpeed, jc.jumpDuration))

        -- Switch to jump animation
        if animator then
            animator:setAnimation(SlimeConfig.WALKING_ANIMATION)
        end
    else
        -- Stay still while attacking
        movement.velocityX = 0
        movement.velocityY = 0
    end

    -- Try to attack when cooldown ready and in range
    local now = love.timer.getTime()
    if dist <= attackRange and attack:isReady(now) then
        -- Fire a projectile towards the target
        local attackerPhys = entity:getComponent("PhysicsCollision")
        local physicsWorld = attackerPhys and attackerPhys.physicsWorld or (pfc and pfc.physicsWorld) or nil

        if physicsWorld then
            -- Spawn projectile from slime's position
            local bulletSpeed = SlimeConfig.PROJECTILE_SPEED or 180
            local bulletLifetime = SlimeConfig.PROJECTILE_LIFETIME or 2.5

            print(string.format("[SLIME %d] FIRING projectile at dist=%.2f tiles", entity.id, dist / GameConstants.TILE_SIZE))

            -- Create bullet moving towards target
            BulletEntity.create(
                ex, ey,           -- Start position (slime center)
                dx, dy,           -- Direction (towards target)
                bulletSpeed,      -- Speed
                attack.damage,    -- Damage
                entity,           -- Owner (slime)
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
    if spriteRenderer then
        if dx < -0.1 then
            spriteRenderer.scaleX = -1
        elseif dx > 0.1 then
            spriteRenderer.scaleX = 1
        end
    end
end

return Attacking


