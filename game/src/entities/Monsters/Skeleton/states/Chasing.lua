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

    -- Cache player entity reference to avoid scanning each frame
    local world = entity._world
    local player = nil
    if world then
        for _, e in ipairs(world.entities) do
            if e.isPlayer then player = e break end
        end
    end
    stateMachine:setStateData("playerRef", player)
end

---Simple visibility check (no obstacles): within distance
local function canSeeTarget(ex, ey, tx, ty, maxDistance)
    local dx = tx - ex
    local dy = ty - ey
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist <= maxDistance
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

    -- Get cached player entity (fallback to lookup if missing)
    local player = stateMachine:getStateData("playerRef")
    if (not player) and entity._world then
        for _, e in ipairs(entity._world.entities) do
            if e.isPlayer then player = e break end
        end
        stateMachine:setStateData("playerRef", player)
    end

    if not player or not position or not movement or not pathfinding then
        stateMachine:changeState("idle", entity)
        return
    end

    local playerPos = player:getComponent("Position")
    if not playerPos then
        stateMachine:changeState("idle", entity)
        return
    end

    -- Current world positions (use collider center if available)
    local sx, sy = position.x, position.y
    if pathfindingCollision and pathfindingCollision:hasCollider() then
        sx, sy = pathfindingCollision:getCenterPosition()
    end
    local px, py = playerPos.x, playerPos.y

    -- Leave chase if player is far or not visible
    local chaseRange = (SkeletonConfig.CHASE_RANGE or 8) * (GameConstants.TILE_SIZE or 16)
    if not canSeeTarget(sx, sy, px, py, chaseRange) then
        -- Stop path and go idle/wander
        pathfinding.currentPath = nil
        pathfinding.pathIndex = 1
        stateMachine:changeState("idle", entity)
        return
    end

    -- Decide steering: direct follow if line-of-sight; otherwise end chase
    local directLOS = false
    if pathfindingCollision and pathfindingCollision:hasCollider() then
        directLOS = pathfindingCollision:hasLineOfSightTo(px, py, nil)
    else
        directLOS = true
    end

    if directLOS then
        -- Direct chase: set velocity straight towards player
        local dx = px - sx
        local dy = py - sy
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            local desiredSpeed = movement.maxSpeed * 0.9
            movement.velocityX = (dx / dist) * desiredSpeed
            movement.velocityY = (dy / dist) * desiredSpeed
        end
        -- Clear any existing path to avoid PathfindingSystem steering
        pathfinding.currentPath = nil
        pathfinding.pathIndex = 1
        -- Set target for debug overlay
        pathfinding.targetX = px
        pathfinding.targetY = py
    else
        -- No LOS: stop chasing immediately
        pathfinding.currentPath = nil
        pathfinding.pathIndex = 1
        movement.velocityX = 0
        movement.velocityY = 0
        stateMachine:changeState("idle", entity)
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


