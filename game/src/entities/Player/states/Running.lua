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
    stateMachine:setStateData("lastParticleSpawn", 0) -- Track last particle spawn time

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

        -- Normalize diagonal movement to prevent faster diagonal movement
        local magnitude = math.sqrt(velocityX * velocityX + velocityY * velocityY)
        if magnitude > 0 then
            local normalizedX = velocityX / magnitude
            local normalizedY = velocityY / magnitude
            velocityX = normalizedX * runSpeed
            velocityY = normalizedY * runSpeed
        end

        movement:setVelocity(velocityX, velocityY)

        -- Spawn running particles if moving and enough time has passed (more frequent than walking)
        if (velocityX ~= 0 or velocityY ~= 0) and PlayerConfig.WALKING_PARTICLES.enabled then
            local lastSpawn = stateMachine:getStateData("lastParticleSpawn") or 0
            local spawnRate = PlayerConfig.WALKING_PARTICLES.spawnRate * 0.6 -- 40% faster spawn rate for running
            if runTime - lastSpawn >= spawnRate then
                self:spawnRunningParticles(entity, velocityX, velocityY)
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
