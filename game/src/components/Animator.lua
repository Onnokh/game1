---@class Animator
---@field sheet string Name of the iffy tileset/spritesheet
---@field frames table List of frame indices to play
---@field fps number Frames per second
---@field loop boolean Whether animation loops
---@field time number Accumulated time
---@field playing boolean Is animation playing
local Animator = {}
Animator.__index = Animator

---Create a new Animator component
---@param config table Animation config table with {sheet, frames, fps, loop}
---@return Component|Animator
function Animator.new(config)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Animator"), Animator)

    self.sheet = config.sheet
    self.frames = config.frames or {1}
    self.fps = config.fps or 6
    self.loop = config.loop ~= false
    self.time = 0
    self.playing = true

    return self
end

---Update animation timer
---@param dt number
function Animator:update(dt)
    if not self.playing or #self.frames <= 1 or self.fps <= 0 then return end
    self.time = self.time + dt
    if not self.loop then
        local total = (#self.frames) / self.fps
        if self.time > total then
            self.time = total
            self.playing = false
        end
    end
end

---Get current frame index (into iffy tileset)
---@return integer
function Animator:getCurrentFrame()
    if #self.frames == 0 then return 1 end
    local frameNumber = math.floor(self.time * self.fps)
    if self.loop then
        frameNumber = frameNumber % #self.frames
    else
        frameNumber = math.min(frameNumber, #self.frames - 1)
    end
    return self.frames[frameNumber + 1]
end

---Change the active animation
---@param config table Animation config table with {sheet, frames, fps, loop}
function Animator:setAnimation(config)
    self.sheet = config.sheet
    self.frames = config.frames or self.frames
    self.fps = config.fps or self.fps
    if config.loop ~= nil then self.loop = config.loop end
    self.time = 0
    self.playing = true
end

return Animator


