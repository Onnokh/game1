---@class Running : State
---Running state for player
local Running = {}
Running.__index = Running
setmetatable(Running, {__index = require("src.core.State")})

local PlayerConfig = require("src.entities.Player.PlayerConfig")
local SoundManager = require("src.core.managers.SoundManager")

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
    stateMachine:setStateData("lastParticleSpawn", 0) -- Track last particle spawn time

    -- Set running animation when entering state
    local animator = entity:getComponent("Animator")
    if animator then
        animator:setAnimation(PlayerConfig.RUNNING_ANIMATION)
    end

    -- Start or reuse movement sound globally; only adjust volume when switching
    local existingSound = stateMachine:getGlobalData("movementSound")
    if not existingSound then
        local runningSound = SoundManager.playLooping("running", 0.6)
        stateMachine:setGlobalData("movementSound", runningSound)
        print("Running: Created new movement sound")
    else
        -- Reuse existing instance to avoid restarting; adjust volume for running
        existingSound:setVolume(0.6 * SoundManager.getSFXVolume())
        print("Running: Reusing movement sound (running volume)")
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
        local runSpeed = movement.maxSpeed * PlayerConfig.RUNNING_SPEED
        local desiredX, desiredY = 0, 0

        if GameState.input.left then desiredX = -runSpeed end
        if GameState.input.right then desiredX = runSpeed end
        if GameState.input.up then desiredY = -runSpeed end
        if GameState.input.down then desiredY = runSpeed end

        -- Normalize diagonal for consistent top speed
        local magnitude = math.sqrt(desiredX * desiredX + desiredY * desiredY)
        if magnitude > 0 then
            local normalizedX = desiredX / magnitude
            local normalizedY = desiredY / magnitude
            desiredX = normalizedX * runSpeed
            desiredY = normalizedY * runSpeed
        end

        -- If no input, stop immediately to avoid gliding
        if desiredX == 0 and desiredY == 0 then
            movement:setVelocity(0, 0)
        else
            -- Accelerate toward desired velocity
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

        -- Spawn running particles if moving and enough time has passed (more frequent than walking)
        if (desiredX ~= 0 or desiredY ~= 0) and PlayerConfig.WALKING_PARTICLES.enabled then
            local lastSpawn = stateMachine:getStateData("lastParticleSpawn") or 0
            local spawnRate = PlayerConfig.WALKING_PARTICLES.spawnRate * 0.6 -- 40% faster spawn rate for running
            if runTime - lastSpawn >= spawnRate then
                self:spawnRunningParticles(entity, desiredX, desiredY)
                stateMachine:setStateData("lastParticleSpawn", runTime)
            end
        end
    end
end

---Spawn running particles at the player's feet (more intense than walking)
---@param entity Entity The player entity
---@param velocityX number Player's X velocity
---@param velocityY number Player's Y velocity
function Running:spawnRunningParticles(entity, velocityX, velocityY)
    local particleSystem = entity:getComponent("ParticleSystem")
    local position = entity:getComponent("Position")

    if not particleSystem or not position then
        return
    end

    -- Calculate spawn position at player's feet
    local spawnX = position.x + (PlayerConfig.SPRITE_WIDTH / 2)
    local spawnY = position.y + PlayerConfig.SPRITE_HEIGHT - 4 -- Slightly above ground

    -- Spawn more particles for running (1.5x the walking amount)
    local config = PlayerConfig.WALKING_PARTICLES
    local particleCount = math.floor(config.count * 1.5)

    for i = 1, particleCount do
        -- Calculate particle velocity based on movement direction (faster for running)
        local speed = config.velocity.min + math.random() * (config.velocity.max - config.velocity.min)
        speed = speed * 1.3 -- 30% faster particles for running

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

return Running
