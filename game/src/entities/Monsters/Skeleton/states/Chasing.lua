---@class Chasing : State
---Chasing state for skeleton - pursue the player using pathfinding
local Chasing = {}
Chasing.__index = Chasing
setmetatable(Chasing, {__index = require("src.core.State")})

local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")
local GameConstants = require("src.constants")

---@return Chasing The created chasing state
function Chasing.new()
    local self = setmetatable({}, Chasing)
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Chasing:onEnter(stateMachine, entity)
    -- Set walk animation
    local animator = entity:getComponent("Animator")
    if animator then
        animator:setAnimation(SkeletonConfig.WALKING_ANIMATION)
    end

end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Chasing:onUpdate(stateMachine, entity, dt)
    local position = entity:getComponent("Position")
    local movement = entity:getComponent("Movement")
    local pathfinding = entity:getComponent("Pathfinding")
    local pathfindingCollision = entity:getComponent("PathfindingCollision")

    -- Use the entity's current target
    local target = entity.target

    if not target or target.isDead or not position or not movement or not pathfinding then
        return
    end

    -- Current world positions (use collider center if available)
    local sx, sy = position.x, position.y
    if pathfindingCollision and pathfindingCollision:hasCollider() then
        sx, sy = pathfindingCollision:getCenterPosition()
    end

    -- Get closest point on target's collider
    local EntityUtils = require("src.utils.entities")
    local tx, ty = EntityUtils.getClosestPointOnTarget(sx, sy, target)

    -- Decide steering: direct follow if line-of-sight; otherwise end chase
    local directLOS = false
    if pathfindingCollision and pathfindingCollision:hasCollider() then
        directLOS = pathfindingCollision:hasLineOfSightTo(tx, ty, nil)
    else
        directLOS = true
    end

    if directLOS then
        -- Ranged chase: maintain distance from target
        local dx = tx - sx
        local dy = ty - sy
        local dist = math.sqrt(dx*dx + dy*dy)

        local tileSize = GameConstants.TILE_SIZE
        local stopRange = SkeletonConfig.ATTACK_RANGE_TILES * tileSize

        -- Skeleton maintains preferred range instead of chasing all the way
        local preferredRange = SkeletonConfig.PREFERRED_CHASE_RANGE_TILES
        if preferredRange then
            preferredRange = preferredRange * tileSize
            local tolerance = tileSize * 0.3 -- Small tolerance to stay within attack range

            if dist <= stopRange then
                -- Too close to attack, don't move
                movement.velocityX = 0
                movement.velocityY = 0
            elseif dist < preferredRange - tolerance then
                -- Too close to preferred range, move away from target (kiting)
                if dist > 0 then
                    local desiredSpeed = movement.maxSpeed * 0.6
                    movement.velocityX = -(dx / dist) * desiredSpeed
                    movement.velocityY = -(dy / dist) * desiredSpeed
                end
            elseif dist > preferredRange + tolerance then
                -- Too far from preferred range, move toward target
                if dist > 0 then
                    local desiredSpeed = movement.maxSpeed * 0.9
                    movement.velocityX = (dx / dist) * desiredSpeed
                    movement.velocityY = (dy / dist) * desiredSpeed
                end
            else
                -- Within acceptable range (2.7 - 3.3 tiles), stop moving
                movement.velocityX = 0
                movement.velocityY = 0
            end
        else
            -- Fallback to default melee behavior if no preferred range set
            if dist <= stopRange then
                movement.velocityX = 0
                movement.velocityY = 0
            else
                if dist > 0 then
                    local desiredSpeed = movement.maxSpeed * 0.9
                    movement.velocityX = (dx / dist) * desiredSpeed
                    movement.velocityY = (dy / dist) * desiredSpeed
                end
            end
        end
        -- Clear any existing path to avoid PathfindingSystem steering
        pathfinding.currentPath = nil
        pathfinding.pathIndex = 1
        -- Set target for debug overlay
        pathfinding.targetX = tx
        pathfinding.targetY = ty
    else
        -- No LOS: stop chasing immediately
        pathfinding.currentPath = nil
        pathfinding.pathIndex = 1
        movement.velocityX = 0
        movement.velocityY = 0
    end

    -- Speed tweak: move faster than wandering
    if movement then
        movement.maxSpeed = GameConstants.PLAYER_SPEED -- match player speed
    end

    -- Flip sprite based on movement set by PathfindingSystem
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer and movement then
        local baseScale = spriteRenderer.eliteScale or 1.0 -- Use stored elite scale
        if movement.velocityX < -0.1 then
            spriteRenderer.scaleX = -baseScale
            -- Adjust X offset for flipped sprite
            if spriteRenderer.baseOffsetX then
                spriteRenderer.offsetX = -spriteRenderer.baseOffsetX
            end
        elseif movement.velocityX > 0.1 then
            spriteRenderer.scaleX = baseScale
            -- Reset X offset for normal sprite
            if spriteRenderer.baseOffsetX then
                spriteRenderer.offsetX = spriteRenderer.baseOffsetX
            end
        end
    end
end

return Chasing


