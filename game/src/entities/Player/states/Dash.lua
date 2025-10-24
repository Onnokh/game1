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

    -- Consume a dash charge
    local dashCharges = entity:getComponent("DashCharges")
    if dashCharges then
        dashCharges:consumeCharge()
    end

    -- Lock the state machine to prevent transitions during dash
    stateMachine:lock()

    -- Initialize shadow tracking
    stateMachine:setStateData("dashDistanceTraveled", 0)
    stateMachine:setStateData("lastShadowX", nil)
    stateMachine:setStateData("lastShadowY", nil)
    stateMachine:setStateData("hasSpawnedFirstShadow", false)

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

    -- Track distance traveled for shadow spawning
    local position = entity:getComponent("Position")
    local lastShadowX = stateMachine:getStateData("lastShadowX")
    local lastShadowY = stateMachine:getStateData("lastShadowY")

    if position then
        -- Initialize last shadow position if this is the first frame
        if lastShadowX == nil or lastShadowY == nil then
            stateMachine:setStateData("lastShadowX", position.x)
            stateMachine:setStateData("lastShadowY", position.y)
            stateMachine:setStateData("dashDistanceTraveled", 0)
        else
            -- Calculate distance since last shadow
            local dx = position.x - lastShadowX
            local dy = position.y - lastShadowY
            local distance = math.sqrt(dx * dx + dy * dy)

            local distanceTraveled = stateMachine:getStateData("dashDistanceTraveled") or 0
            distanceTraveled = distanceTraveled + distance

            -- Spawn shadow if we've traveled enough distance
            -- For the first shadow, require a bit more distance to avoid spawning at start position
            local shadowDistance = PlayerConfig.DASH_SHADOW_DISTANCE
            local hasSpawnedFirstShadow = stateMachine:getStateData("hasSpawnedFirstShadow") or false

            if not hasSpawnedFirstShadow then
                shadowDistance = PlayerConfig.DASH_SHADOW_DISTANCE * 1.5  -- 50% more distance for first shadow
            end

            if distanceTraveled >= shadowDistance then
                self:spawnDashShadow(entity, stateMachine)
                stateMachine:setStateData("dashDistanceTraveled", 0)
                stateMachine:setStateData("lastShadowX", position.x)
                stateMachine:setStateData("lastShadowY", position.y)
                stateMachine:setStateData("hasSpawnedFirstShadow", true)
            else
                stateMachine:setStateData("dashDistanceTraveled", distanceTraveled)
            end
        end
    end

    -- Maintain a decaying speed floor along dash direction for strong burst feel
    -- Impulse-based dash only; no per-frame enforcement

    -- Auto-transition out of dash when duration is over
    if dashTime >= dashDuration then
        -- Force transition to idle when dash duration ends
        stateMachine:changeState("idle", entity)
    end
end

---Spawn a dash shadow at the previous position
---@param entity Entity The player entity
---@param stateMachine StateMachine The state machine
function Dash:spawnDashShadow(entity, stateMachine)
    -- Get current player position and sprite data
    local position = entity:getComponent("Position")
    local animator = entity:getComponent("Animator")
    local spriteRenderer = entity:getComponent("SpriteRenderer")

    if not position then return end

    -- Get the world to spawn the shadow entity
    local world = entity._world
    if not world then return end

    -- Create shadow entity
    local Entity = require("src.core.Entity")
    local Position = require("src.components.Position")
    local DashShadow = require("src.components.DashShadow")
    local DepthSorting = require("src.utils.depthSorting")

    local shadowEntity = Entity.new()
    shadowEntity:addTag("DashShadow")

    -- Use the last shadow position (where player was) instead of current position
    local lastShadowX = stateMachine:getStateData("lastShadowX") or position.x
    local lastShadowY = stateMachine:getStateData("lastShadowY") or position.y

    -- Create position component (slightly behind player in depth)
    local shadowPosition = Position.new(
        lastShadowX,
        lastShadowY,
        DepthSorting.getLayerZ("PLAYER") - 0.1
    )
    shadowEntity:addComponent("Position", shadowPosition)

    -- Create dash shadow component with staggered fade timing
    local dashTime = stateMachine:getStateData("dashTime") or 0
    local dashDuration = stateMachine:getStateData("dashDuration") or PlayerConfig.DASH_DURATION

    -- Calculate how much dash time is remaining when this shadow is created
    local remainingDashTime = dashDuration - dashTime
    local staggeredFadeDelay = math.max(0, remainingDashTime * 0.3) -- 30% of remaining dash time as delay

    local shadowComponent = DashShadow.new(
        PlayerConfig.DASH_SHADOW_FADE_TIME + staggeredFadeDelay + 0.1, -- Total lifetime with staggered delay
        PlayerConfig.DASH_SHADOW_FADE_TIME,       -- Fade time
        PlayerConfig.DASH_SHADOW_OPACITY          -- Initial opacity
    )

    -- Capture current sprite frame and facing direction
    if animator and animator.layers and #animator.layers > 0 then
        local currentFrame = animator:getCurrentFrame()
        local scaleX = spriteRenderer and spriteRenderer.scaleX or 1
        local scaleY = spriteRenderer and spriteRenderer.scaleY or 1

        -- Use the first layer for shadow
        shadowComponent:setSpriteData(animator.layers[1], currentFrame, scaleX, scaleY)
    end

    -- Store dash direction for motion blur
    local dashDirX = stateMachine:getStateData("dashDirX") or 0
    local dashDirY = stateMachine:getStateData("dashDirY") or 0
    shadowComponent.dashDirX = dashDirX
    shadowComponent.dashDirY = dashDirY

    shadowEntity:addComponent("DashShadow", shadowComponent)

    -- Add to world
    world:addEntity(shadowEntity)
end

---Called when exiting this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Dash:onExit(stateMachine, entity)
    -- Start fading all existing dash shadows
    local world = entity._world
    if world then
        for _, worldEntity in ipairs(world.entities) do
            if worldEntity:hasTag("DashShadow") then
                local dashShadow = worldEntity:getComponent("DashShadow")
                if dashShadow then
                    dashShadow:startFading()
                end
            end
        end
    end

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
