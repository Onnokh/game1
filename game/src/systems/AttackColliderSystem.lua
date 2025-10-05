local System = require("src.core.System")

---@class AttackColliderSystem : System
local AttackColliderSystem = System:extend("AttackColliderSystem", {"AttackCollider"})

---Update all ephemeral attack colliders and clean up expired ones
---@param dt number Delta time
function AttackColliderSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local ac = entity:getComponent("AttackCollider")
        if ac then
            if ac.update then ac:update(dt) end
            if ac.isExpired and ac:isExpired() then
                if ac.destroy then ac:destroy() end
                entity:removeComponent("AttackCollider")
            end
        end
    end
end

return AttackColliderSystem


