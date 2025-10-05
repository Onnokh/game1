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
    -- Set run/walk animation
    if entity then
        local Animator = require("src.components.Animator")
        local animator = entity:getComponent("Animator")
        if not animator then
            animator = Animator.new("skeleton", SkeletonConfig.WALKING_ANIMATION.frames, SkeletonConfig.WALKING_ANIMATION.fps, SkeletonConfig.WALKING_ANIMATION.loop)
            entity:addComponent("Animator", animator)
        else
            animator:setAnimation(SkeletonConfig.WALKING_ANIMATION.frames, SkeletonConfig.WALKING_ANIMATION.fps, SkeletonConfig.WALKING_ANIMATION.loop)
        end
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
    -- Exception: reactor doesn't need line of sight (static structure)
    local directLOS = false
    if target.isReactor then
        directLOS = true -- Always chase reactor
    elseif pathfindingCollision and pathfindingCollision:hasCollider() then
        directLOS = pathfindingCollision:hasLineOfSightTo(tx, ty, nil)
    else
        directLOS = true
    end

    if directLOS then
        -- Direct chase: set velocity straight towards target
        local dx = tx - sx
        local dy = ty - sy
        local dist = math.sqrt(dx*dx + dy*dy)
        -- Stop moving within attack range
        local tileSize = (GameConstants.TILE_SIZE or 16)
        local stopRange = (require("src.entities.Monsters.Skeleton.SkeletonConfig").ATTACK_RANGE_TILES or 0.8) * tileSize
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
        if movement.velocityX < -0.1 then
            spriteRenderer.scaleX = -1
        elseif movement.velocityX > 0.1 then
            spriteRenderer.scaleX = 1
        end
    end
end

return Chasing


