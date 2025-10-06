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
    stateMachine:setStateData("lastParticleSpawn", 0) -- Track last particle spawn time

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

        -- Normalize diagonal movement to prevent faster diagonal movement
        local magnitude = math.sqrt(velocityX * velocityX + velocityY * velocityY)
        if magnitude > 0 then
            local normalizedX = velocityX / magnitude
            local normalizedY = velocityY / magnitude
            velocityX = normalizedX * movement.maxSpeed
            velocityY = normalizedY * movement.maxSpeed
        end

        movement:setVelocity(velocityX, velocityY)

        -- Spawn walking particles if moving and enough time has passed
        if (velocityX ~= 0 or velocityY ~= 0) and PlayerConfig.WALKING_PARTICLES.enabled then
            local lastSpawn = stateMachine:getStateData("lastParticleSpawn") or 0
            if walkTime - lastSpawn >= PlayerConfig.WALKING_PARTICLES.spawnRate then
                self:spawnWalkingParticles(entity, velocityX, velocityY)
                stateMachine:setStateData("lastParticleSpawn", walkTime)
            end
        end
    end
end

---Spawn walking particles at the player's feet
---@param entity Entity The player entity
---@param velocityX number Player's X velocity
---@param velocityY number Player's Y velocity
function Moving:spawnWalkingParticles(entity, velocityX, velocityY)
    local particleSystem = entity:getComponent("ParticleSystem")
    local position = entity:getComponent("Position")

    if not particleSystem or not position then
        return
    end

    -- Calculate spawn position at player's feet
    local spawnX = position.x + (PlayerConfig.SPRITE_WIDTH / 2)
    local spawnY = position.y + PlayerConfig.SPRITE_HEIGHT - 4 -- Slightly above ground

    -- Spawn particles based on movement direction
    local config = PlayerConfig.WALKING_PARTICLES
    for i = 1, config.count do
        -- Calculate particle velocity based on movement direction
        local speed = config.velocity.min + math.random() * (config.velocity.max - config.velocity.min)

        -- Add some randomness to the direction
        local angleOffset = (math.random() - 0.5) * (config.velocity.spread * math.pi / 180)
        local baseAngle = math.atan2(velocityY, velocityX) + math.pi -- Opposite to movement
        local angle = baseAngle + angleOffset

        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed

        -- Add small random offset to spawn position
        local offsetX = spawnX + (math.random() - 0.1) * 4
        local offsetY = spawnY + (math.random() - 0.1) * 4

        particleSystem:addParticle(
            offsetX, offsetY,
            vx, vy,
            config.life,
            config.color,
            config.size,
            true -- fade over time
        )
    end
end

return Moving
