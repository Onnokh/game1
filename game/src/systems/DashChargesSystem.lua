local System = require("src.core.System")

---@class DashChargesSystem : System
---System that manages dash charge regeneration for all entities with DashCharges component
local DashChargesSystem = System:extend("DashChargesSystem", { "DashCharges" })

---Update dash charge regeneration for all entities with DashCharges component
---@param dt number Delta time
function DashChargesSystem:update(dt)
    local entities = self.world:getEntitiesWith({ "DashCharges" })
    for _, entity in ipairs(entities) do
        local dashCharges = entity:getComponent("DashCharges")
        if dashCharges then
            dashCharges:update(dt)
        end
    end
end

return DashChargesSystem
