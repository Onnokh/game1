local System = require("src.core.System")

---@class KnockbackSystem : System
local KnockbackSystem = System:extend("KnockbackSystem", {"Collision", "Knockback"})

---Update all entities with Knockback components
---@param dt number Delta time
function KnockbackSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local knockback = entity:getComponent("Knockback")
        local collision = entity:getComponent("Collision")

        if knockback and collision and collision:hasCollider() then
            -- Apply immediate force or velocity impulse
            if knockback.timer == 0 then
                local impulseX = knockback.x * knockback.power
                local impulseY = knockback.y * knockback.power
                collision:applyLinearImpulse(impulseX, impulseY)
            end

            -- Track timer
            knockback.timer = knockback.timer + dt
            if knockback.timer >= knockback.duration then
                -- Remove knockback component after duration
                entity:removeComponent("Knockback")
            end
        end
    end
end

return KnockbackSystem
