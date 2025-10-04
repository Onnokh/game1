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

            -- Check if we have collision component for more accurate position
            local collision = entity:getComponent("Collision")
            if collision and collision:hasCollider() then
                currentX, currentY = collision:getPosition()
                currentX = currentX + collision.width / 2
                currentY = currentY + collision.height / 2
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

        -- Debug output
        print("Skeleton reached wander target, transitioning to idle")
        stateMachine:changeState("idle", entity)
    end
end

return Wandering
