local System = require("src.core.System")

---@class MovementSystem : System
local MovementSystem = System:extend("MovementSystem", {"Position", "Movement"})

---Update all entities with Position and Movement components
---@param dt number Delta time
function MovementSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local movement = entity:getComponent("Movement")
        local pathfindingCollision = entity:getComponent("PathfindingCollision")
        local physicsCollision = entity:getComponent("PhysicsCollision")

        if position and movement and movement.enabled then
            -- If using physics colliders, CollisionSystem is responsible for syncing/applying physics.
            -- Only integrate position directly when no colliders are present.
            if (not pathfindingCollision or not pathfindingCollision:hasCollider()) and (not physicsCollision or not physicsCollision:hasCollider()) then
                position:move(movement.velocityX * dt, movement.velocityY * dt)
            end
        end
    end
end

return MovementSystem
