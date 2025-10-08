---@class GenericAttacking : State
---Generic attacking state for monsters - perform melee when in range
local GenericAttacking = {}
GenericAttacking.__index = GenericAttacking
setmetatable(GenericAttacking, {__index = require("src.core.State")})

local GameConstants = require("src.constants")

---Create a new generic attacking state
---@param config table Monster configuration (must have ATTACK_RANGE_TILES, and optionally ATTACK_ANIMATION)
---@return GenericAttacking The created attacking state
function GenericAttacking.new(config)
    local self = setmetatable({}, GenericAttacking)
    self.config = config
    return self
end

function GenericAttacking:onEnter(stateMachine, entity)
    -- Stop movement when starting attack
    local movement = entity:getComponent("Movement")
    if movement then
        movement.velocityX = 0
        movement.velocityY = 0
    end
    -- Optional: set attack animation here if available
    local animator = entity:getComponent("Animator")
    if animator and self.config.ATTACK_ANIMATION then
        animator:setAnimation(self.config.ATTACK_ANIMATION)
    end
end

function GenericAttacking:onUpdate(stateMachine, entity, dt)
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

    -- Check if we need to move closer to target or can attack
    local attackRange = (self.config.ATTACK_RANGE_TILES or 1.2) * (GameConstants.TILE_SIZE or 16)

    if dist <= attackRange then
        -- Close enough to attack - stop movement
        if movement then
            movement.velocityX = 0
            movement.velocityY = 0
        end
    else
        -- Too far to attack - move toward target
        if movement and dist > 0 then
            local desiredSpeed = movement.maxSpeed * 0.8
            movement.velocityX = (dx / dist) * desiredSpeed
            movement.velocityY = (dy / dist) * desiredSpeed
        end
    end

    -- Try to attack when cooldown ready and in range
    local now = love.timer.getTime()
    if dist <= attackRange and attack:isReady(now) then
        -- Set attack direction and hit area using attacker center
        attack:setDirection(dx, dy)
        attack:calculateHitArea(ex, ey)

        -- Spawn attack collider via AttackSystem by adding AttackCollider component
        local AttackCollider = require("src.components.AttackCollider")
        local attackerPhys = entity:getComponent("PhysicsCollision")
        local physicsWorld = attackerPhys and attackerPhys.physicsWorld or (pfc and pfc.physicsWorld) or nil
        if physicsWorld then
            local ac = AttackCollider.new(entity, attack.damage, attack.knockback, 0.06)
            ac:createFixture(physicsWorld, attack.hitAreaX, attack.hitAreaY, attack.hitAreaWidth, attack.hitAreaHeight)
            -- Rotate collider to face the player
            if attack.attackAngleRad and ac.setAngle then
                ac:setAngle(attack.attackAngleRad)
            end
            entity:addComponent("AttackCollider", ac)
            attack:performAttack(now)
        end
    end
end

return GenericAttacking

