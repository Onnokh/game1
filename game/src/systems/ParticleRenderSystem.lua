local System = require("src.core.System")

---@class ParticleRenderSystem : System
local ParticleRenderSystem = System:extend("ParticleRenderSystem", {"ParticleSystem"})

---Update all entities with ParticleSystem components
---@param dt number Delta time
function ParticleRenderSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local particleSystem = entity:getComponent("ParticleSystem")

        if particleSystem then
            particleSystem:update(dt)
        end
    end
end

---Draw all entities with ParticleSystem components
function ParticleRenderSystem:draw()
    for _, entity in ipairs(self.entities) do
        local particleSystem = entity:getComponent("ParticleSystem")

        if particleSystem then
            particleSystem:draw()
        end
    end
end

return ParticleRenderSystem
