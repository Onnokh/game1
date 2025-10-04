local System = require("src.core.System")

---@class AnimationSystem : System
local AnimationSystem = System:extend("AnimationSystem", {"Animator"})

function AnimationSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local animator = entity:getComponent("Animator")
        if animator then
            animator:update(dt)
        end
    end
end

return AnimationSystem


