---@class GenericDying : State
---Generic dying state for monsters
---@field duration number How long the dying state lasts
---@field fadeSpeed number How fast the monster fades out
---@field currentAlpha number Current alpha value for fading
local GenericDying = {}
GenericDying.__index = GenericDying
setmetatable(GenericDying, {__index = require("src.core.State")})

local EventBus = require("src.utils.EventBus")

---Create a new GenericDying state
---@param config table Monster configuration (optionally has DYING_ANIMATION or DEATH_ANIMATION)
---@return GenericDying
function GenericDying.new(config)
    local self = setmetatable({}, GenericDying)
    self.config = config
    self.duration = .5 -- 0.5 seconds total
    self.fadeSpeed = .5 -- Fade out over 0.5 seconds
    self.currentAlpha = 1.0
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function GenericDying:onEnter(stateMachine, entity)
    -- Check if we've already started dying to prevent multiple triggers
    if stateMachine:getGlobalData("isDying") then
        return
    end

    -- Also check if death timer already exists
    if stateMachine:getGlobalData("deathTimer") then
        return
    end

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

    -- Set death animation (try both DYING_ANIMATION and DEATH_ANIMATION for compatibility)
    local animator = entity:getComponent("Animator")
    if animator then
        local deathAnim = self.config.DYING_ANIMATION or self.config.DEATH_ANIMATION
        if deathAnim then
            animator:setAnimation(deathAnim)
        end
    end

    -- Start the death timer
    stateMachine:setGlobalData("deathTimer", 0)
    stateMachine:setGlobalData("fadeTimer", 0)
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function GenericDying:onUpdate(stateMachine, entity, dt)
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
            stateMachine:setGlobalData("deathMessageShown", true)

            -- Emit a final despawn event before removal so systems (e.g., loot) can react
            EventBus.emit("entityDropLoot", { entity = entity })

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
function GenericDying:onExit(stateMachine, entity)
    -- Clean up any death-specific data
    stateMachine:setGlobalData("deathTimer", nil)
    stateMachine:setGlobalData("fadeTimer", nil)
    stateMachine:setGlobalData("isDying", nil)
    stateMachine:setGlobalData("deathMessageShown", nil)
end

return GenericDying

