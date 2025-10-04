local System = require("src.core.System")

---@class MovementSystem : System
local MovementSystem = System:extend("MovementSystem", {"Position", "Movement"})

---Update all entities with Position and Movement components
---@param dt number Delta time
function MovementSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local movement = entity:getComponent("Movement")
        local collision = entity:getComponent("Collision")

        if position and movement and movement.enabled then
            -- Apply velocity to physics collider and let Love2D handle collision
            if collision and collision:hasCollider() then
                collision:setLinearVelocity(movement.velocityX, movement.velocityY)
                -- Sync ECS position from physics collider
                local x, y = collision:getPosition()
                position:setPosition(x, y)
            else
                -- Fallback to direct position movement if no collider
                position:move(movement.velocityX * dt, movement.velocityY * dt)
            end
        end
    end
end

return MovementSystem
