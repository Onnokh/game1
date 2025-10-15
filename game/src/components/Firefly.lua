---@class Firefly
---@field vx number X velocity in pixels per second
---@field vy number Y velocity in pixels per second
---@field lifetime number Current lifetime in seconds
---@field maxLifetime number Maximum lifetime in seconds
---@field driftSpeed number Speed of horizontal sine wave drift
---@field startTime number Time when firefly was created (for sine wave calculation)
---@field fadeInDuration number Duration of fade-in effect in seconds
---@field fadeInProgress number Current fade-in progress (0-1)
local Firefly = {}
Firefly.__index = Firefly

---Create a new Firefly component
---@param vx number|nil X velocity (default: 0)
---@param vy number|nil Y velocity (default: -25, upward)
---@param lifetime number|nil Lifetime in seconds (default: 5)
---@param driftSpeed number|nil Horizontal drift speed (default: 15)
---@return Component|Firefly
function Firefly.new(vx, vy, lifetime, driftSpeed)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Firefly"), Firefly)

    self.vx = vx or 0
    self.vy = vy or -25  -- Negative for upward movement
    self.lifetime = lifetime or 5
    self.maxLifetime = self.lifetime
    self.driftSpeed = driftSpeed or 15
    self.startTime = love.timer.getTime()
    self.fadeInDuration = 0.5  -- 0.5 seconds to fade in
    self.fadeInProgress = 0    -- Start with no fade-in progress

    return self
end

---Update firefly lifetime and fade-in progress
---@param dt number Delta time
function Firefly:update(dt)
    self.lifetime = self.lifetime - dt

    -- Update fade-in progress
    local elapsed = love.timer.getTime() - self.startTime
    if elapsed < self.fadeInDuration then
        self.fadeInProgress = elapsed / self.fadeInDuration
    else
        self.fadeInProgress = 1
    end
end

---Check if firefly is still alive
---@return boolean True if firefly has lifetime remaining
function Firefly:isAlive()
    return self.lifetime > 0
end

---Get the alpha multiplier based on lifetime (for fading)
---@return number Alpha multiplier (0-1)
function Firefly:getAlphaMultiplier()
    if self.lifetime <= 0 then
        return 0
    end
    -- Fade out in the last 20% of lifetime
    local fadeStart = self.maxLifetime * 0.2
    if self.lifetime <= fadeStart then
        return self.lifetime / fadeStart
    end
    return 1
end

---Get the fade-in alpha multiplier (for appearing)
---@return number Alpha multiplier (0-1)
function Firefly:getFadeInAlpha()
    return self.fadeInProgress
end

---Get the combined alpha multiplier (fade-in + lifetime fade-out)
---@return number Alpha multiplier (0-1)
function Firefly:getCombinedAlpha()
    return self:getFadeInAlpha() * self:getAlphaMultiplier()
end

---Get horizontal drift offset based on time
---@param currentTime number Current time
---@return number Horizontal offset in pixels
function Firefly:getDriftOffset(currentTime)
    local elapsed = currentTime - self.startTime
    return math.sin(elapsed * self.driftSpeed * 0.1) * 20
end

return Firefly
