local Easing = require("src.utils.easing")

---@class Animation
---@field value number Current animated value
---@field targetValue number Target value to animate to
---@field startValue number Starting value
---@field duration number Total duration of animation in seconds
---@field elapsed number Time elapsed since animation started
---@field easingFunction function Easing function to use
---@field isComplete boolean Whether animation has finished
---@field onComplete function|nil Optional callback when animation completes
---@field loop boolean Whether to loop the animation
---@field yoyo boolean Whether to reverse direction when reaching end
---@field yoyoDirection number 1 for forward, -1 for reverse
---@field itemData table|nil Optional custom data (for shop items, etc)
---@field slotIndex number|nil Optional slot index
---@field shop table|nil Optional shop reference
local Animation = {}
Animation.__index = Animation

---Create a new animation
---@param startValue number Starting value
---@param targetValue number Target value
---@param duration number Duration in seconds
---@param easingName string|nil Name of easing function (default: "linear")
---@param onComplete function|nil Optional callback when animation completes
---@return Animation
function Animation.new(startValue, targetValue, duration, easingName, onComplete)
    local self = setmetatable({}, Animation)

    self.value = startValue
    self.startValue = startValue
    self.targetValue = targetValue
    self.duration = duration or 1.0
    self.elapsed = 0.0
    self.isComplete = false
    self.onComplete = onComplete
    self.loop = false
    self.yoyo = false
    self.yoyoDirection = 1
    self.pulseMode = false

    -- Set easing function
    easingName = easingName or "linear"
    self.easingFunction = Easing[easingName] or Easing.linear

    return self
end

---Update the animation
---@param dt number Delta time
function Animation:update(dt)
    if self.isComplete and not self.loop and not self.yoyo then
        return
    end

    self.elapsed = self.elapsed + dt

    -- Calculate progress (0 to 1)
    local progress = math.min(self.elapsed / self.duration, 1.0)

    -- Apply easing
    local easedProgress = self.easingFunction(progress)

    -- Calculate current value
    if self.yoyoDirection == 1 then
        self.value = self.startValue + (self.targetValue - self.startValue) * easedProgress
    else
        self.value = self.targetValue - (self.targetValue - self.startValue) * easedProgress
    end

    -- Check if animation is complete
    if progress >= 1.0 then
        if self.yoyo then
            -- Check if this is the second half of a pulse animation (shrinking back)
            if self.pulseMode and self.yoyoDirection == -1 then
                -- Pulse animation is complete
                self.isComplete = true
                self.value = self.startValue

                if self.onComplete then
                    self.onComplete()
                end
            else
                -- Reverse direction for yoyo or first half of pulse
                self.yoyoDirection = -self.yoyoDirection
                self.elapsed = 0
            end
        elseif self.loop then
            -- Restart from beginning
            self.elapsed = 0
        else
            -- Mark as complete
            self.isComplete = true
            self.value = self.yoyoDirection == 1 and self.targetValue or self.startValue

            if self.onComplete then
                self.onComplete()
            end
        end
    end
end

---Reset the animation to start
function Animation:reset()
    self.elapsed = 0
    self.value = self.startValue
    self.isComplete = false
    self.yoyoDirection = 1
end

---Set animation to loop
---@param shouldLoop boolean
---@return Animation
function Animation:setLoop(shouldLoop)
    self.loop = shouldLoop
    return self
end

---Set animation to yoyo (reverse when reaching end)
---@param shouldYoyo boolean
---@return Animation
function Animation:setYoyo(shouldYoyo)
    self.yoyo = shouldYoyo
    return self
end

---Set animation to pulse (grow then shrink back)
---@param shouldPulse boolean
---@return Animation
function Animation:setPulse(shouldPulse)
    if shouldPulse then
        -- For pulse, we want to go to target then back to start
        self.yoyo = true
        -- Pulse should complete the full cycle (grow + shrink)
        self.pulseMode = true
    else
        self.yoyo = false
        self.pulseMode = false
    end
    return self
end

---Reverse the animation direction
function Animation:reverse()
    local temp = self.startValue
    self.startValue = self.targetValue
    self.targetValue = temp
    self.elapsed = self.duration - self.elapsed
    self.yoyoDirection = -self.yoyoDirection
    self.isComplete = false -- Reset complete flag so animation continues
end

---@class AnimationManager
---@field animations table<string, Animation> Map of animation ID to Animation
local AnimationManager = {}
AnimationManager.__index = AnimationManager

---Create a new AnimationManager
---@return AnimationManager
function AnimationManager.new()
    local self = setmetatable({}, AnimationManager)
    self.animations = {}
    return self
end

---Create and register an animation
---@param id string Unique identifier for this animation
---@param startValue number Starting value
---@param targetValue number Target value
---@param duration number Duration in seconds
---@param easingName string|nil Name of easing function (default: "linear")
---@param onComplete function|nil Optional callback when animation completes
---@return Animation
function AnimationManager:create(id, startValue, targetValue, duration, easingName, onComplete)
    local anim = Animation.new(startValue, targetValue, duration, easingName, onComplete)
    self.animations[id] = anim
    return anim
end

---Get an animation by ID
---@param id string Animation identifier
---@return Animation|nil
function AnimationManager:get(id)
    return self.animations[id]
end

---Get the current value of an animation
---@param id string Animation identifier
---@param defaultValue number|nil Value to return if animation doesn't exist
---@return number
function AnimationManager:getValue(id, defaultValue)
    local anim = self.animations[id]
    if anim then
        return anim.value
    end
    return defaultValue or 0
end

---Check if an animation exists and is playing
---@param id string Animation identifier
---@return boolean
function AnimationManager:isPlaying(id)
    local anim = self.animations[id]
    return anim ~= nil and not anim.isComplete
end

---Check if an animation is complete
---@param id string Animation identifier
---@return boolean
function AnimationManager:isComplete(id)
    local anim = self.animations[id]
    return anim ~= nil and anim.isComplete
end

---Remove an animation
---@param id string Animation identifier
function AnimationManager:remove(id)
    self.animations[id] = nil
end

---Update all animations
---@param dt number Delta time
function AnimationManager:update(dt)
    for id, anim in pairs(self.animations) do
        anim:update(dt)

        -- Auto-cleanup completed animations (unless they loop or yoyo)
        if anim.isComplete and not anim.loop and not anim.yoyo then
            self.animations[id] = nil
        end
    end
end

---Clear all animations
function AnimationManager:clear()
    self.animations = {}
end

---Get the number of active animations
---@return number
function AnimationManager:count()
    local count = 0
    for _ in pairs(self.animations) do
        count = count + 1
    end
    return count
end

return {
    Animation = Animation,
    AnimationManager = AnimationManager
}

