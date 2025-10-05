---@class Wandering : State
---Wandering state for skeleton
local Wandering = {}
Wandering.__index = Wandering
setmetatable(Wandering, {__index = require("src.core.State")})

local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")

---@return Wandering The created wandering state
function Wandering.new()
    local self = setmetatable({}, Wandering)
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Wandering:onEnter(stateMachine, entity)
    -- Create and set walking animation when entering state
    if entity then
        local Animator = require("src.components.Animator")
        local animator = entity:getComponent("Animator")

        if not animator then
            -- Create animator if it doesn't exist
            animator = Animator.new("skeleton", SkeletonConfig.WALKING_ANIMATION.frames, SkeletonConfig.WALKING_ANIMATION.fps, SkeletonConfig.WALKING_ANIMATION.loop)
            entity:addComponent("Animator", animator)
        else
            animator:setAnimation(SkeletonConfig.WALKING_ANIMATION.frames, SkeletonConfig.WALKING_ANIMATION.fps, SkeletonConfig.WALKING_ANIMATION.loop)
        end

        -- Get wander path
        local pathfinding = entity:getComponent("Pathfinding")
        local position = entity:getComponent("Position")
        if pathfinding and position then
            -- Use current position for pathfinding
            local currentX, currentY = position.x, position.y

            -- Check if we have pathfinding collision component for more accurate position
            local pathfindingCollision = entity:getComponent("PathfindingCollision")
            if pathfindingCollision and pathfindingCollision:hasCollider() then
                currentX, currentY = pathfindingCollision:getCenterPosition()
            end

            -- Start a new wander from current position
            pathfinding:startWander(currentX, currentY, 16) -- 16 is tile size
        end
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Wandering:onUpdate(stateMachine, entity, dt)
    local pathfinding = entity:getComponent("Pathfinding")
    local movement = entity:getComponent("Movement")
    local spriteRenderer = entity:getComponent("SpriteRenderer")

    -- Transition to chasing if player nearby
    do
        local entityPos = entity:getComponent("Position")
        local pfc = entity:getComponent("PathfindingCollision")
        local sx, sy = entityPos and entityPos.x or 0, entityPos and entityPos.y or 0
        if pfc and pfc:hasCollider() then
            sx, sy = pfc:getCenterPosition()
        end
        local world = entity._world
        if world then
            local player
            for _, e in ipairs(world.entities) do
                if e.isPlayer then player = e break end
            end
            if player then
                local playerPos = player:getComponent("Position")
                if playerPos then
                    local GameConstants = require("src.constants")
                    local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")
                    local chaseRange = (SkeletonConfig.CHASE_RANGE or 8) * (GameConstants.TILE_SIZE or 16)
                    local dx = playerPos.x - sx
                    local dy = playerPos.y - sy
                    local dist = math.sqrt(dx*dx+dy*dy)
                    if dist <= chaseRange then
                        local pfc2 = entity:getComponent("PathfindingCollision")
                        if not pfc2 or pfc2:hasLineOfSightTo(playerPos.x, playerPos.y, nil) then
                            stateMachine:changeState("chasing", entity)
                            return
                        end
                    end
                end
            end
        end
    end

    -- Handle sprite flipping based on movement direction
    if movement and spriteRenderer then
        if movement.velocityX < -0.1 then
            -- Moving left, flip sprite horizontally
            spriteRenderer.scaleX = -1
        elseif movement.velocityX > 0.1 then
            -- Moving right, normal orientation
            spriteRenderer.scaleX = 1
        end
        -- If velocityX is very small, keep current orientation
    end

    -- Check if we've reached the wander target
    if pathfinding and pathfinding:isPathComplete() and movement and (math.abs(movement.velocityX) < 0.1 and math.abs(movement.velocityY) < 0.1) then
        -- We've reached the target, immediately transition to idle
        -- Clear the current path
        pathfinding.currentPath = nil
        pathfinding.currentPathIndex = 1

        stateMachine:changeState("idle", entity)
    end
end

return Wandering
