---@class Dash : State
---Dash state for player
local Dash = {}
Dash.__index = Dash
setmetatable(Dash, {__index = require("src.core.State")})

---@return Dash The created dash state
function Dash.new()
    local self = setmetatable({}, Dash)
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Dash:onEnter(stateMachine, entity)
    stateMachine:setStateData("dashTime", 0)
    stateMachine:setStateData("dashDuration", 0.3) -- Dash lasts 0.3 seconds

    -- Create and set dash animation when entering state
    if entity then
        local Animator = require("src.components.Animator")
        local animator = entity:getComponent("Animator")

        if not animator then
            -- Create animator if it doesn't exist
            animator = Animator.new("character", {41, 42}, 12, false)
            entity:addComponent("Animator", animator)
        else
            animator:setAnimation({41, 42}, 12, false)
        end
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Dash:onUpdate(stateMachine, entity, dt)
    local dashTime = stateMachine:getStateData("dashTime") or 0
    local dashDuration = stateMachine:getStateData("dashDuration") or 0.3

    dashTime = dashTime + dt
    stateMachine:setStateData("dashTime", dashTime)

    -- Handle dash movement with high velocity
    local movement = entity:getComponent("Movement")

    -- Access gameState from the global state
    local GameState = require("src.core.GameState")
    if GameState and GameState.input and movement then
        local velocityX, velocityY = 0, 0
        local dashSpeed = movement.maxSpeed * 3 -- 3x speed when dashing

        if GameState.input.left then velocityX = -dashSpeed end
        if GameState.input.right then velocityX = dashSpeed end
        if GameState.input.up then velocityY = -dashSpeed end
        if GameState.input.down then velocityY = dashSpeed end

        -- If no directional input, dash in the last direction or forward
        if velocityX == 0 and velocityY == 0 then
            velocityX = dashSpeed -- Default dash forward
        end

        movement:setVelocity(velocityX, velocityY)
    end

    -- Auto-transition out of dash when duration is over
    if dashTime >= dashDuration then
        -- The state machine will handle the transition based on current input
    end
end

return Dash
