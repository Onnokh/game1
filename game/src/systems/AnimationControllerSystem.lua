local System = require("src.System")

---@class AnimationControllerSystem : System
local AnimationControllerSystem = setmetatable({}, {__index = System})
AnimationControllerSystem.__index = AnimationControllerSystem

function AnimationControllerSystem.new()
    local self = System.new({"AnimationController", "Animator", "Movement"})
    setmetatable(self, AnimationControllerSystem)
    return self
end

function AnimationControllerSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local animationController = entity:getComponent("AnimationController")
        local animator = entity:getComponent("Animator")
        local movement = entity:getComponent("Movement")

        if animationController and animator and movement then
            local isMoving = movement:isMoving()
            animationController:updateAnimation(isMoving, animator)
        end
    end
end

return AnimationControllerSystem
