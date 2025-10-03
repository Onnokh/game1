---@class Idle : State
---Idle state for skeleton
local Idle = {}
Idle.__index = Idle
setmetatable(Idle, {__index = require("src.core.State")})

local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")

---@return Idle The created idle state
function Idle.new()
    local self = setmetatable({}, Idle)
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Idle:onEnter(stateMachine, entity)
    stateMachine:setStateData("idleTime", 0)

    -- Create and set idle animation when entering state
    if entity then
        local Animator = require("src.components.Animator")
        local animator = entity:getComponent("Animator")

        if not animator then
            -- Create animator if it doesn't exist
            animator = Animator.new("skeleton", SkeletonConfig.IDLE_ANIMATION.frames, SkeletonConfig.IDLE_ANIMATION.fps, SkeletonConfig.IDLE_ANIMATION.loop)
            entity:addComponent("Animator", animator)
        else
            animator:setAnimation(SkeletonConfig.IDLE_ANIMATION.frames, SkeletonConfig.IDLE_ANIMATION.fps, SkeletonConfig.IDLE_ANIMATION.loop)
        end
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Idle:onUpdate(stateMachine, entity, dt)
    local idleTime = stateMachine:getStateData("idleTime") or 0
    stateMachine:setStateData("idleTime", idleTime + dt)

    -- After 2 seconds of idling, start wandering
    if idleTime > 1.0 then
        stateMachine:changeState("wandering", entity)
    end
end

return Idle
