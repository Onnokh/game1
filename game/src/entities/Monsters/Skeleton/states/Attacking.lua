---@class Attacking : State
---Attacking state for skeleton - perform melee when in range
local Attacking = {}
Attacking.__index = Attacking
setmetatable(Attacking, {__index = require("src.core.State")})

local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")
local GameConstants = require("src.constants")

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
    -- Optional: set attack animation here if available
end

function Attacking:onUpdate(stateMachine, entity, dt)
    local position = entity:getComponent("Position")
    local attack = entity:getComponent("Attack")
    local movement = entity:getComponent("Movement")
    if not position or not attack then
        stateMachine:changeState("idle", entity)
        return
    end

    -- Determine target (player)
    local world = entity._world
    local player = nil
    if world then
        for _, e in ipairs(world.entities) do
            if e.isPlayer then player = e break end
        end
    end
    if not player then
        stateMachine:changeState("idle", entity)
        return
    end

    -- Compute direction to player center
    local playerPos = player:getComponent("Position")
    if not playerPos then
        stateMachine:changeState("idle", entity)
        return
    end
    local px, py = playerPos.x, playerPos.y
    local playerPfc = player:getComponent("PathfindingCollision")
    if playerPfc and playerPfc:hasCollider() then
        px, py = playerPfc:getCenterPosition()
    else
        local ps = player:getComponent("SpriteRenderer")
        if ps and ps.width and ps.height then
            px = playerPos.x + ps.width / 2
            py = playerPos.y + ps.height / 2
        end
    end

    local ex, ey = position.x, position.y
    local pfc = entity:getComponent("PathfindingCollision")
    if pfc and pfc:hasCollider() then
        ex, ey = pfc:getCenterPosition()
    end

    local dx, dy = px - ex, py - ey
    local dist = math.sqrt(dx*dx + dy*dy)

    -- Leave attacking if target out of range
    local stopRange = (SkeletonConfig.ATTACK_RANGE_TILES or 1.0) * (GameConstants.TILE_SIZE or 16)
    if dist > stopRange * 1.1 then
        stateMachine:changeState("chasing", entity)
        return
    end

    -- Face target (optional)
    if movement and dist > 0 then
        -- zero movement; attacking state holds position
        movement.velocityX = 0
        movement.velocityY = 0
    end

    -- Try to attack when cooldown ready
    local now = love.timer.getTime()
    if attack:isReady(now) then
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
            entity:addComponent("AttackCollider", ac)
            attack:performAttack(now)
        end
    end
end

return Attacking


