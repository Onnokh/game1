---@class Idle : State
---Idle state for player
local Idle = {}
Idle.__index = Idle
setmetatable(Idle, {__index = require("src.core.State")})

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
            animator = Animator.new("character", {1, 2}, 4, true)
            entity:addComponent("Animator", animator)
        else
            -- Set idle animation: frames 1-2, 4 fps
            animator:setAnimation({1, 2}, 4, true)
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
end

return Idle
