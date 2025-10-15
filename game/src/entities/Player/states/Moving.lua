---@class Moving : State
---Moving state for player
local Moving = {}
Moving.__index = Moving
setmetatable(Moving, {__index = require("src.core.State")})

local PlayerConfig = require("src.entities.Player.PlayerConfig")
local SoundManager = require("src.core.managers.SoundManager")

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

    -- Set walking animation when entering state
    local animator = entity:getComponent("Animator")
    if animator then
        animator:setAnimation(PlayerConfig.WALKING_ANIMATION)
    end

    -- Start or reuse movement sound globally; only adjust volume when switching
    local existingSound = stateMachine:getGlobalData("movementSound")
    if not existingSound then
        local walkingSound = SoundManager.playLooping("running", 0.4) -- Lower volume for walking
        stateMachine:setGlobalData("movementSound", walkingSound)
        print("Moving: Created new movement sound")
    else
        -- Reuse existing instance to avoid restarting; adjust volume for walking
        existingSound:setVolume(0.4 * SoundManager.getSFXVolume())
        print("Moving: Reusing movement sound (walking volume)")
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
        local desiredX, desiredY = 0, 0
        if GameState.input.left then desiredX = -movement.maxSpeed end
        if GameState.input.right then desiredX = movement.maxSpeed end
        if GameState.input.up then desiredY = -movement.maxSpeed end
        if GameState.input.down then desiredY = movement.maxSpeed end

        -- Normalize diagonal to maintain consistent top speed
        local magnitude = math.sqrt(desiredX * desiredX + desiredY * desiredY)
        if magnitude > 0 then
            local normalizedX = desiredX / magnitude
            local normalizedY = desiredY / magnitude
            desiredX = normalizedX * movement.maxSpeed
            desiredY = normalizedY * movement.maxSpeed
        end

        -- If no input, stop immediately to avoid gliding
        if desiredX == 0 and desiredY == 0 then
            movement:setVelocity(0, 0)
        else
            -- Accelerate current velocity toward desired velocity
            local deltaX = desiredX - movement.velocityX
            local deltaY = desiredY - movement.velocityY
            local deltaLen = math.sqrt(deltaX * deltaX + deltaY * deltaY)
            if deltaLen > 0 then
                local maxStep = movement.acceleration * dt
                local step = math.min(maxStep, deltaLen)
                local ux, uy = deltaX / deltaLen, deltaY / deltaLen
                movement:addVelocity(ux * step, uy * step)
            end
        end

        -- Spawn walking particles if moving and enough time has passed
        if (desiredX ~= 0 or desiredY ~= 0) and PlayerConfig.WALKING_PARTICLES.enabled then
            local lastSpawn = stateMachine:getStateData("lastParticleSpawn") or 0
            if walkTime - lastSpawn >= PlayerConfig.WALKING_PARTICLES.spawnRate then
                self:spawnWalkingParticles(entity, desiredX, desiredY)
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
