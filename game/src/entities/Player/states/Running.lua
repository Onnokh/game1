---@class Running : State
---Running state for player
local Running = {}
Running.__index = Running
setmetatable(Running, {__index = require("src.core.State")})

local PlayerConfig = require("src.entities.Player.PlayerConfig")

---@return Running The created running state
function Running.new()
    local self = setmetatable({}, Running)
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Running:onEnter(stateMachine, entity)
    stateMachine:setStateData("runTime", 0)

    -- Create and set running animation when entering state
    if entity then
        local Animator = require("src.components.Animator")
        local animator = entity:getComponent("Animator")

        if not animator then
            -- Create animator if it doesn't exist
            animator = Animator.new("character", PlayerConfig.RUNNING_ANIMATION.frames, PlayerConfig.RUNNING_ANIMATION.fps, PlayerConfig.RUNNING_ANIMATION.loop)
            entity:addComponent("Animator", animator)
        else
            animator:setAnimation(PlayerConfig.RUNNING_ANIMATION.frames, PlayerConfig.RUNNING_ANIMATION.fps, PlayerConfig.RUNNING_ANIMATION.loop)
        end
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Running:onUpdate(stateMachine, entity, dt)
    local runTime = stateMachine:getStateData("runTime") or 0
    stateMachine:setStateData("runTime", runTime + dt)

    -- Handle movement input with increased speed
    local movement = entity:getComponent("Movement")

    -- Access gameState from the global state
    local GameState = require("src.core.GameState")
    if GameState and GameState.input and movement then
        local velocityX, velocityY = 0, 0
        local runSpeed = movement.maxSpeed * PlayerConfig.RUNNING_SPEED

        if GameState.input.left then velocityX = -runSpeed end
        if GameState.input.right then velocityX = runSpeed end
        if GameState.input.up then velocityY = -runSpeed end
        if GameState.input.down then velocityY = runSpeed end
        movement:setVelocity(velocityX, velocityY)
    end
end

return Running
