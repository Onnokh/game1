---@class AnimationController
---@field idleFrames table Frames for idle animation
---@field walkFrames table Frames for walking animation
---@field idleFps number FPS for idle animation
---@field walkFps number FPS for walking animation
---@field currentAnimation string Current animation state
local AnimationController = {}
AnimationController.__index = AnimationController

---Create a new AnimationController component
---@param idleFrames table|nil Frames for idle animation
---@param walkFrames table|nil Frames for walking animation
---@param idleFps number|nil FPS for idle animation
---@param walkFps number|nil FPS for walking animation
---@return Component|AnimationController
function AnimationController.new(idleFrames, walkFrames, idleFps, walkFps)
    local Component = require("src.ecs.Component")
    local self = setmetatable(Component.new("AnimationController"), AnimationController)

    self.idleFrames = idleFrames or {1, 2}
    self.walkFrames = walkFrames or {9, 10, 11, 12} -- Row 2, columns 1-4
    self.idleFps = idleFps or 6
    self.walkFps = walkFps or 8
    self.currentAnimation = "idle"

    return self
end

---Update animation based on movement state
---@param isMoving boolean Whether the entity is moving
---@param animator Animator The animator component to control
function AnimationController:updateAnimation(isMoving, animator)
    local targetAnimation = isMoving and "walk" or "idle"

    if self.currentAnimation ~= targetAnimation then
        self.currentAnimation = targetAnimation

        if targetAnimation == "walk" then
            animator:setAnimation(self.walkFrames, self.walkFps, true)
        else
            animator:setAnimation(self.idleFrames, self.idleFps, true)
        end
    end
end

return AnimationController
