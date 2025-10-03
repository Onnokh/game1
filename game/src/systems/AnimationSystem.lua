local System = require("src.System")

---@class AnimationSystem : System
local AnimationSystem = setmetatable({}, {__index = System})
AnimationSystem.__index = AnimationSystem

function AnimationSystem.new()
    local self = System.new({"Animator"})
    setmetatable(self, AnimationSystem)
    return self
end

function AnimationSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local animator = entity:getComponent("Animator")
        if animator then
            animator:update(dt)
        end
    end
end

return AnimationSystem


