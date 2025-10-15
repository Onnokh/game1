local System = require("src.core.System")

---@class DashShadowSystem : System
---System that manages dash shadow lifetime and fading
local DashShadowSystem = System:extend("DashShadowSystem", {"Position", "DashShadow"})

---Update dash shadows - handle lifetime and fading
---@param dt number Delta time
function DashShadowSystem:update(dt)
    -- Create a list of entities to remove to avoid modifying the list while iterating
    local entitiesToRemove = {}

    for _, entity in ipairs(self.entities) do
        local dashShadow = entity:getComponent("DashShadow")

        if dashShadow then
            -- Update the shadow and check if it should be removed
            local shouldRemove = dashShadow:update(dt)

            if shouldRemove then
                table.insert(entitiesToRemove, entity)
            end
        end
    end

    -- Remove entities that should be destroyed
    for _, entity in ipairs(entitiesToRemove) do
        if entity._world then
            entity._world:removeEntity(entity)
        end
    end
end

return DashShadowSystem
