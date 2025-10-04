---@class FlashEffect
---@field duration number Duration of the flash effect in seconds
---@field elapsed number Time elapsed since flash started
---@field intensity number Flash intensity (0-1)
---@field sizePulse number Size pulse intensity (0-1)
---@field isFlashing boolean Whether the entity is currently flashing
---@field shader love.Shader|nil The flash shader
local FlashEffect = {}
FlashEffect.__index = FlashEffect

---Create a new FlashEffect component
---@param duration number|nil Duration of the flash effect in seconds (default: 0.5)
---@return any
function FlashEffect.new(duration)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("FlashEffect"), FlashEffect)

    local ShaderManager = require("src.utils.ShaderManager")

    self.duration = duration or 0.5
    self.elapsed = 0
    self.intensity = 0
    self.sizePulse = 0
    self.isFlashing = false
    self.shader = ShaderManager.getShader("flash")

    return self
end

---Start the flash effect
function FlashEffect:startFlash()
    self.isFlashing = true
    self.elapsed = 0
    self.intensity = 1.0
    self.sizePulse = 0.3 -- Start with a noticeable size pulse
end

---Update the flash effect
---@param dt number Delta time
---@return boolean Whether the flash is still active
function FlashEffect:update(dt)
    if not self.isFlashing then
        return false
    end

    self.elapsed = self.elapsed + dt

    -- Calculate flash intensity with smooth fade-out
    local progress = self.elapsed / self.duration
    if progress >= 1.0 then
        self.isFlashing = false
        self.intensity = 0
        self.sizePulse = 0
        return false
    end

    -- Smooth fade-out curve
    self.intensity = (1 - progress) * (1 - progress) -- Quadratic fade-out

    -- Size pulse with a different curve - starts strong and fades quickly
    self.sizePulse = (1 - progress) * (1 - progress) * 0.3 -- Quadratic fade-out, max 0.3

    return true
end

---Check if the entity is currently flashing
---@return boolean
function FlashEffect:isCurrentlyFlashing()
    return self.isFlashing
end

---Get the current flash intensity
---@return number
function FlashEffect:getIntensity()
    return self.intensity
end

---Get the current size pulse intensity
---@return number
function FlashEffect:getSizePulse()
    return self.sizePulse
end

---Get the flash shader
---@return love.Shader|nil
function FlashEffect:getShader()
    return self.shader
end

return FlashEffect
