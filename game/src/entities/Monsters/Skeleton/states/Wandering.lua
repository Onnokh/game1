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

        -- Reset wander timer
        stateMachine:setStateData("wanderTime", 0)
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Wandering:onUpdate(stateMachine, entity, dt)
    local pathfinding = entity:getComponent("Pathfinding")
    local movement = entity:getComponent("Movement")
    local wanderTime = stateMachine:getStateData("wanderTime") or 0
    stateMachine:setStateData("wanderTime", wanderTime + dt)

    -- Debug: Print pathfinding status (only occasionally)
    if pathfinding and wanderTime % 5.0 < 0.1 then -- Print every 5 seconds
        local isComplete = pathfinding:isPathComplete()
        local hasPath = pathfinding.currentPath ~= nil
    end

    -- Only transition to idle after wandering for at least 3 seconds
    if wanderTime > 3.0 then
        -- Check if we should transition to idle
        if pathfinding and pathfinding:isPathComplete() then
            -- If pathfinding is complete and we're not moving much, go to idle
            if movement and (math.abs(movement.velocityX) < 0.1 and math.abs(movement.velocityY) < 0.1) then
                stateMachine:changeState("idle", entity)
            end
        end
    end
end

return Wandering
