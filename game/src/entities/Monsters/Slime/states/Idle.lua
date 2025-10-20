---@class SlimeIdle : State
---@field jumpController SlimeJumpController Shared jump controller
---Idle state for slime - stand still and wait
local Idle = {}
Idle.__index = Idle
setmetatable(Idle, {__index = require("src.core.State")})

local SlimeConfig = require("src.entities.Monsters.Slime.SlimeConfig")

---@param jumpController SlimeJumpController Shared jump controller
---@return SlimeIdle The created idle state
function Idle.new(jumpController)
    local self = setmetatable({}, Idle)
    self.jumpController = jumpController
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Idle:onEnter(stateMachine, entity)
    local jc = self.jumpController

    -- Set idle animation (unless mid-jump)
    local animator = entity:getComponent("Animator")
    if animator and not jc:isCurrentlyJumping() then
        animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
    end

    -- Stop movement (unless mid-jump)
    local movement = entity:getComponent("Movement")
    if movement and not jc:isCurrentlyJumping() then
        movement.velocityX = 0
        movement.velocityY = 0
    end

end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Idle:onUpdate(stateMachine, entity, dt)
    local jc = self.jumpController
    local movement = entity:getComponent("Movement")

    -- Update jump timer every frame (for cooldown tracking)
    jc:update(dt)

    -- Apply sprite Y offset for jump arc visual effect
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer then
        spriteRenderer.offsetY = jc:getSpriteYOffset()
    end

    -- Apply shadow scale for jump effect
    local groundShadow = entity:getComponent("GroundShadow")
    if groundShadow then
        local scale = jc:getShadowScale()
        groundShadow.widthFactor = 0.9 * scale
        groundShadow.heightFactor = 0.2 * scale
    end

    -- If mid-jump, continue the jump
    if jc:isCurrentlyJumping() then

        if jc:isJumpFinished() then
            -- Jump finished during idle
            jc:finishJump()
            if movement then
                movement.velocityX = 0
                movement.velocityY = 0
            end

            -- Switch to idle animation
            local animator = entity:getComponent("Animator")
            if animator then
                animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
            end
        else
            -- Continue jump
            local vx, vy = jc:getJumpVelocity()
            if movement then
                movement.velocityX = vx
                movement.velocityY = vy
            end
        end
    else
        -- Normal idle - no timer needed
    end
end

return Idle

