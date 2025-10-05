local System = require("src.core.System")

---@class MovementSystem : System
local MovementSystem = System:extend("MovementSystem", {"Position", "Movement"})

---Update all entities with Position and Movement components
---@param dt number Delta time
function MovementSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local movement = entity:getComponent("Movement")
        local physicsCollision = entity:getComponent("PhysicsCollision")
        local pathfindingCollision = entity:getComponent("PathfindingCollision")

        if position and movement and movement.enabled then
            -- Apply velocity to pathfinding collider and let Love2D handle collision
            if pathfindingCollision and pathfindingCollision:hasCollider() then
                -- Static entities don't move
                if pathfindingCollision.type == "static" then
                    return
                else
                    -- Dynamic entities - apply velocity to physics body
                    pathfindingCollision:setLinearVelocity(movement.velocityX, movement.velocityY)
                    -- Sync ECS position from physics collider
                    local x, y = pathfindingCollision:getPosition()
                    position:setPosition(x, y)

                    -- Also sync the physics collision position (sensor for hit detection)
                    if physicsCollision and physicsCollision:hasCollider() then
                        physicsCollision:setPosition(x, y)
                    end
                end
            else
                -- Fallback to direct position movement if no collider
                position:move(movement.velocityX * dt, movement.velocityY * dt)

                -- Also update both collision positions if they exist
                if pathfindingCollision and pathfindingCollision:hasCollider() then
                    pathfindingCollision:setPosition(position.x, position.y)
                end
                if physicsCollision and physicsCollision:hasCollider() then
                    physicsCollision:setPosition(position.x, position.y)
                end
            end
        end
    end
end

return MovementSystem
