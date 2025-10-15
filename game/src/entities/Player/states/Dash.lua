---@class Dash : State
---Dash state for player
local Dash = {}
Dash.__index = Dash
setmetatable(Dash, {__index = require("src.core.State")})

local PlayerConfig = require("src.entities.Player.PlayerConfig")
local SoundManager = require("src.core.managers.SoundManager")

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

    -- Apply a one-time dash impulse to velocity
    local movement = entity:getComponent("Movement")
    if movement then
        -- Normalize diagonal
        local mag = math.sqrt(dashDirX * dashDirX + dashDirY * dashDirY)
        if mag > 0 then
            dashDirX = dashDirX / mag
            dashDirY = dashDirY / mag
        end

        -- Immediate burst: set velocity to a higher-than-dash speed once
        local burst = movement.maxSpeed * PlayerConfig.DASH_SPEED * (PlayerConfig.DASH_BURST_MULTIPLIER or 1)
        movement:setVelocity(dashDirX * burst, dashDirY * burst)
        stateMachine:setStateData("dashBurst", burst)
    end

    -- Stop any movement sound when entering dash (single global reference)
    local movementSound = stateMachine:getGlobalData("movementSound")
    if movementSound then
        movementSound:stop()
        stateMachine:setGlobalData("movementSound", nil)
        print("Dash: Stopped movement sound")
    end

    -- Set dash animation when entering state
    local animator = entity:getComponent("Animator")
    if animator then
        animator:setAnimation(PlayerConfig.DASH_ANIMATION)
    end

    -- Play dash sound effect
    SoundManager.play("dash", 1) -- Higher volume for impact sound
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

    -- Maintain a decaying speed floor along dash direction for strong burst feel
    -- Impulse-based dash only; no per-frame enforcement

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
    -- Reset velocity at the end of dash only if no movement input is held
    local movement = entity:getComponent("Movement")
    if movement then
        local GameState = require("src.core.GameState")
        local hasInput = false
        if GameState and GameState.input then
            local input = GameState.input
            hasInput = (input.left or input.right or input.up or input.down) == true
        end
        if not hasInput then
            movement:setVelocity(0, 0)
        end
    end

    -- Unlock the state machine to allow transitions again
    stateMachine:unlock()
end

return Dash
