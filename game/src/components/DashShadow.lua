---@class DashShadow
---Component for tracking dash shadow/afterimage effects
---@field lifetime number Time remaining for this shadow (seconds)
---@field fadeTime number Time over which shadow fades out (seconds)
---@field initialOpacity number Initial opacity of the shadow
---@field currentOpacity number Current opacity of the shadow
---@field spriteSheet string|nil Sprite sheet name to render
---@field frameIndex number|nil Frame index to render from the sprite sheet
---@field scaleX number X scale factor (for facing direction)
---@field scaleY number Y scale factor
---@field isFading boolean Whether the shadow is currently fading out
---@field fadeStartTime number|nil When fading started (for staggered fade timing)
---@field dashDirX number Dash direction X component for motion blur
---@field dashDirY number Dash direction Y component for motion blur
local DashShadow = {}
DashShadow.__index = DashShadow

local Component = require("src.core.Component")

---Create a new DashShadow component
---@param lifetime number Time the shadow should live (seconds)
---@param fadeTime number Time over which shadow fades out (seconds)
---@param initialOpacity number Initial opacity of the shadow (0-1)
---@return Component|DashShadow
function DashShadow.new(lifetime, fadeTime, initialOpacity)
    local self = setmetatable(Component.new("DashShadow"), DashShadow)

    self.lifetime = lifetime or 0.3
    self.fadeTime = fadeTime or 0.2
    self.initialOpacity = initialOpacity or 0.6
    self.currentOpacity = self.initialOpacity
    self.spriteSheet = nil
    self.frameIndex = nil
    self.scaleX = 1
    self.scaleY = 1
    self.isFading = false
    self.fadeStartTime = nil  -- When fading actually starts
    self.dashDirX = 0
    self.dashDirY = 0

    return self
end

---Set the sprite data for this shadow
---@param spriteSheet string Sprite sheet name
---@param frameIndex number Frame index to display
---@param scaleX number X scale factor
---@param scaleY number|nil Y scale factor, defaults to scaleX
function DashShadow:setSpriteData(spriteSheet, frameIndex, scaleX, scaleY)
    self.spriteSheet = spriteSheet
    self.frameIndex = frameIndex
    self.scaleX = scaleX
    self.scaleY = scaleY or scaleX
end

---Start the fade-out process
function DashShadow:startFading()
    self.isFading = true
    self.fadeStartTime = 0  -- Will be updated each frame with dt
end

---Update the shadow (called by system)
---@param dt number Delta time
---@return boolean True if shadow should be removed
function DashShadow:update(dt)
    if self.isFading then
        -- Update fade start time
        if self.fadeStartTime == 0 then
            self.fadeStartTime = self.lifetime  -- Remember when fading started
        end

        -- Fade out
        self.lifetime = self.lifetime - dt
        if self.lifetime <= 0 then
            return true -- Remove this shadow
        end

        -- Calculate fade progress (0 to 1) based on how much fade time has passed
        local fadeTimePassed = self.fadeStartTime - self.lifetime
        local fadeProgress = math.max(0, math.min(1, fadeTimePassed / self.fadeTime))
        self.currentOpacity = self.initialOpacity * (1 - fadeProgress)
    end

    return false -- Keep this shadow
end

---Get the current opacity
---@return number Current opacity (0-1)
function DashShadow:getOpacity()
    return self.currentOpacity
end

---Serialize the DashShadow component for saving
---@return table Serialized dash shadow data
function DashShadow:serialize()
    return {
        lifetime = self.lifetime,
        fadeTime = self.fadeTime,
        initialOpacity = self.initialOpacity,
        currentOpacity = self.currentOpacity,
        spriteSheet = self.spriteSheet,
        frameIndex = self.frameIndex,
        scaleX = self.scaleX,
        scaleY = self.scaleY,
        isFading = self.isFading,
        fadeStartTime = self.fadeStartTime,
        dashDirX = self.dashDirX,
        dashDirY = self.dashDirY
    }
end

---Deserialize DashShadow component from saved data
---@param data table Serialized dash shadow data
---@return Component|DashShadow Recreated DashShadow component
function DashShadow.deserialize(data)
    local shadow = DashShadow.new(data.lifetime, data.fadeTime, data.initialOpacity)
    shadow.currentOpacity = data.currentOpacity or shadow.initialOpacity
    shadow.spriteSheet = data.spriteSheet
    shadow.frameIndex = data.frameIndex
    shadow.scaleX = data.scaleX or 1
    shadow.scaleY = data.scaleY or 1
    shadow.isFading = data.isFading or false
    shadow.fadeStartTime = data.fadeStartTime
    shadow.dashDirX = data.dashDirX or 0
    shadow.dashDirY = data.dashDirY or 0
    return shadow
end

return DashShadow
