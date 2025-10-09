---@class SlimeJumpController
---@field jumpTimer number Timer for tracking jump cooldown and duration
---@field jumpCooldown number Time between jumps
---@field jumpDuration number Duration of current jump (calculated from distance/speed)
---@field jumpDistance number Distance of current jump
---@field isJumping boolean Whether currently jumping
---@field jumpDirectionX number X direction of current jump
---@field jumpDirectionY number Y direction of current jump
---@field jumpSpeed number Speed of current jump
---@field jumpArcHeight number Maximum height of jump arc in pixels
---@field baseSpeed number Base walking speed of the slime
---Shared jump state controller for slime entities
---This ensures jump cooldown and state persists across state transitions
local SlimeJumpController = {}
SlimeJumpController.__index = SlimeJumpController

local SlimeConfig = require("src.entities.Monsters.Slime.SlimeConfig")

---Create a new jump controller
---@return SlimeJumpController
function SlimeJumpController.new()
    local self = setmetatable({}, SlimeJumpController)
    self.jumpTimer = 0
    self.jumpCooldown = 1.5 -- Time between jumps (seconds)
    self.isJumping = false
    self.jumpArcHeight = 16 -- Peak height of jump arc in pixels
    self.baseSpeed = SlimeConfig.JUMP_SPEED -- Use absolute jump speed from config

    return self
end

---Update the jump timer
---@param dt number Delta time
function SlimeJumpController:update(dt)
    self.jumpTimer = self.jumpTimer + dt
end

---Check if ready to start a new jump
---@return boolean
function SlimeJumpController:canJump()
    return not self.isJumping and self.jumpTimer >= self.jumpCooldown
end

---Check if currently jumping
---@return boolean
function SlimeJumpController:isCurrentlyJumping()
    return self.isJumping
end

---Check if jump is finished
---@return boolean
function SlimeJumpController:isJumpFinished()
    return self.isJumping and self.jumpTimer >= self.jumpDuration
end

---Start a new jump toward or away from a target
---@param dx number Direction X (unnormalized)
---@param dy number Direction Y (unnormalized)
---@param dist number Distance to target
---@param tileSize number Tile size
---@param moveAway boolean Whether to move away from target
function SlimeJumpController:startJump(dx, dy, dist, tileSize, moveAway)
    self.isJumping = true
    self.jumpTimer = 0

    -- Calculate jump direction
    if dist > 0 then
        if moveAway then
            self.jumpDirectionX = -dx / dist
            self.jumpDirectionY = -dy / dist
        else
            self.jumpDirectionX = dx / dist
            self.jumpDirectionY = dy / dist
        end

        -- Calculate jump distance (between min and max)
        local minJumpDistance = tileSize * SlimeConfig.MIN_JUMP_DISTANCE
        local maxJumpDistance = tileSize * SlimeConfig.MAX_JUMP_DISTANCE

        -- Clamp jump distance: min <= jumpDist <= max
        local desiredDistance = math.min(dist, dist * 0.8)
        self.jumpDistance = math.max(minJumpDistance, math.min(desiredDistance, maxJumpDistance))

        -- Use configured jump speed
        self.jumpSpeed = self.baseSpeed

        -- Calculate duration based on distance and speed: time = distance / speed
        self.jumpDuration = self.jumpDistance / self.jumpSpeed
    else
        self.jumpDirectionX = 0
        self.jumpDirectionY = 0
        self.jumpSpeed = self.baseSpeed
        self.jumpDistance = 0
        self.jumpDuration = 0.3 -- Fallback duration
    end
end

---Finish the current jump
function SlimeJumpController:finishJump()
    self.isJumping = false
    self.jumpTimer = 0
end

---Get the current jump velocity
---@return number velocityX
---@return number velocityY
function SlimeJumpController:getJumpVelocity()
    if self.isJumping then
        return self.jumpDirectionX * self.jumpSpeed, self.jumpDirectionY * self.jumpSpeed
    else
        return 0, 0
    end
end

---Reset to ready state (called when entering combat from idle/wandering)
---Only resets if cooldown is very low (not in active combat)
function SlimeJumpController:resetToReady()
    if not self.isJumping then
        -- Reset to ready if:
        -- 1. Nearly ready (cooldown >= 90% complete) - was already waiting
        -- 2. Just started (cooldown near 0) - first time entering combat
        if self.jumpTimer >= self.jumpCooldown * 0.9 or self.jumpTimer < 0.1 then
            self.jumpTimer = self.jumpCooldown
        end
        -- Otherwise preserve the current cooldown timer (mid-combat state transition)
    end
end

---Get the sprite Y offset for the jumping arc effect
---Uses a parabolic arc that peaks at mid-jump
---@return number The Y offset (negative = up)
function SlimeJumpController:getSpriteYOffset()
    if not self.isJumping then
        return 0
    end

    -- Normalize time within the jump (0 to 1)
    local t = self.jumpTimer / self.jumpDuration

    -- Parabolic arc: peaks at t=0.5
    -- offset = -height * 4 * t * (1 - t)
    -- At t=0: offset=0, at t=0.5: offset=-height, at t=1: offset=0
    local offset = -self.jumpArcHeight * 4 * t * (1 - t)

    return offset
end

---Get the shadow scale factor for the jumping effect
---Shadow gets smaller when higher in the air
---@return number The scale factor (1.0 = normal, 0.6 = smallest at peak)
function SlimeJumpController:getShadowScale()
    if not self.isJumping then
        return 1.0
    end

    -- Normalize time within the jump (0 to 1)
    local t = self.jumpTimer / self.jumpDuration

    -- Shadow scales down as slime goes up
    -- At t=0 or t=1: scale=1.0 (on ground)
    -- At t=0.5: scale=0.6 (at peak, smallest shadow)
    local heightFactor = 4 * t * (1 - t) -- 0 to 1, peaks at t=0.5
    local minScale = 0.6
    local scale = 1.0 - (1.0 - minScale) * heightFactor

    return scale
end

return SlimeJumpController

