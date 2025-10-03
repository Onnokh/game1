---@class Dash : State
---Dash state for player
local Dash = {}
Dash.__index = Dash
setmetatable(Dash, {__index = require("src.core.State")})

local PlayerConfig = require("src.entities.Player.PlayerConfig")

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
    stateMachine:setStateData("dashDuration", PlayerConfig.DASH_DURATION)

    -- Set cooldown to prevent immediate re-dash
    stateMachine:setGlobalData("dashCooldown", PlayerConfig.DASH_COOLDOWN)

    -- Lock the state machine to prevent transitions during dash
    stateMachine:lock()

    -- Capture initial dash direction
    local GameState = require("src.core.GameState")
    local dashDirX, dashDirY = 0, 0

    if GameState and GameState.input then
        if GameState.input.left then dashDirX = -1 end
        if GameState.input.right then dashDirX = 1 end
        if GameState.input.up then dashDirY = -1 end
        if GameState.input.down then dashDirY = 1 end
    end

    -- Default direction if no input (dash forward)
    if dashDirX == 0 and dashDirY == 0 then
        dashDirY = 1 -- Default dash forward (down)
    end

    -- Store the dash direction for the entire dash duration
    stateMachine:setStateData("dashDirX", dashDirX)
    stateMachine:setStateData("dashDirY", dashDirY)

    -- Create and set dash animation when entering state
    if entity then
        local Animator = require("src.components.Animator")
        local animator = entity:getComponent("Animator")

        if not animator then
            -- Create animator if it doesn't exist
            animator = Animator.new("character", PlayerConfig.DASH_ANIMATION.frames, PlayerConfig.DASH_ANIMATION.fps, PlayerConfig.DASH_ANIMATION.loop)
            entity:addComponent("Animator", animator)
        else
            animator:setAnimation(PlayerConfig.DASH_ANIMATION.frames, PlayerConfig.DASH_ANIMATION.fps, PlayerConfig.DASH_ANIMATION.loop)
        end
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Dash:onUpdate(stateMachine, entity, dt)
    local dashTime = stateMachine:getStateData("dashTime") or 0
    local dashDuration = stateMachine:getStateData("dashDuration") or PlayerConfig.DASH_DURATION

    dashTime = dashTime + dt
    stateMachine:setStateData("dashTime", dashTime)

    -- Handle dash movement with high velocity using stored direction
    local movement = entity:getComponent("Movement")

    if movement then
        local dashSpeed = movement.maxSpeed * PlayerConfig.DASH_SPEED

        -- Use the stored dash direction from when dash started
        local dashDirX = stateMachine:getStateData("dashDirX") or 0
        local dashDirY = stateMachine:getStateData("dashDirY") or 1

        local velocityX = dashDirX * dashSpeed
        local velocityY = dashDirY * dashSpeed

        movement:setVelocity(velocityX, velocityY)
    end

    -- Auto-transition out of dash when duration is over
    if dashTime >= dashDuration then
        -- Force transition to idle when dash duration ends
        stateMachine:changeState("idle", entity)
    end
end

---Called when exiting this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Dash:onExit(stateMachine, entity)
    -- Clear velocity when exiting dash to prevent continued movement
    local movement = entity:getComponent("Movement")
    if movement then
        movement:setVelocity(0, 0)
    end

    -- Unlock the state machine to allow transitions again
    stateMachine:unlock()
end

return Dash
