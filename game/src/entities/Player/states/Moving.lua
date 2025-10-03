---@class Moving : State
---Moving state for player
local Moving = {}
Moving.__index = Moving
setmetatable(Moving, {__index = require("src.core.State")})

local PlayerConfig = require("src.entities.Player.PlayerConfig")

---@return Moving The created moving state
function Moving.new()
    local self = setmetatable({}, Moving)
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Moving:onEnter(stateMachine, entity)
    stateMachine:setStateData("walkTime", 0)

    -- Create and set walking animation when entering state
    if entity then
        local Animator = require("src.components.Animator")
        local animator = entity:getComponent("Animator")

        if not animator then
            -- Create animator if it doesn't exist
            animator = Animator.new("character", PlayerConfig.WALKING_ANIMATION.frames, PlayerConfig.WALKING_ANIMATION.fps, PlayerConfig.WALKING_ANIMATION.loop)
            entity:addComponent("Animator", animator)
        else
            animator:setAnimation(PlayerConfig.WALKING_ANIMATION.frames, PlayerConfig.WALKING_ANIMATION.fps, PlayerConfig.WALKING_ANIMATION.loop)
        end
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Moving:onUpdate(stateMachine, entity, dt)
    local walkTime = stateMachine:getStateData("walkTime") or 0
    stateMachine:setStateData("walkTime", walkTime + dt)

    -- Handle movement input
    local movement = entity:getComponent("Movement")

    -- Access gameState from the global state
    local GameState = require("src.core.GameState")
    if GameState and GameState.input and movement then
        local velocityX, velocityY = 0, 0
        if GameState.input.left then velocityX = -movement.maxSpeed end
        if GameState.input.right then velocityX = movement.maxSpeed end
        if GameState.input.up then velocityY = -movement.maxSpeed end
        if GameState.input.down then velocityY = movement.maxSpeed end
        movement:setVelocity(velocityX, velocityY)
    end
end

return Moving
