---@class Dying : State
---@field duration number How long the dying state lasts
---@field fadeSpeed number How fast the skeleton fades out
---@field currentAlpha number Current alpha value for fading
local Dying = {}
Dying.__index = Dying
setmetatable(Dying, {__index = require("src.core.State")})

local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")

---Create a new Dying state
---@return Dying
function Dying.new()
    local self = setmetatable({}, Dying)
    self.duration = 2.0 -- 2 seconds total
    self.fadeSpeed = 1.5 -- Fade out over 1.5 seconds
    self.currentAlpha = 1.0
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Dying:onEnter(stateMachine, entity)
    -- Check if we've already started dying to prevent multiple triggers
    if stateMachine:getGlobalData("isDying") then
        return
    end

    print("Skeleton is dying...")
    stateMachine:setGlobalData("isDying", true)

    -- Stop any movement
    local movement = entity:getComponent("Movement")
    if movement then
        movement.velocityX = 0
        movement.velocityY = 0
        movement.enabled = false
    end

    -- Disable pathfinding
    local pathfinding = entity:getComponent("Pathfinding")
    if pathfinding then
        pathfinding.enabled = false
    end

    -- Disable collision
    local collision = entity:getComponent("Collision")
    if collision then
        collision.enabled = false
    end

    -- Set up death animation
    local animator = entity:getComponent("Animator")
    if animator then
        -- Set the dying animation from config
        animator:setAnimation(
            SkeletonConfig.DYING_ANIMATION.frames,
            SkeletonConfig.DYING_ANIMATION.fps,
            SkeletonConfig.DYING_ANIMATION.loop
        )
    end

    -- Start the death timer
    stateMachine:setGlobalData("deathTimer", 0)
    stateMachine:setGlobalData("fadeTimer", 0)
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Dying:onUpdate(stateMachine, entity, dt)
    local deathTimer = stateMachine:getGlobalData("deathTimer") or 0
    local fadeTimer = stateMachine:getGlobalData("fadeTimer") or 0

    -- Update timers
    deathTimer = deathTimer + dt
    fadeTimer = fadeTimer + dt
    stateMachine:setGlobalData("deathTimer", deathTimer)
    stateMachine:setGlobalData("fadeTimer", fadeTimer)

    -- Handle fading
    if fadeTimer < self.fadeSpeed then
        self.currentAlpha = 1.0 - (fadeTimer / self.fadeSpeed)

        -- Apply alpha to sprite renderer
        local spriteRenderer = entity:getComponent("SpriteRenderer")
        if spriteRenderer then
            spriteRenderer.color.a = self.currentAlpha
        end
    end

    -- Check if death animation is complete
    if deathTimer >= self.duration then
        if not stateMachine:getGlobalData("deathMessageShown") then
            print("Skeleton has died and been removed from the world")
            stateMachine:setGlobalData("deathMessageShown", true)

            -- Properly remove the entity from the world
            local world = entity._world
            if world then
                world:removeEntity(entity)
            else
                -- Fallback: just mark as inactive if no world reference
                entity.active = false
            end
        end
    end
end

---Called when exiting this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Dying:onExit(stateMachine, entity)
    -- Clean up any death-specific data
    stateMachine:setGlobalData("deathTimer", nil)
    stateMachine:setGlobalData("fadeTimer", nil)
    stateMachine:setGlobalData("isDying", nil)
    stateMachine:setGlobalData("deathMessageShown", nil)
end

return Dying
